//
//  RadarTraceManager+Sampling.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

// The server's per-session sampling decisions (`tracingEnabled` in `/v1/config` and `/v1/track` responses).
//
// A decision only covers the session it was made for, so a new session is pending until its own decision arrives.
// A trace keeps the session it started in, so spans that end after the session changes still need the previous
// session's decision. Decisions are remembered in memory only.
extension RadarTraceManager {

    /// Whether spans in a session are uploaded, dropped, or kept until the server decides.
    enum SamplingState: Sendable {
        case sampled
        case notSampled
        case pending
    }

    // The session can change in the middle of a trace, so at least two decisions must be kept. Five allows for
    // several session changes between a trace's start and end. Session ID updates at most every 5 minutes.
    static let maxSamplingDecisions = 5

    func samplingState(sessionId: String) -> SamplingState {
        samplingLock.withLock {
            if let sampledOverride {
                return sampledOverride ? .sampled : .notSampled
            }
            guard let decision = samplingDecisions.first(where: { $0.sessionId == sessionId }) else { return .pending }
            return decision.sampled ? .sampled : .notSampled
        }
    }

    /// Applies the server's sampling decision for `sessionId`, which must be the session sent with the request, not the
    /// current one: the session can change while a request is in flight. Pending spans from that session become
    /// uploadable if sampled and are deleted otherwise. Only a session's first decision counts, so a session's sampling
    /// can't change partway through, for example if the sampling rate changes.
    @objc(onSamplingDecisionForSessionId:sampled:)
    func onSamplingDecision(sessionId: String, sampled: Bool) {
        let isFirst = samplingLock.withLock {
            guard !samplingDecisions.contains(where: { $0.sessionId == sessionId }) else { return false }
            samplingDecisions.append((sessionId, sampled))
            if samplingDecisions.count > Self.maxSamplingDecisions {
                samplingDecisions.removeFirst()
            }
            return true
        }
        guard isFirst else { return }
        disk.async { self.store.resolvePending(sessionId: sessionId, sampled: sampled) }
        if sampled {
            flush()
        }
    }

    /// Forces every session to be sampled (true) or not (false), for example to trace 100% locally. Nil uses the
    /// server's decisions.
    func overrideSampledForTesting(_ sampled: Bool?) {
        samplingLock.withLock { sampledOverride = sampled }
    }
}
