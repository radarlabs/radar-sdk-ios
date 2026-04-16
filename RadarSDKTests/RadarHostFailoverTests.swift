//
//  RadarHostFailoverTests.swift
//  RadarSDKTests
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Testing
@testable import RadarSDK

@Suite(.serialized)
struct RadarHostFailoverTests {

    let primary = "api.radar.io"
    let fallback1 = "api-fallback1.radar.io"
    let fallback2 = "api-fallback2.radar.io"

    // MARK: - Initial state

    @Test func currentHost_returnsPrimaryInitially() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        #expect(failover.currentHost == primary)
    }

    @Test func currentHost_singleHost() {
        let failover = RadarHostFailover(hosts: [primary])
        #expect(failover.currentHost == primary)
    }

    // MARK: - reportFailure

    @Test func reportFailure_returnsTrueWhenAlternateAvailable() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        #expect(failover.reportFailure() == true)
    }

    @Test func reportFailure_switchesToFallback() {
        let failover = RadarHostFailover(hosts: [primary, fallback1, fallback2])
        failover.reportFailure()
        #expect(failover.currentHost == fallback1)
    }

    @Test func reportFailure_returnsFalseOnLastHost() {
        let failover = RadarHostFailover(hosts: [primary])
        #expect(failover.reportFailure() == false)
    }

    @Test func reportFailure_advancesThroughAllHosts() {
        let failover = RadarHostFailover(hosts: [primary, fallback1, fallback2])

        #expect(failover.reportFailure() == true)
        #expect(failover.currentHost == fallback1)

        #expect(failover.reportFailure() == true)
        #expect(failover.currentHost == fallback2)

        #expect(failover.reportFailure() == false)
    }

    // MARK: - reportSuccess

    @Test func reportSuccess_normalModeDoesNotChangeHost() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        failover.reportSuccess()
        #expect(failover.currentHost == primary)
    }

    @Test func reportSuccess_notProbingStaysOnFallback() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        failover.reportFailure()
        // Within backoff so not probing; reportSuccess should not reset to primary
        failover.reportSuccess()
        #expect(failover.currentHost == fallback1)
    }

    // MARK: - Probing behavior

    @Test func currentHost_probesPrimaryAfterBackoff() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        failover.reportFailure()

        // Simulate backoff elapsed
        failover.lastFailureTime = Date(timeIntervalSinceNow: -60)

        #expect(failover.currentHost == primary)
    }

    @Test func reportSuccess_afterProbeResetsToPrimary() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        failover.reportFailure()

        // Simulate backoff elapsed and trigger probe
        failover.lastFailureTime = Date(timeIntervalSinceNow: -60)
        #expect(failover.currentHost == primary)

        // Probe succeeds
        failover.reportSuccess()
        #expect(failover.currentHost == primary)
    }

    @Test func reportFailure_probeFailedDoublesBackoff() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        failover.reportFailure()

        // Simulate backoff elapsed to trigger probe
        failover.lastFailureTime = Date(timeIntervalSinceNow: -60)
        _ = failover.currentHost // sets isProbingPrimary = true

        // Probe fails
        #expect(failover.reportFailure() == true)

        // Backoff should have doubled from 30 to 60
        #expect(failover.currentBackoff == 60.0)
    }

    @Test func backoffCapsAt300Seconds() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        failover.reportFailure()

        // Repeatedly probe and fail: 30 -> 60 -> 120 -> 240 -> 300 (cap)
        for _ in 0..<10 {
            failover.lastFailureTime = Date(timeIntervalSinceNow: -600)
            _ = failover.currentHost // trigger probe
            failover.reportFailure() // probe fails, doubles backoff
        }

        #expect(failover.currentBackoff == 300.0)
    }

    @Test func reportSuccess_resetsBackoffToInitial() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        failover.reportFailure()

        // Drive backoff up
        failover.lastFailureTime = Date(timeIntervalSinceNow: -60)
        _ = failover.currentHost
        failover.reportFailure() // backoff now 60

        // Probe again and succeed
        failover.lastFailureTime = Date(timeIntervalSinceNow: -120)
        _ = failover.currentHost
        failover.reportSuccess()

        #expect(failover.currentBackoff == 30.0)
    }

    // MARK: - Fallback during backoff

    @Test func currentHost_returnsFallbackDuringBackoff() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        failover.reportFailure()

        // lastFailureTime is now, so backoff hasn't elapsed
        #expect(failover.currentHost == fallback1)
        #expect(failover.currentHost == fallback1)
    }

    // MARK: - Full failover cycle

    @Test func fullCycle_failoverProbeRecover() {
        let failover = RadarHostFailover(hosts: [primary, fallback1, fallback2])

        // 1. Start on primary
        #expect(failover.currentHost == primary)

        // 2. Primary fails, move to fallback1
        failover.reportFailure()
        #expect(failover.currentHost == fallback1)

        // 3. Backoff elapses, probe primary
        failover.lastFailureTime = Date(timeIntervalSinceNow: -60)
        #expect(failover.currentHost == primary)

        // 4. Probe fails, stay on fallback1 with doubled backoff
        failover.reportFailure()
        #expect(failover.currentHost == fallback1)

        // 5. Backoff elapses again, probe primary
        failover.lastFailureTime = Date(timeIntervalSinceNow: -120)
        #expect(failover.currentHost == primary)

        // 6. Probe succeeds, back to primary
        failover.reportSuccess()
        #expect(failover.currentHost == primary)
    }

    @Test func failoverToSecondFallbackThenRecover() {
        let failover = RadarHostFailover(hosts: [primary, fallback1, fallback2])

        // Fail through to fallback2
        failover.reportFailure() // -> fallback1
        failover.reportFailure() // -> fallback2
        #expect(failover.currentHost == fallback2)

        // Backoff elapses, probe primary, succeeds
        failover.lastFailureTime = Date(timeIntervalSinceNow: -60)
        #expect(failover.currentHost == primary)
        failover.reportSuccess()

        // Fully recovered
        #expect(failover.currentHost == primary)
    }

    @Test func reportFailure_onLastHostReturnsFalseRepeatedly() {
        let failover = RadarHostFailover(hosts: [primary, fallback1])
        failover.reportFailure() // -> fallback1
        #expect(failover.reportFailure() == false) // already on last host
        #expect(failover.reportFailure() == false) // still on last host
    }
}
