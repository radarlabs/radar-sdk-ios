//
//  RadarVerifiedRefreshSchedulingTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/12/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable import class RadarSDK.RadarVerifiedLocationToken

// Captures the requested delay without starting a real timer.
private final class RefreshSchedulingManager: RadarVerificationManager {
    var scheduledDelays: [TimeInterval] = []

    override func perform(
        _ aSelector: Selector,
        with anArgument: Any?,
        afterDelay delay: TimeInterval
    ) {
        scheduledDelays.append(delay)
    }
}

final class RadarVerifiedRefreshSchedulingTests: XCTestCase {
    func test_cachedIDFromOneShotDoesNotDriveRefreshExpiry() throws {
        let token = try XCTUnwrap(
            RadarVerifiedLocationToken(object: [
                "format": "id",
                "_id": "lookup-id",
            ])
        )

        let delay = try scheduledDelay(for: token)

        // A prior one-shot ID can remain cached before a continuous request completes.
        // Its missing expiry must not override the configured refresh interval.
        XCTAssertEqual(delay, 290, accuracy: 0.1)
    }

    func test_JWEUsesRemainingTokenLifetime() throws {
        let token = try XCTUnwrap(
            RadarVerifiedLocationToken(object: [
                "format": "jwe",
                "_id": "evaluation-id",
                "token": "opaque-token",
                "expiresAt": "2030-01-01T00:00:00.000Z",
                "expiresIn": 90,
                "passed": true,
            ])
        )

        let delay = try scheduledDelay(for: token)

        // Lifetime of 90 seconds, minus 20 elapsed and the early refresh margin.
        XCTAssertEqual(delay, 60, accuracy: 0.1)
    }

    private func scheduledDelay(
        for token: RadarVerifiedLocationToken
    ) throws -> TimeInterval {
        let manager = RefreshSchedulingManager()
        manager.started = true
        manager.setValue(300.0, forKey: "startedInterval")
        manager.setValue(token, forKey: "lastToken")
        manager.setValue(
            ProcessInfo.processInfo.systemUptime - 20,
            forKey: "lastTokenSystemUptime"
        )

        _ = manager.perform(
            NSSelectorFromString("scheduleNextIntervalWithLastToken")
        )

        XCTAssertEqual(manager.scheduledDelays.count, 1)
        return try XCTUnwrap(manager.scheduledDelays.first)
    }
}
