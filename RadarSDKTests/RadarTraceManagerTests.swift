//
//  RadarTraceManagerTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTraceManager upload")
final class RadarTraceManagerTests {
    private let harness = TraceTestHarness()
    private var manager: RadarTraceManager { harness.manager }
    private var session: TraceURLSession { harness.session }

    @Test("Persists spans, uploads an OTLP envelope, then deletes acknowledged files")
    func persistsAndExportsOtlpEnvelope() async throws {
        manager.record(TraceTestHarness.span(spanId(1)), project: try harness.project())
        manager.record(TraceTestHarness.span(spanId(2)), project: try harness.project())
        await manager.awaitDiskForTesting()
        #expect(harness.traceFiles().count == 2)

        try await manager.flushAndWaitForTesting()

        #expect(harness.traceFiles().isEmpty)
        let request = try #require(session.requests.first)
        #expect(session.requests.count == 1)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/v1/traces")
        #expect(request.value(forHTTPHeaderField: "Authorization") == TraceTestHarness.publishableKey)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let payload = try #require(session.payloads.first)
        #expect(TraceTestHarness.resourceAttribute(payload, "service.name") == "radar-client")
        #expect(TraceTestHarness.resourceAttribute(payload, "os.type") == "ios")
        #expect(TraceTestHarness.resourceAttribute(payload, "radar.sdk.version") == RadarUtils.sdkVersion)
        let scope = try #require(TraceTestHarness.scopeSpans(payload)?["scope"] as? [String: Any])
        #expect(scope["name"] as? String == "io.radar.sdk")
        #expect(scope["version"] as? String == RadarUtils.sdkVersion)
        #expect(spanIds(payload) == [spanId(1), spanId(2)])
    }

    @Test("A network error keeps the batch, and the next flush retries it first")
    func networkErrorRetriesBatch() async throws {
        session.queue(.error(URLError(.notConnectedToInternet)))
        try await harness.recordSpans(150)

        try await manager.flushAndWaitForTesting()

        #expect(harness.traceFiles().count == 150)
        #expect(harness.batchSizes() == [100])

        try await manager.flushAndWaitForTesting()

        #expect(harness.traceFiles().isEmpty)
        // The failed batch of 100 is retried, followed by the remaining 50.
        #expect(harness.batchSizes() == [100, 100, 50])
        #expect(spanIds(session.payloads[0]) == spanIds(session.payloads[1]))
    }

    @Test("A rate limit keeps the batch on disk")
    func rateLimitKeepsBatch() async throws {
        session.queue(.status(429, Data(#"{"meta":{"code":429}}"#.utf8)))
        try await harness.recordSpans(150)

        try await manager.flushAndWaitForTesting()

        #expect(harness.traceFiles().count == 150)
        #expect(harness.batchSizes() == [100])
    }

    @Test("A non-retryable response drops exactly the rejected batch and stops the flush")
    func nonRetryableResponseDropsBatch() async throws {
        session.queue(.status(400, Data(#"{"meta":{"code":400}}"#.utf8)))
        try await harness.recordSpans(150)

        try await manager.flushAndWaitForTesting()

        #expect(harness.batchSizes() == [100])
        #expect(spanIds(session.payloads[0]) == (1...100).map(spanId))
        #expect(harness.persistedSpanIds() == Set((101...150).map(spanId)))
    }

    @Test("Repeated server errors never drop spans")
    func serverErrorsKeepBatch() async throws {
        for _ in 0..<5 {
            session.queue(.status(503, Data(#"{"meta":{"code":503}}"#.utf8)))
        }
        try await harness.recordSpans(150)

        // Each flush retries the oldest batch and stops.
        for _ in 0..<5 {
            try await manager.flushAndWaitForTesting()
        }
        #expect(harness.traceFiles().count == 150)
        #expect(harness.batchSizes() == Array(repeating: 100, count: 5))
        #expect(session.payloads.allSatisfy { spanIds($0) == (1...100).map(spanId) })

        // Once the server recovers, the whole queue uploads.
        try await manager.flushAndWaitForTesting()
        #expect(harness.traceFiles().isEmpty)
        #expect(harness.batchSizes() == Array(repeating: 100, count: 5) + [100, 50])
    }

    @Test("A 200 without a JSON envelope keeps the batch")
    func malformedSuccessKeepsBatch() async throws {
        session.queue(.status(200, Data()))
        try await harness.recordSpans(2)

        try await manager.flushAndWaitForTesting()

        #expect(harness.traceFiles().count == 2)
        #expect(harness.batchSizes() == [2])
    }

    @Test("A partial success deletes the batch without retrying")
    func partialSuccessDeletesBatch() async throws {
        session.queue(.status(200, Data(#"{"meta":{"code":200},"partialSuccess":{"rejectedSpans":"1"}}"#.utf8)))
        try await harness.recordSpans(2)

        try await manager.flushAndWaitForTesting()

        #expect(harness.traceFiles().isEmpty)
        #expect(session.payloads.count == 1)
    }

    @Test("A flush drains the queue in batches, oldest first")
    func flushDrainsQueueInBatches() async throws {
        try await harness.recordSpans(450)

        try await manager.flushAndWaitForTesting()

        #expect(harness.batchSizes() == [100, 100, 100, 100, 50])
        #expect(spanIds(session.payloads[0]) == (1...100).map(spanId))
        #expect(harness.traceFiles().isEmpty)
    }

    @Test("A flush stops when an uploaded batch can't be deleted")
    func flushStopsWhenBatchCannotBeDeleted() async throws {
        try await harness.recordSpans(150)
        let directory = harness.directory.path
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory) }

        try await manager.flushAndWaitForTesting()

        #expect(harness.batchSizes() == [100])
        #expect(harness.traceFiles().count == 150)
    }

    @Test("Batches are split at the byte limit")
    func batchIsSplitAtByteLimit() async throws {
        // Each record is about 20 KB, so six fit under the 128 KiB batch limit.
        try await harness.recordSpans(10, attributes: ["payload": .string(String(repeating: "x", count: 20_000))])

        try await manager.flushAndWaitForTesting()

        #expect(harness.batchSizes() == [6, 4])
        #expect(harness.traceFiles().isEmpty)
    }

    @Test("Spans from different SDK versions are uploaded in separate batches")
    func sdkVersionsUploadSeparately() async throws {
        try await harness.writeRecordFile("1000-000000001-a.json", spanId: spanId(1), sdkVersion: "3.44.0")
        try await harness.writeRecordFile("1000-000000002-a.json", spanId: spanId(2), sdkVersion: "3.44.0")
        try await harness.writeRecordFile("1000-000000003-a.json", spanId: spanId(3), sdkVersion: "3.45.0")

        try await manager.flushAndWaitForTesting()

        #expect(session.payloads.map { TraceTestHarness.resourceAttribute($0, "radar.sdk.version") } == ["3.44.0", "3.45.0"])
        #expect(harness.batchSizes() == [2, 1])
    }

    @Test("A flush before start does nothing")
    func flushBeforeStartDoesNothing() async throws {
        let harness = TraceTestHarness(start: false)
        try await harness.recordSpans(1)

        harness.manager.flush()
        try await harness.manager.waitForFlushForTesting()

        #expect(harness.session.requests.isEmpty)
        #expect(harness.traceFiles().count == 1)
    }

    @Test("A second flush during an upload is ignored")
    func secondFlushDuringUploadIsIgnored() async throws {
        session.hold()
        try await harness.recordSpans(1)

        manager.flush()
        try await session.waitForHeldRequests(1)
        manager.flush()
        await manager.awaitDiskForTesting()

        #expect(session.requests.count == 1)
        try session.releaseNext(.status(200, TraceTestHarness.acceptedBody))
        try await manager.waitForFlushForTesting()
        #expect(harness.traceFiles().isEmpty)
        #expect(session.requests.count == 1)
    }

    @Test("Spans are only uploaded under the key they were recorded with")
    func spansAreIsolatedByProjectKey() async throws {
        try await harness.recordSpans(1)

        harness.key.value = "prj_test_pk_other"
        try await manager.flushAndWaitForTesting()
        #expect(harness.traceFiles().count == 1)
        #expect(session.requests.isEmpty)

        harness.key.value = TraceTestHarness.publishableKey
        try await manager.flushAndWaitForTesting()
        #expect(harness.traceFiles().isEmpty)
        #expect(session.requests.count == 1)
    }

    @Test(
        "Upload responses map to batch outcomes",
        arguments: [
            (200, #"{"meta":{"code":200}}"#, RadarTraceManager.UploadOutcome.accepted(rejectedSpans: nil)),
            (200, #"{"partialSuccess":{"rejectedSpans":"2"}}"#, .accepted(rejectedSpans: "2")),
            (200, "", .retry),
            (200, "[]", .retry),
            (429, "", .retry),
            (500, "", .retry),
            (503, "", .retry),
            (400, "bad", .drop(statusCode: 400, body: "bad")),
            (401, "", .drop(statusCode: 401, body: "")),
            (404, "", .drop(statusCode: 404, body: "")),
            (413, "", .drop(statusCode: 413, body: "")),
        ]
    )
    func uploadOutcome(statusCode: Int, body: String, expected: RadarTraceManager.UploadOutcome) {
        #expect(RadarTraceManager.outcome(statusCode: statusCode, data: Data(body.utf8)) == expected)
    }

    private func spanId(_ index: Int) -> String {
        TraceTestHarness.spanId(index)
    }

    private func spanIds(_ payload: [String: Any]) -> [String] {
        TraceTestHarness.spanIds(payload)
    }
}
