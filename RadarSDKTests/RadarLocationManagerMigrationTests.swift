//
//  RadarLocationManagerMigrationTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Testing
@testable import RadarSDK

@Suite(.serialized)
actor RadarLocationManagerMigrationTests {
    @Test("Location manager Swift migration flag defaults off")
    func migrationFlagDefaultsOff() {
        RadarUserDefaults.set(nil, forKey: .LocationManagerSwiftMigrationEnabled)

        #expect(RadarSettings.locationManagerSwiftMigrationEnabled == false)
    }

    @Test("Location manager Swift migration flag round trips")
    func migrationFlagRoundTrips() {
        RadarSettings.locationManagerSwiftMigrationEnabled = true
        #expect(RadarSettings.locationManagerSwiftMigrationEnabled == true)

        RadarSettings.locationManagerSwiftMigrationEnabled = false
        #expect(RadarSettings.locationManagerSwiftMigrationEnabled == false)
    }
}
