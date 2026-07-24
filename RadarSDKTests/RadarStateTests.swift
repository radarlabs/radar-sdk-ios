//
//  RadarStateTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 6/30/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite(.serialized)
struct RadarStateTests {

    @Test func registeredNotificationsGetterIgnoresPoisonedCache() {
        // Snapshot written by a legacy build: a host `Data` value in userInfo
        let poisoned: [[String: Any]] = [["identifier": "radar_x", "info": Data("x".utf8)]]
        RadarUserDefaults.set(poisoned, forKey: .registeredNotifications)
        defer { RadarUserDefaults.set(nil, forKey: .registeredNotifications) }

        // Must not crash; returns nil because the snapshot isn't valid JSON.
        #expect(RadarState().registeredNotifications == nil)
    }

    @Test func registeredNotificationsReadsValidSnapshot() {
        let valid: [[String: Any]] = [
            ["identifier": "radar_x", "registeredAt": 123.0, "geofenceId": "g1", "campaignId": "c1"]
        ]
        RadarUserDefaults.set(valid, forKey: .registeredNotifications)
        defer { RadarUserDefaults.set(nil, forKey: .registeredNotifications) }

        let result = RadarState().registeredNotifications
        #expect(result?.count == 1)
        #expect(result?.first?.identifier == "radar_x")
        #expect(result?.first?.registeredAt == 123.0)
        #expect(result?.first?.geofenceId == "g1")
        #expect(result?.first?.campaignId == "c1")
    }
}
