//
//  RadarTraceStorageTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTraceManager storage")
final class RadarTraceStorageTests {
    private let harness = TraceTestHarness()
    private var manager: RadarTraceManager { harness.manager }
    private var session: TraceURLSession { harness.session }

    @Test("The file limit evicts the oldest spans")
    func fileLimitEvictsOldestSpans() async throws {
        // Record in two steps so the write queue (also 500) never fills; this test is about the file limit.
        try await harness.recordSpans(500)
        try await harness.recordSpans(10, firstId: 501)

        #expect(harness.traceFiles().count == 500)
        #expect(harness.persistedSpanIds() == Set((11...510).map(spanId)))
    }

    @Test("The byte limit evicts the oldest spans")
    func byteLimitEvictsOldestSpans() async throws {
        try await harness.recordSpans(30, attributes: ["payload": .string(String(repeating: "x", count: 20_000))])

        let files = harness.traceFiles()
        let bytes = files.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
        #expect(bytes <= 512 * 1024)
        #expect(files.count < 30)
        // Whatever survives must be the newest spans.
        #expect(harness.persistedSpanIds() == Set((1...30).map(spanId).suffix(files.count)))
    }

    @Test("Expired spans are dropped before upload")
    func expiredSpanIsDropped() async throws {
        try await harness.recordSpans(1)
        let file = try #require(harness.traceFiles().first)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -73 * 60 * 60)], ofItemAtPath: file.path)

        try await manager.flushAndWaitForTesting()

        #expect(harness.traceFiles().isEmpty)
        #expect(session.requests.isEmpty)
    }

    @Test("The batch being uploaded can be evicted, and its upload still completes")
    func inFlightBatchCanBeEvicted() async throws {
        try await evictInFlightBatch()

        session.stopHolding()
        try session.releaseNext(.status(200, TraceTestHarness.acceptedBody))
        try await manager.waitForFlushForTesting()

        #expect(TraceTestHarness.spanIds(session.payloads[0]) == (1...100).map(spanId))
        // The flush continued with the rest of the queue, so no span was lost.
        #expect(harness.traceFiles().isEmpty)
        #expect(session.payloads.dropFirst().flatMap(TraceTestHarness.spanIds) == (101...600).map(spanId))
    }

    @Test("A retry after the batch being uploaded was evicted continues with the remaining spans")
    func retryAfterInFlightBatchIsEvicted() async throws {
        try await evictInFlightBatch()

        session.stopHolding()
        try session.releaseNext(.status(503, Data(#"{"meta":{"code":503}}"#.utf8)))
        try await manager.waitForFlushForTesting()

        // The evicted batch is gone, so the next flush starts with the oldest remaining span.
        #expect(harness.persistedSpanIds() == Set((101...600).map(spanId)))
        try await manager.flushAndWaitForTesting()
        #expect(harness.traceFiles().isEmpty)
        #expect(session.payloads.dropFirst().flatMap(TraceTestHarness.spanIds) == (101...600).map(spanId))
    }

    /// Holds an upload of spans 1–100, then records 101–600, which exceeds the file limit and evicts the batch.
    private func evictInFlightBatch() async throws {
        session.hold()
        try await harness.recordSpans(100)
        manager.flush()
        try await session.waitForHeldRequests(1)

        try await harness.recordSpans(500, firstId: 101)
        #expect(harness.persistedSpanIds() == Set((101...600).map(spanId)))
    }

    @Test("Corrupt records are deleted and valid records uploaded")
    func corruptRecordsAreDeleted() async throws {
        try await harness.writeFile("1000-000000001-a.json", Data("not json".utf8))
        try await harness.writeFile("1000-000000002-a.json", JSONSerialization.data(withJSONObject: ["project": try harness.project()]))
        try await harness.writeRecordFile("1000-000000003-a.json", spanId: spanId(3))

        try await manager.flushAndWaitForTesting()

        #expect(harness.traceFiles().isEmpty)
        #expect(session.payloads.flatMap(TraceTestHarness.spanIds) == [spanId(3)])
    }

    @Test("Stale temp files are removed at startup and recent ones are kept")
    func tempFilesAtStartup() async throws {
        let stale = harness.directory.appendingPathComponent("span-stale.tmp")
        let recent = harness.directory.appendingPathComponent("span-recent.tmp")
        try Data("partial".utf8).write(to: stale)
        try Data("partial".utf8).write(to: recent)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -2 * 60)], ofItemAtPath: stale.path)

        await harness.makeManager().awaitDiskForTesting()

        #expect(!FileManager.default.fileExists(atPath: stale.path))
        #expect(FileManager.default.fileExists(atPath: recent.path))
    }

    @Test("Spans persisted before the process ended are uploaded by a new manager")
    func spansSurviveRestart() async throws {
        try await harness.recordSpans(3)

        harness.manager = harness.makeManager(start: false)
        manager.start()
        try await manager.waitForFlushForTesting()

        #expect(harness.traceFiles().isEmpty)
        #expect(Set(session.payloads.flatMap(TraceTestHarness.spanIds)) == Set((1...3).map(spanId)))
    }

    @Test("Spans beyond the write queue limit are dropped")
    func spansBeyondWriteQueueLimitAreDropped() async throws {
        // Hold the disk queue so writes queue up.
        let release = DispatchSemaphore(value: 0)
        manager.disk.async { release.wait() }

        // The queue holds 500 writes, so the newest 100 spans are dropped. Without the limit, all 600 would be
        // written and the storage limits would evict the oldest 100 instead.
        let project = try harness.project()
        for id in 1...600 {
            manager.record(TraceTestHarness.span(spanId(id)), project: project, sessionId: manager.currentSessionId())
        }
        release.signal()
        // Let the 500 writes finish before timing the flush; they're slow on CI runners.
        await manager.awaitDiskForTesting()
        try await manager.flushAndWaitForTesting()

        #expect(session.payloads.flatMap(TraceTestHarness.spanIds) == (1...500).map(spanId))

        // Once the queue drains, new spans are accepted again.
        try await harness.recordSpans(1, firstId: 601)
        try await manager.flushAndWaitForTesting()

        #expect(session.payloads.flatMap(TraceTestHarness.spanIds).last == spanId(601))
    }

    // MARK: - Encoding

    @Test("Completed spans encode as OTLP/JSON with typed attributes")
    func completedSpanEncoding() async throws {
        let completed = RadarCompletedSpan(
            name: "HTTP POST /v1/track",
            traceId: "0123456789abcdef0123456789abcdef",
            spanId: spanId(2),
            parentSpanId: spanId(1),
            kind: .client,
            startUnixNanos: 1_780_000_000_000_000_000,
            endUnixNanos: 1_780_000_000_100_000_000,
            status: .errorNetwork,
            attributes: [
                "string": .string("value"),
                "int": .int(42),
                "double": .double(1.5),
                "bool": .bool(true),
            ]
        )

        // Round-trip through JSON so the test checks the encoded types, not the Swift values.
        let data = try JSONSerialization.data(withJSONObject: completed.otlpJSON())
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let text = try #require(String(bytes: data, encoding: .utf8))

        #expect(json["traceId"] as? String == "0123456789abcdef0123456789abcdef")
        #expect(json["spanId"] as? String == spanId(2))
        #expect(json["parentSpanId"] as? String == spanId(1))
        #expect(json["kind"] as? Int == 3)
        #expect(json["flags"] as? Int == 1)
        #expect(json["startTimeUnixNano"] as? String == "1780000000000000000")
        #expect(json["endTimeUnixNano"] as? String == "1780000000100000000")
        #expect((json["status"] as? [String: Any])?["code"] as? Int == 2)

        let attributes = try #require(json["attributes"] as? [[String: Any]])
        let values = Dictionary(
            uniqueKeysWithValues: attributes.compactMap { attribute in
                (attribute["key"] as? String).map { ($0, attribute["value"] as? [String: Any] ?? [:]) }
            })
        #expect(values["string"]?["stringValue"] as? String == "value")
        #expect(values["int"]?["intValue"] as? String == "42")
        #expect(values["double"]?["doubleValue"] as? Double == 1.5)
        #expect(values["error.type"]?["stringValue"] as? String == "ERROR_NETWORK")
        // JSONSerialization reads booleans back as NSNumber, so check the encoded text for a JSON boolean.
        #expect(text.contains(#"{"boolValue":true}"#))
    }

    @Test("A successful span has no status or error type, and a root span has no parent")
    func successfulRootSpanEncoding() {
        let json = TraceTestHarness.span(spanId(1)).otlpJSON()

        #expect(json["status"] == nil)
        #expect(json["parentSpanId"] == nil)
        #expect((json["attributes"] as? [[String: Any]])?.isEmpty == true)
    }

    private func spanId(_ index: Int) -> String {
        TraceTestHarness.spanId(index)
    }
}
