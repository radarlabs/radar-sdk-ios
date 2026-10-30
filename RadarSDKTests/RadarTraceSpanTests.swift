//
//  RadarTraceSpanTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTraceSpan")
final class RadarTraceSpanTests {
    private let harness = TraceTestHarness()
    private var manager: RadarTraceManager { harness.manager }

    @Test("Child spans share the trace and link to their parent")
    func childSpansShareTraceAndLinkToParent() async throws {
        let root = RadarTraceSpan.start("root", manager: manager)
        let internalChild = root.child("internal")
        let client = root.child("HTTP POST /v1/test", kind: .client)
        client.end(status: .success)
        internalChild.end(status: .success)
        root.end(status: .success)

        let spans = try await uploadedSpans()
        let rootJson = try #require(spans["root"])
        #expect(rootJson["parentSpanId"] == nil)
        #expect(rootJson["kind"] as? Int == RadarSpanKind.internal.rawValue)
        for name in ["internal", "HTTP POST /v1/test"] {
            #expect(spans[name]?["traceId"] as? String == rootJson["traceId"] as? String)
            #expect(spans[name]?["parentSpanId"] as? String == rootJson["spanId"] as? String)
        }
        #expect(spans["internal"]?["kind"] as? Int == RadarSpanKind.internal.rawValue)
        #expect(spans["HTTP POST /v1/test"]?["kind"] as? Int == RadarSpanKind.client.rawValue)
        #expect(client.traceparent == "00-\(client.traceId)-\(client.spanId)-01")
    }

    @Test("IDs are lowercase hex and unique")
    func idsAreLowercaseHexAndUnique() {
        let spans = (1...50).map { _ in RadarTraceSpan.start("root", manager: manager) }

        for span in spans {
            #expect(isLowercaseHex(span.traceId, length: 32), "\(span.traceId)")
            #expect(isLowercaseHex(span.spanId, length: 16), "\(span.spanId)")
        }
        #expect(Set(spans.map(\.traceId)).count == 50)
        #expect(Set(spans.map(\.spanId)).count == 50)
    }

    @Test("end(status:) records once, with the first status")
    func endIsIdempotent() async throws {
        let span = RadarTraceSpan.start("root", manager: manager)
        span.end(status: .success)
        span.end(status: .errorServer)

        let json = try #require(try await uploadedSpans()["root"])
        #expect(session.payloads.flatMap(Self.spans).count == 1)
        #expect(json["status"] == nil)
        #expect(attribute(json, "error.type") == nil)
    }

    @Test("Attributes set after end(status:) are ignored")
    func attributesSetAfterEndAreIgnored() async throws {
        let span = RadarTraceSpan.start("root", manager: manager)
        span.setString("1", forKey: "before")
        span.end(status: .success)
        span.setString("2", forKey: "after")

        let json = try #require(try await uploadedSpans()["root"])
        #expect(attribute(json, "before") != nil)
        #expect(attribute(json, "after") == nil)
    }

    @Test("Attributes are encoded as typed OTLP values")
    func attributesAreEncodedAsOtlpValues() async throws {
        let span = RadarTraceSpan.start("root", manager: manager)
        span.setString("medium", forKey: "string")
        span.setInteger(42, forKey: "integer")
        span.setDouble(1.5, forKey: "double")
        span.setBool(true, forKey: "bool")
        span.end(status: .success)

        let json = try #require(try await uploadedSpans()["root"])
        #expect(attribute(json, "string")?["stringValue"] as? String == "medium")
        // OTLP/JSON encodes int64 as a decimal string.
        #expect(attribute(json, "integer")?["intValue"] as? String == "42")
        #expect(attribute(json, "double")?["doubleValue"] as? Double == 1.5)
        #expect(attribute(json, "bool")?["boolValue"] as? Bool == true)
    }

    @Test("An error status sets the OTLP error status and error.type")
    func errorStatusSetsOtlpErrorAndErrorType() async throws {
        RadarTraceSpan.start("root", manager: manager).end(status: .errorNetwork)

        let json = try #require(try await uploadedSpans()["root"])
        #expect((json["status"] as? [String: Any])?["code"] as? Int == 2)
        #expect(attribute(json, "error.type")?["stringValue"] as? String == "ERROR_NETWORK")
    }

    @Test("Timestamps are Unix nanoseconds as decimal strings")
    func timestampsAreUnixNanoStrings() async throws {
        let span = RadarTraceSpan.start("root", manager: manager)
        harness.clock.advance(milliseconds: 250)
        span.end(status: .success)

        let json = try #require(try await uploadedSpans()["root"])
        #expect(json["startTimeUnixNano"] as? String == "1780000000000000000")
        #expect(json["endTimeUnixNano"] as? String == "1780000000250000000")
    }

    @Test("Duration comes from the monotonic clock, not the wall clock")
    func durationUsesMonotonicClock() async throws {
        let span = RadarTraceSpan.start("root", manager: manager)
        harness.clock.advance(milliseconds: 1500)
        // The wall clock jumps back while the span is open, as a time sync can do.
        harness.clock.setWallClock(milliseconds: 1_000)
        span.end(status: .success)

        let json = try #require(try await uploadedSpans()["root"])
        let start = try #require(UInt64(json["startTimeUnixNano"] as? String ?? ""))
        let end = try #require(UInt64(json["endTimeUnixNano"] as? String ?? ""))
        #expect(start == 1_780_000_000_000_000_000)
        #expect(end - start == 1_500_000_000)
    }

    @Test("A span started before its session is decided records, but sends no traceparent")
    func spanStartedBeforeDecisionIsNotNoOp() {
        harness.useServerSampling(sessionId: "1000")

        let root = RadarTraceSpan.start("root", manager: manager)
        let child = root.child("HTTP POST /v1/test", kind: .client)

        // Pending spans are real so they can be kept until the decision arrives.
        #expect(root !== RadarTraceSpan.noop)
        #expect(root !== child)
        #expect(child.traceId == root.traceId)
        // No header while the decision is pending, and never the not-sampled flag.
        #expect(child.traceparent == nil)

        manager.onSamplingDecision(sessionId: "1000", sampled: true)
        #expect(child.traceparent == "00-\(child.traceId)-\(child.spanId)-01")
    }

    @Test("A span's traceparent is dropped once its session is not sampled")
    func traceparentIsOmittedWhenSessionIsNotSampled() {
        harness.useServerSampling(sessionId: "1000")
        let span = RadarTraceSpan.start("root", manager: manager)

        manager.onSamplingDecision(sessionId: "1000", sampled: false)

        #expect(span.traceparent == nil)
    }

    @Test("Child spans use the session their trace started in")
    func childSpansUseTheSessionTheirTraceStartedIn() {
        harness.useServerSampling(sessionId: "1000")
        let root = RadarTraceSpan.start("root", manager: manager)
        harness.radarSession.value = "2000"
        let child = root.child("HTTP POST /v1/test", kind: .client)

        manager.onSamplingDecision(sessionId: "2000", sampled: false)
        manager.onSamplingDecision(sessionId: "1000", sampled: true)

        #expect(child.traceparent == "00-\(child.traceId)-\(child.spanId)-01")
    }

    @Test("A span in a session that isn't sampled is the shared no-op span")
    func spanIsNoOpWhenSessionIsNotSampled() {
        harness.useServerSampling(sessionId: "1000")
        manager.onSamplingDecision(sessionId: "1000", sampled: false)

        let root = RadarTraceSpan.start("root", manager: manager)

        #expect(root === RadarTraceSpan.noop)
        #expect(root.traceparent == nil)
    }

    @Test("An unsampled trace is the shared no-op span")
    func unsampledSpanIsNoOp() async throws {
        manager.overrideSampledForTesting(false)

        let root = RadarTraceSpan.start("root", manager: manager)
        let child = root.child("HTTP POST /v1/test", kind: .client)
        child.setString("value", forKey: "key")
        child.end(status: .success)
        root.end(status: .success)

        #expect(root.traceparent == nil)
        #expect(child.traceparent == nil)
        #expect(root === child)
        #expect(root === RadarTraceSpan.start("other", manager: manager))
        try await manager.flushAndWaitForTesting()
        #expect(harness.session.requests.isEmpty)
    }

    @Test("Spans are no-ops before tracing starts")
    func spanIsNoOpBeforeStart() {
        let notStarted = harness.makeManager(start: false)
        notStarted.overrideSampledForTesting(true)

        let root = RadarTraceSpan.start("root", manager: notStarted)

        #expect(root === RadarTraceSpan.noop)
        #expect(root.child("child").traceparent == nil)
    }

    @Test("Spans are no-ops without a publishable key")
    func spanIsNoOpWithoutPublishableKey() async {
        harness.key.value = nil

        let root = RadarTraceSpan.start("root", manager: manager)
        root.end(status: .success)

        #expect(root.traceparent == nil)
        await manager.awaitDiskForTesting()
        #expect(harness.traceFiles().isEmpty)
    }

    @Test("Attribute updates racing end(status:) don't drop spans")
    func attributeUpdatesRacingEndDoNotDropSpans() async throws {
        // Writers keep adding attributes while end(status:) snapshots them. Without the lock, concurrent dictionary
        // mutation corrupts the span or crashes. A race test only fails when it hits the window, so it runs many spans
        // and ends each one while the writers are midway through.
        let spanCount = 200
        for index in 0..<spanCount {
            await raceAttributeWritesAgainstEnd(RadarTraceSpan.start("span-\(index)", manager: manager))
            // Upload as we go so the spans stay well under the storage limits.
            if index % 10 == 9 {
                try await manager.flushAndWaitForTesting()
            }
        }

        let names = Set(session.payloads.flatMap(Self.spans).compactMap { $0["name"] as? String })
        #expect(names == Set((0..<spanCount).map { "span-\($0)" }))
    }

    @Test("Objective-C can reach the span API")
    func objectiveCSurface() {
        // The class must keep its unmangled runtime name for RadarTraceSpan+Internal.h to link.
        #expect(NSClassFromString("RadarTraceSpan") === RadarTraceSpan.self)
        #expect(RadarTraceSpan.responds(to: NSSelectorFromString("startWithName:")))
        let selectors = [
            "child:", "clientChild:", "traceparent", "setString:forKey:", "setInteger:forKey:", "setDouble:forKey:",
            "setBool:forKey:", "endWithStatus:",
        ]
        for selector in selectors {
            #expect(RadarTraceSpan.instancesRespond(to: NSSelectorFromString(selector)), "\(selector)")
        }
    }

    // MARK: - Helpers

    private var session: TraceURLSession { harness.session }

    /// Three writers each set 2,000 attributes on `span`, which ends once all of them have started. Keys repeat after
    /// 200, so a span holds at most 600 attributes. Waits by suspending, so it doesn't hold a thread other tests need.
    private func raceAttributeWritesAgainstEnd(_ span: RadarTraceSpan) async {
        let writers = 3
        let finished = DispatchGroup()
        let started = DispatchGroup()
        for writer in 0..<writers {
            started.enter()
            DispatchQueue.global().async(group: finished) {
                for key in 0..<2_000 {
                    span.setInteger(Int64(key), forKey: "w\(writer)-\(key % 200)")
                    if key == 20 {
                        started.leave()
                    }
                }
            }
        }
        await withCheckedContinuation { continuation in
            started.notify(queue: .global()) { continuation.resume() }
        }
        span.end(status: .success)
        await withCheckedContinuation { continuation in
            finished.notify(queue: .global()) { continuation.resume() }
        }
    }

    /// Flushes, then returns every uploaded span by name.
    private func uploadedSpans() async throws -> [String: [String: Any]] {
        try await manager.flushAndWaitForTesting()
        let spans = session.payloads.flatMap(Self.spans)
        return Dictionary(spans.map { ($0["name"] as? String ?? "", $0) }, uniquingKeysWith: { first, _ in first })
    }

    private static func spans(_ payload: [String: Any]) -> [[String: Any]] {
        TraceTestHarness.scopeSpans(payload)?["spans"] as? [[String: Any]] ?? []
    }

    private func isLowercaseHex(_ value: String, length: Int) -> Bool {
        value.count == length && value.allSatisfy { ("0"..."9").contains($0) || ("a"..."f").contains($0) }
    }

    private func attribute(_ span: [String: Any], _ key: String) -> [String: Any]? {
        let attributes = span["attributes"] as? [[String: Any]] ?? []
        return attributes.first { $0["key"] as? String == key }?["value"] as? [String: Any]
    }
}
