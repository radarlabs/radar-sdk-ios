//
//  RadarTraceSamplingTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTraceManager sampling")
final class RadarTraceSamplingTests {
    private let harness = TraceTestHarness()
    private var manager: RadarTraceManager { harness.manager }
    private var session: TraceURLSession { harness.session }

    init() {
        harness.useServerSampling(sessionId: "1000")
    }

    @Test("Spans wait for their session's sampling decision before uploading")
    func spansWaitForSamplingDecisionBeforeUpload() async throws {
        try await harness.recordSpans(2)

        try await manager.flushAndWaitForTesting()
        #expect(session.requests.isEmpty)
        #expect(harness.pendingFiles().count == 2)
        #expect(manager.samplingState(sessionId: "1000") == .pending)

        manager.onSamplingDecision(sessionId: "1000", sampled: true)
        try await manager.flushAndWaitForTesting()

        #expect(spanIds(session.payloads.first ?? [:]) == [spanId(1), spanId(2)])
        #expect(session.payloads.count == 1)
        #expect(harness.pendingFiles().isEmpty)
        #expect(harness.traceFiles().isEmpty)
    }

    @Test("Spans recorded after a sampled decision are written uploadable")
    func spansAfterSampledDecisionAreWrittenUploadable() async throws {
        manager.onSamplingDecision(sessionId: "1000", sampled: true)

        try await harness.recordSpans(1)

        #expect(harness.pendingFiles().isEmpty)
        #expect(harness.traceFiles().count == 1)
    }

    @Test("A not-sampled decision deletes pending spans and drops later ones")
    func notSampledDecisionDeletesPendingSpansAndDropsLaterSpans() async throws {
        try await harness.recordSpans(2)

        manager.onSamplingDecision(sessionId: "1000", sampled: false)
        try await harness.recordSpans(1, firstId: 3)
        try await manager.flushAndWaitForTesting()

        #expect(manager.samplingState(sessionId: "1000") == .notSampled)
        #expect(harness.pendingFiles().isEmpty)
        #expect(harness.traceFiles().isEmpty)
        #expect(session.requests.isEmpty)
    }

    @Test("A replaced session keeps its pending spans for its own decision")
    func replacedSessionKeepsPendingSpansForItsOwnDecision() async throws {
        // Session 1000 is replaced before its decision arrives, for example by a track that was in flight when the app
        // was resumed. Session 2000's decision must not delete session 1000's spans.
        try await harness.recordSpans(2)
        harness.radarSession.value = "2000"
        try await harness.recordSpans(1, firstId: 3)

        manager.onSamplingDecision(sessionId: "2000", sampled: true)
        try await manager.flushAndWaitForTesting()
        #expect(uploadedSpanIds() == [spanId(3)])
        #expect(harness.pendingFiles().count == 2)

        manager.onSamplingDecision(sessionId: "1000", sampled: true)
        try await manager.flushAndWaitForTesting()
        #expect(Set(uploadedSpanIds()) == [spanId(1), spanId(2), spanId(3)])
        #expect(harness.pendingFiles().isEmpty)
    }

    @Test("Spans from a decided session use its decision after the session changes")
    func spansFromDecidedSessionUseItsDecisionAfterSessionChanges() async throws {
        // A trace started in session 1000 ends after the session changed and the new session was decided.
        manager.onSamplingDecision(sessionId: "1000", sampled: true)
        harness.radarSession.value = "2000"
        manager.onSamplingDecision(sessionId: "2000", sampled: false)

        let project = try harness.project()
        manager.record(TraceTestHarness.span(spanId(1)), project: project, sessionId: "1000")
        manager.record(TraceTestHarness.span(spanId(2)), project: project, sessionId: "2000")
        try await manager.flushAndWaitForTesting()

        #expect(uploadedSpanIds() == [spanId(1)])
        #expect(harness.pendingFiles().isEmpty)
    }

    @Test("A session's first sampled decision is final")
    func firstDecisionForSessionIsFinal() async throws {
        manager.onSamplingDecision(sessionId: "1000", sampled: true)

        // For example, a track response after the sampling rate was lowered.
        manager.onSamplingDecision(sessionId: "1000", sampled: false)
        try await harness.recordSpans(1)
        try await manager.flushAndWaitForTesting()

        #expect(manager.samplingState(sessionId: "1000") == .sampled)
        #expect(uploadedSpanIds() == [spanId(1)])
    }

    @Test("A session's first not-sampled decision is final")
    func firstNotSampledDecisionIsFinal() async throws {
        manager.onSamplingDecision(sessionId: "1000", sampled: false)

        manager.onSamplingDecision(sessionId: "1000", sampled: true)
        try await harness.recordSpans(1)
        try await manager.flushAndWaitForTesting()

        #expect(manager.samplingState(sessionId: "1000") == .notSampled)
        #expect(session.requests.isEmpty)
        #expect(harness.pendingFiles().isEmpty)
    }

    @Test("Starting deletes pending spans from other sessions")
    func startDeletesPendingSpansFromOtherSessions() async throws {
        // The previous process's session was replaced, so no request can carry its decision any more.
        try await harness.recordSpans(2)
        harness.radarSession.value = "2000"
        try await harness.recordSpans(1, firstId: 3)

        harness.manager = harness.makeManager(start: false)
        harness.manager.overrideSampledForTesting(nil)
        manager.start()
        await manager.awaitDiskForTesting()

        // Only the current session's pending span is left.
        #expect(harness.pendingFiles().count == 1)
        manager.onSamplingDecision(sessionId: "2000", sampled: true)
        try await manager.flushAndWaitForTesting()
        #expect(uploadedSpanIds() == [spanId(3)])
    }

    @Test("A late decision for a replaced session leaves the current session pending")
    func lateDecisionForReplacedSessionKeepsCurrentSessionPending() async throws {
        // The config request was sent in session 1000, and the session changed before the response arrived.
        try await harness.recordSpans(1)
        harness.radarSession.value = "2000"
        try await harness.recordSpans(1, firstId: 2)

        manager.onSamplingDecision(sessionId: "1000", sampled: true)
        try await manager.flushAndWaitForTesting()

        #expect(uploadedSpanIds() == [spanId(1)])
        #expect(manager.samplingState(sessionId: "2000") == .pending)
        #expect(harness.pendingFiles().count == 1)

        manager.onSamplingDecision(sessionId: "2000", sampled: false)
        await manager.awaitDiskForTesting()
        #expect(harness.pendingFiles().isEmpty)
    }

    @Test("A new session is pending until its own decision")
    func newSessionIsPendingUntilItsOwnDecision() {
        manager.onSamplingDecision(sessionId: "1000", sampled: true)
        #expect(manager.samplingState(sessionId: manager.currentSessionId()) == .sampled)

        harness.radarSession.value = "2000"

        #expect(manager.samplingState(sessionId: manager.currentSessionId()) == .pending)
    }

    @Test("Pending spans are resolved after a restart in the same session")
    func pendingSpansAreResolvedAfterRestartInTheSameSession() async throws {
        try await harness.recordSpans(2)

        harness.manager = harness.makeManager(start: false)
        harness.manager.overrideSampledForTesting(nil)
        manager.start()
        manager.onSamplingDecision(sessionId: "1000", sampled: true)
        try await manager.flushAndWaitForTesting()

        #expect(Set(uploadedSpanIds()) == [spanId(1), spanId(2)])
        #expect(harness.pendingFiles().isEmpty)
    }

    @Test("Pending spans count toward the storage limits")
    func pendingSpansCountTowardStorageLimits() async throws {
        try await harness.recordSpans(500)
        try await harness.recordSpans(10, firstId: 501)

        #expect(harness.pendingFiles().count == 500)
    }

    @Test("Only the 5 most recent decisions are kept")
    func onlyRecentDecisionsAreKept() {
        for session in 1...6 {
            manager.onSamplingDecision(sessionId: "\(session)", sampled: true)
        }

        #expect(manager.samplingState(sessionId: "1") == .pending)
        #expect((2...6).allSatisfy { manager.samplingState(sessionId: "\($0)") == .sampled })
    }

    // MARK: - Helpers

    private func uploadedSpanIds() -> [String] {
        session.payloads.flatMap(TraceTestHarness.spanIds)
    }

    private func spanIds(_ payload: [String: Any]) -> [String] {
        TraceTestHarness.spanIds(payload)
    }

    private func spanId(_ index: Int) -> String {
        TraceTestHarness.spanId(index)
    }
}
