//
//  RadarReplayBufferTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 6/29/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import XCTest

@testable import RadarSDK

final class RadarReplayBufferTests: XCTestCase {

    func test_writeNewReplay_persistsAndReloads() throws {
        let sdkConfiguration = RadarSdkConfiguration(dict: [
            "logLevel": "warning",
            "startTrackingOnInitialize": false,
            "trackOnceOnAppOpen": false,
            "usePersistence": true,
            "extendFlushReplays": false,
            "useLogPersistence": false,
            "useRadarModifiedBeacon": false,
            "syncAfterSetUser": false,
        ])
        RadarSettings.sdkConfiguration = sdkConfiguration

        let params: [AnyHashable: Any] = [
            "latitude": 0.1,
            "longitude": 0.1,
            "replayed": true,
            "stateCode": "StateCode",
        ]

        let buffer = RadarReplayBuffer.sharedInstance
        buffer.clearBuffer()
        buffer.writeNewReplayToBuffer(params)

        // wipe in-memory only (persistence remains), then reload from the store
        buffer.mutableReplayBuffer = []
        buffer.loadReplaysFromPersistentStore()

        XCTAssertEqual(buffer.mutableReplayBuffer.count, 1)
        XCTAssertEqual(
            buffer.mutableReplayBuffer.first?.replayParams as NSDictionary?,
            params as NSDictionary
        )
    }
}
