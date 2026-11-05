//
//  RadarTraceTestSupport.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

/// A `RadarTraceManager` on a temporary directory, uploading through `TraceURLSession`, with its own publishable key
/// (the global setting is untouched, so tests can run in parallel). Cleans up when released.
final class TraceTestHarness {
    static let publishableKey = "prj_test_pk_trace"
    static let acceptedBody = Data(#"{"meta":{"code":200}}"#.utf8)

    let directory: URL
    let session = TraceURLSession()
    let key = TraceKey(TraceTestHarness.publishableKey)
    var manager: RadarTraceManager!

    /// `start: false` leaves the manager unstarted, for tests of `start` itself.
    init(start: Bool = true) {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("radar-traces-\(UUID().uuidString)")
        // Tests write files into the directory directly, so create it now rather than waiting for the manager to.
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        manager = makeManager(start: start)
    }

    deinit {
        // Clean up after any queued writes, without blocking the releasing thread.
        let directory = directory
        manager.disk.async {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
            try? FileManager.default.removeItem(at: directory)
        }
    }

    /// A new manager on the same directory, session, and key, as after a process restart. Started by default, like
    /// the shared manager after `initialize`. Pass `start: false` to test `start` itself.
    func makeManager(start: Bool = true) -> RadarTraceManager {
        let key = key
        let manager = RadarTraceManager(
            directory: directory,
            apiClient: RadarAPIClient(apiHelper: RadarAPIHelper(session: session)),
            publishableKey: { key.value }
        )
        if start {
            manager.start()
        }
        return manager
    }

    func project() throws -> String {
        try #require(manager.currentProjectFingerprint())
    }

    func recordSpans(_ count: Int, firstId: Int = 1, attributes: [String: RadarTraceAttributeValue] = [:]) async throws {
        let project = try project()
        for id in firstId..<(firstId + count) {
            manager.record(Self.span(Self.spanId(id), attributes: attributes), project: project)
        }
        await manager.awaitDiskForTesting()
    }

    func writeRecordFile(_ name: String, spanId: String, sdkVersion: String = RadarUtils.sdkVersion) async throws {
        let record: [String: Any] = [
            "project": try project(),
            "sdkVersion": sdkVersion,
            "span": Self.span(spanId).otlpJSON(),
        ]
        try await writeFile(name, JSONSerialization.data(withJSONObject: record))
    }

    /// Writes a file into the trace directory once the manager's startup flush has finished, so that flush can't
    /// upload some of a test's files before the rest are written.
    func writeFile(_ name: String, _ data: Data) async throws {
        try await manager.waitForFlushForTesting()
        try data.write(to: directory.appendingPathComponent(name))
    }

    func traceFiles() -> [URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return urls.filter { $0.pathExtension == "json" }
    }

    func persistedSpanIds() -> Set<String> {
        Set(
            traceFiles().compactMap { url in
                guard let data = try? Data(contentsOf: url),
                    let record = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else { return nil }
                return (record["span"] as? [String: Any])?["spanId"] as? String
            })
    }

    /// Span count of each upload so far, in upload order.
    func batchSizes() -> [Int] {
        session.payloads.map { Self.spanIds($0).count }
    }

    static func spanId(_ index: Int) -> String {
        String(format: "%016x", index)
    }

    static func span(_ spanId: String, attributes: [String: RadarTraceAttributeValue] = [:]) -> RadarCompletedSpan {
        RadarCompletedSpan(
            name: "span",
            traceId: "0123456789abcdef0123456789abcdef",
            spanId: spanId,
            parentSpanId: nil,
            kind: .internal,
            startUnixNanos: 1_780_000_000_000_000_000,
            endUnixNanos: 1_780_000_000_100_000_000,
            status: .success,
            attributes: attributes
        )
    }

    static func scopeSpans(_ payload: [String: Any]) -> [String: Any]? {
        let resourceSpans = (payload["resourceSpans"] as? [[String: Any]])?.first
        return (resourceSpans?["scopeSpans"] as? [[String: Any]])?.first
    }

    /// Span IDs in upload order.
    static func spanIds(_ payload: [String: Any]) -> [String] {
        ((scopeSpans(payload)?["spans"] as? [[String: Any]]) ?? []).compactMap { $0["spanId"] as? String }
    }

    static func resourceAttribute(_ payload: [String: Any], _ key: String) -> String? {
        let resourceSpans = (payload["resourceSpans"] as? [[String: Any]])?.first
        let attributes = ((resourceSpans?["resource"] as? [String: Any])?["attributes"] as? [[String: Any]]) ?? []
        let attribute = attributes.first { $0["key"] as? String == key }
        return (attribute?["value"] as? [String: Any])?["stringValue"] as? String
    }
}

/// The publishable key a test's manager reads, changeable during the test.
final class TraceKey: @unchecked Sendable {
    private let lock = NSLock()
    private var current: String?

    init(_ value: String?) {
        current = value
    }

    var value: String? {
        get { lock.withLock { current } }
        set { lock.withLock { current = newValue } }
    }
}

/// Records trace upload requests and replies with queued responses (200 with an envelope by default). In hold mode,
/// requests wait until the test releases them, so tests can act while an upload is in flight.
final class TraceURLSession: RadarURLSessionProtocol, @unchecked Sendable {
    enum Reply {
        case status(Int, Data)
        case error(URLError)
    }

    private let lock = NSLock()
    private var replies: [Reply] = []
    private var recorded: [URLRequest] = []
    private var holding = false
    private var held: [CheckedContinuation<Reply, Never>] = []

    var requests: [URLRequest] {
        lock.withLock { recorded }
    }

    /// Decoded JSON bodies of the trace uploads, in order.
    var payloads: [[String: Any]] {
        requests.compactMap { request in
            request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        }
    }

    func queue(_ reply: Reply) {
        lock.withLock { replies.append(reply) }
    }

    func hold() {
        lock.withLock { holding = true }
    }

    func stopHolding() {
        lock.withLock { holding = false }
    }

    /// Waits until `count` requests are held. Fails instead of hanging if they never arrive within 60 seconds.
    func waitForHeldRequests(_ count: Int) async throws {
        let deadline = Date().addingTimeInterval(60)
        while lock.withLock({ held.count }) < count {
            guard Date() < deadline else {
                Issue.record("No trace upload started")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    /// Replies to the oldest held request.
    func releaseNext(_ reply: Reply) throws {
        let continuation = lock.withLock { held.isEmpty ? nil : held.removeFirst() }
        try #require(continuation != nil, "No held trace upload")
        continuation?.resume(returning: reply)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let shouldHold = lock.withLock {
            recorded.append(request)
            return holding
        }
        let reply: Reply
        if shouldHold {
            reply = await withCheckedContinuation { continuation in
                lock.withLock { held.append(continuation) }
            }
        } else {
            reply = lock.withLock { replies.isEmpty ? .status(200, TraceTestHarness.acceptedBody) : replies.removeFirst() }
        }
        switch reply {
        case .status(let statusCode, let data):
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: [:])!
            return (data, response)
        case .error(let error):
            throw error
        }
    }
}
