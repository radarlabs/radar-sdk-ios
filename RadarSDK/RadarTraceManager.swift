//
//  RadarTraceManager.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CryptoKit
import Foundation

/// Durable storage and batched OTLP/JSON export for SDK spans.
///
/// Disk and upload state is confined to the serial `disk` queue, and the private functions that touch it run there.
/// `record` and `flush` hand their work to that queue and return immediately. The queue runs tasks in the order they
/// were submitted, which later work (the sampling decision) relies on, so it must stay a serial `DispatchQueue`
/// rather than an actor.
///
/// Uploads go through the Swift `RadarAPIHelper`, which has its own `URLSession`, so they never wait behind or delay
/// track requests on the Objective-C helper. Like log uploads, flushes are triggered after successful API calls, so
/// failed batches stay on disk and are retried on the next trigger instead of on a timer.
///
/// The server decides sampling per session (see `RadarTraceManager+Sampling.swift`). Spans can end before that decision arrives, so
/// they're written as pending, tagged with their session, and not uploaded until `onSamplingDecision` makes them
/// uploadable or deletes them. A replaced session can still get its decision from a request that was in flight when
/// the session changed, so its pending spans are kept until the next `start`.
@objc(RadarTraceManager)
final class RadarTraceManager: NSObject, @unchecked Sendable {
    static let maxBatchSpans = 100
    static let maxBatchBytes = 128 * 1024

    // Spans waiting for the disk queue. Past this, storing a new span would only evict an older one.
    static let maxPendingWrites = RadarTraceStore.maxFiles

    @objc(sharedInstance)
    static let shared = RadarTraceManager()

    let disk = DispatchQueue(label: "io.radar.traces", qos: .utility)
    let clock: RadarTraceClock
    private let apiClient: RadarAPIClient
    private let publishableKey: @Sendable () -> String?
    private let sessionId: @Sendable () -> String

    // Accessed only on the disk queue.
    let store: RadarTraceStore

    // Sampling decisions have their own lock, since `samplingState` runs whenever a span checks its traceparent.
    let samplingLock = NSLock()
    // Guarded by samplingLock. Oldest first.
    var samplingDecisions: [(sessionId: String, sampled: Bool)] = []
    var sampledOverride: Bool?

    private let lock = NSLock()
    // Guarded by lock.
    private var isStarted = false
    private var isFlushing = false
    private var pendingWrites = 0
    private var droppedWrites = 0

    /// The defaults are what production uses. Tests inject a temporary directory, a mock API client, a key, a session,
    /// and a clock, so they don't share files or change global state.
    init(
        directory: URL = RadarTraceStore.defaultDirectory(),
        apiClient: RadarAPIClient = .shared,
        publishableKey: @escaping @Sendable () -> String? = { RadarSettings.publishableKey },
        sessionId: @escaping @Sendable () -> String = { RadarSettings.sessionId },
        clock: RadarTraceClock = .system
    ) {
        self.store = RadarTraceStore(directory: directory)
        self.clock = clock
        self.apiClient = apiClient
        self.publishableKey = publishableKey
        self.sessionId = sessionId
        super.init()
        disk.async {
            self.store.createDirectory()
            self.store.prune()
        }
    }

    // MARK: - Recording and flushing

    /// Starts tracing for the process: deletes pending spans from every session except the current one, then uploads
    /// stored spans. Called from `initialize`; later calls do nothing.
    @objc
    func start() {
        let first = lock.withLock {
            defer { isStarted = true }
            return !isStarted
        }
        guard first else { return }
        let currentSessionId = currentSessionId()
        disk.async { self.store.deletePending(exceptSessionId: currentSessionId) }
        flush()
    }

    var started: Bool {
        lock.withLock { isStarted }
    }

    /// The current session, which new traces are sampled under.
    func currentSessionId() -> String { sessionId() }

    /// Queues a completed span to be written to disk. `project` is the fingerprint of the publishable key the span was
    /// recorded under, and `sessionId` the session its trace started in. Never throws into SDK call paths.
    func record(_ span: RadarCompletedSpan, project: String, sessionId: String) {
        let data: Data
        do {
            let record: [String: Any] = [
                "project": project,
                "sdkVersion": RadarUtils.sdkVersion,
                "span": span.otlpJSON(),
            ]
            data = try JSONSerialization.data(withJSONObject: record)
        } catch {
            RadarLogger.shared.error("Could not record trace span | message = \(error.localizedDescription)", type: .sdkError)
            return
        }

        // If spans are created faster than they can be written, drop new ones instead of queuing without limit.
        let (accepted, firstDrop) = lock.withLock { () -> (Bool, Bool) in
            guard pendingWrites < Self.maxPendingWrites else {
                droppedWrites += 1
                return (false, droppedWrites == 1)
            }
            pendingWrites += 1
            return (true, false)
        }
        guard accepted else {
            if firstDrop {
                RadarLogger.shared.error("Trace write queue is full; dropping new spans | limit = \(Self.maxPendingWrites)", type: .sdkError)
            }
            return
        }

        disk.async {
            defer { self.finishWrite() }
            // Checked on the disk queue, which runs tasks in order. onSamplingDecision stores the decision before
            // queueing resolvePending, so this write either sees the decision or writes a pending file that
            // resolvePending then handles.
            switch self.samplingState(sessionId: sessionId) {
            case .sampled: self.store.write(data)
            case .pending: self.store.write(data, pendingSessionId: sessionId)
            case .notSampled: break
            }
        }
    }

    /// Uploads batches on the disk queue until the queue is empty or an upload does not succeed. The storage limits
    /// keep a full backlog to about 5 batches. Called after successful track and replay requests. Does nothing before
    /// `start`, or while a flush is in progress.
    @objc
    func flush() {
        let shouldFlush = lock.withLock {
            guard isStarted, !isFlushing else { return false }
            isFlushing = true
            return true
        }
        guard shouldFlush else { return }
        disk.async { self.uploadNextBatch() }
    }

    /// Fingerprint of the current publishable key, or nil if none is set.
    func currentProjectFingerprint() -> String? {
        publishableKey().map(Self.fingerprint)
    }

    /// Tags each span record with its project so spans are only uploaded under the key they were recorded with,
    /// without writing the key (or an auth token) to disk.
    static func fingerprint(_ key: String) -> String {
        SHA256.hash(data: Data(key.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Upload

    /// Span files selected for one upload, and the OTLP request body built from them.
    private struct Batch: Sendable {
        let names: [String]
        let body: Data
    }

    /// Selects and uploads the next batch, continuing from the upload's completion. Runs on the disk queue.
    private func uploadNextBatch() {
        // Read the key once so the same key selects the batch and authenticates the upload.
        guard let publishableKey = publishableKey(),
            let batch = select(project: Self.fingerprint(publishableKey))
        else {
            finishFlush()
            return
        }

        Task(priority: .utility) {
            let outcome: UploadOutcome
            do {
                let (data, response) = try await self.apiClient.postTraces(body: batch.body, publishableKey: publishableKey)
                outcome = Self.outcome(statusCode: response.statusCode, data: data)
            } catch {
                outcome = .retry
            }
            self.disk.async {
                if self.handle(outcome, for: batch) {
                    self.uploadNextBatch()
                } else {
                    self.finishFlush()
                }
            }
        }
    }

    /// Applies the upload result to the batch. Returns true if the flush should continue with the next batch.
    private func handle(_ outcome: UploadOutcome, for batch: Batch) -> Bool {
        switch outcome {
        case .accepted(let rejectedSpans):
            batch.names.forEach(store.remove)
            if let rejectedSpans {
                RadarLogger.shared.warning("Trace batch partially accepted | rejectedSpans = \(rejectedSpans); not retrying")
            }
            // If the batch can't be deleted, the next select would upload it again, so stop instead of looping.
            if batch.names.contains(where: store.exists) {
                RadarLogger.shared.error("Could not delete uploaded trace batch; stopping flush", type: .sdkError)
                return false
            }
            return true

        // Transient: keep the batch for the next flush. A batch the server can never accept is retried until it ages
        // out or is evicted by the storage limits.
        case .retry:
            return false

        // Not retryable (bad request, auth, payload too large, ingestion disabled, etc.).
        case .drop(let statusCode, let body):
            batch.names.forEach(store.remove)
            RadarLogger.shared.error("Dropped trace batch | statusCode = \(statusCode); res = \(body)", type: .sdkError)
            return false
        }
    }

    /// Ends the current flush. Runs on the disk queue.
    private func finishFlush() {
        lock.withLock { isFlushing = false }
    }

    /// Called on the disk queue after each write. Logs how many spans were dropped once the queue drains.
    private func finishWrite() {
        let dropped = lock.withLock {
            pendingWrites -= 1
            guard pendingWrites == 0 else { return 0 }
            defer { droppedWrites = 0 }
            return droppedWrites
        }
        if dropped > 0 {
            RadarLogger.shared.error("Dropped trace spans while the write queue was full | dropped = \(dropped)", type: .sdkError)
        }
    }
}

// MARK: - Batches

extension RadarTraceManager {

    /// A span record read from disk.
    private struct StoredSpan {
        let name: String
        let size: Int
        let project: String
        let sdkVersion: String
        let span: [String: Any]
    }

    /// Builds the next OTLP batch from the oldest spans for a project, or nil if there are none.
    private func select(project: String) -> Batch? {
        store.prune()
        var selected: [StoredSpan] = []
        var bytes = 0
        for entry in store.records() {
            guard let stored = read(entry), stored.project == project else { continue }
            if !fits(stored, in: selected, bytes: bytes) { break }
            selected.append(stored)
            bytes += stored.size
        }
        // `fits` only adds spans recorded by the same SDK version as the first, so it applies to the whole batch.
        guard let sdkVersion = selected.first?.sdkVersion else { return nil }
        do {
            let body = try JSONSerialization.data(withJSONObject: Self.otlpPayload(spans: selected.map(\.span), sdkVersion: sdkVersion))
            return Batch(names: selected.map(\.name), body: body)
        } catch {
            RadarLogger.shared.error("Could not encode trace batch | message = \(error.localizedDescription)", type: .sdkError)
            return nil
        }
    }

    /// Reads a span record, deleting it if it is corrupt.
    private func read(_ entry: RadarTraceStore.Entry) -> StoredSpan? {
        guard let data = store.contents(of: entry.name),
            let record = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let span = record["span"] as? [String: Any]
        else {
            store.remove(entry.name)
            return nil
        }
        return StoredSpan(
            name: entry.name,
            size: entry.size,
            project: record["project"] as? String ?? "",
            sdkVersion: record["sdkVersion"] as? String ?? "",
            span: span
        )
    }

    /// A batch holds spans from one SDK version, up to the span and byte limits. The first span always fits. One
    /// version per batch because `otlpPayload` stamps the version on the batch's single resource.
    private func fits(_ next: StoredSpan, in selected: [StoredSpan], bytes: Int) -> Bool {
        guard let first = selected.first else { return true }
        return next.sdkVersion == first.sdkVersion
            && selected.count < Self.maxBatchSpans
            && bytes + next.size <= Self.maxBatchBytes
    }
}

// MARK: - Test hooks

extension RadarTraceManager {

    /// Waits for queued disk work, including span writes, to finish. Suspends instead of blocking, so tests waiting
    /// on slow writes don't hold threads that other tests' uploads need.
    func awaitDiskForTesting() async {
        await withCheckedContinuation { continuation in
            disk.async { continuation.resume() }
        }
    }

    /// Waits for any flush in progress, then runs a full flush and waits for it to finish.
    func flushAndWaitForTesting() async throws {
        try await waitForFlushForTesting()
        flush()
        try await waitForFlushForTesting()
    }

    /// Waits until no flush is in progress. Throws after 60 seconds so a stuck flush fails the test. CI runners can be
    /// much slower than a local machine, so the limit only catches hangs.
    func waitForFlushForTesting() async throws {
        let deadline = Date().addingTimeInterval(60)
        while lock.withLock({ isFlushing }) {
            guard Date() < deadline else {
                throw NSError(
                    domain: "io.radar.traces", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Trace flush did not finish within 60 seconds"])
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
