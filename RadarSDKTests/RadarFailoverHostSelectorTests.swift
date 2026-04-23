//
//  RadarFailoverHostSelectorTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
@testable import RadarSDK

@Suite(.serialized)
struct RadarFailoverHostSelectorTests {

    @Test func startsOnPrimary() {
        let selector = RadarFailoverHostSelector(hostCount: 2)
        let (index, isProbe) = selector.indexForNextRequest()
        #expect(index == 0)
        #expect(isProbe == false)
    }

    @Test func primarySuccessStaysOnPrimary() {
        let selector = RadarFailoverHostSelector(hostCount: 2)
        selector.recordRadarResponse(onIndex: 0)
        #expect(selector.indexForNextRequest().index == 0)
    }

    @Test func primaryNonRadarFailureMovesToSecondary() {
        var now = Date(timeIntervalSince1970: 1_000_000)
        let selector = RadarFailoverHostSelector(hostCount: 2, now: { now })

        selector.recordNonRadarFailure(onIndex: 0)

        let (index, isProbe) = selector.indexForNextRequest()
        #expect(index == 1)
        #expect(isProbe == false)

        // Advance time, but still inside the 60s probe window.
        now = now.addingTimeInterval(59)
        #expect(selector.indexForNextRequest().index == 1)

        // Cross the probe boundary.
        now = now.addingTimeInterval(2)
        let probe = selector.indexForNextRequest()
        #expect(probe.index == 0)
        #expect(probe.isProbe == true)
    }

    @Test func probeSuccessReturnsToPrimary() {
        var now = Date(timeIntervalSince1970: 2_000_000)
        let selector = RadarFailoverHostSelector(hostCount: 2, now: { now })
        selector.recordNonRadarFailure(onIndex: 0)
        now = now.addingTimeInterval(RadarFailoverHostSelector.probeInterval + 1)

        // Probe primary and have it succeed.
        _ = selector.indexForNextRequest()
        selector.recordRadarResponse(onIndex: 0)

        // Should now stick with primary indefinitely.
        now = now.addingTimeInterval(10_000)
        #expect(selector.indexForNextRequest().index == 0)
    }

    @Test func probeFailureReArmsTimer() {
        var now = Date(timeIntervalSince1970: 3_000_000)
        let selector = RadarFailoverHostSelector(hostCount: 2, now: { now })

        selector.recordNonRadarFailure(onIndex: 0)
        now = now.addingTimeInterval(RadarFailoverHostSelector.probeInterval + 1)

        // Probe primary and have it fail again.
        _ = selector.indexForNextRequest()
        selector.recordNonRadarFailure(onIndex: 0)

        // Immediately after, we're still in a fresh 60s window on secondary.
        let (index, _) = selector.indexForNextRequest()
        #expect(index == 1)

        now = now.addingTimeInterval(59)
        #expect(selector.indexForNextRequest().index == 1)

        now = now.addingTimeInterval(2)
        #expect(selector.indexForNextRequest().index == 0)
    }

    @Test func secondaryFailureClearsTimerSoPrimaryIsProbedNext() {
        let now = Date(timeIntervalSince1970: 4_000_000)
        let selector = RadarFailoverHostSelector(hostCount: 2, now: { now })

        selector.recordNonRadarFailure(onIndex: 0)
        #expect(selector.indexForNextRequest().index == 1)

        // Secondary also fails — should reset the probe window so the next
        // call immediately tries primary again.
        selector.recordNonRadarFailure(onIndex: 1)

        let (index, isProbe) = selector.indexForNextRequest()
        #expect(index == 0)
        #expect(isProbe == true)
    }

    @Test func resetReturnsToInitialState() {
        let selector = RadarFailoverHostSelector(hostCount: 2)
        selector.recordNonRadarFailure(onIndex: 0)
        selector.reset()
        let (index, isProbe) = selector.indexForNextRequest()
        #expect(index == 0)
        #expect(isProbe == false)
    }

    @Test func threeHostsCycleThroughChain() {
        var now = Date(timeIntervalSince1970: 9_000_000)
        let selector = RadarFailoverHostSelector(hostCount: 3, now: { now })

        // host[0] fails → advance to host[1], arm probe timer
        selector.recordNonRadarFailure(onIndex: 0)
        #expect(selector.indexForNextRequest().index == 1)

        // host[1] fails (middle) → advance to host[2], probe timer re-armed
        selector.recordNonRadarFailure(onIndex: 1)
        #expect(selector.indexForNextRequest().index == 2)

        // Still inside probe window — stay on host[2].
        now = now.addingTimeInterval(30)
        #expect(selector.indexForNextRequest().index == 2)

        // host[2] (last) fails → probe host[0] immediately on next request.
        selector.recordNonRadarFailure(onIndex: 2)
        let (index, isProbe) = selector.indexForNextRequest()
        #expect(index == 0)
        #expect(isProbe == true)
    }
}
