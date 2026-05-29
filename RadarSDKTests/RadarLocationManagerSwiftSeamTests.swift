//
//  RadarLocationManagerSwiftSeamTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftSeamTests {

        // MARK: - restartPreviousTrackingOptions — Swift twin

        @Test("Swift twin calls Radar.stopTracking and clears previousTrackingOptions when none to restart")
        func swiftTwinStopsTrackingWhenNoPreviousOptions() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            // Seed `tracking = true` to observe that `Radar.stopTracking()` actually flipped it off.
            RadarSettings.tracking = true

            RadarLocationManagerSwift.restartPreviousTrackingOptions()

            #expect(RadarSettings.previousTrackingOptions == nil)
            #expect(RadarSettings.tracking == false)
        }

        @Test("Swift twin restarts tracking with previous options and clears previousTrackingOptions")
        func swiftTwinRestartsTrackingAndClearsPreviousOptions() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            // Authorize location so `Radar.startTracking(trackingOptions:)` proceeds past the
            // permission gate in `RadarLocationManager.startTrackingWithOptions:`.
            RadarLocationManagerSwiftTestHelpers.installAuthorizedPermissions()
            let previousOptions = RadarTrackingOptions.presetResponsive
            RadarSettings.previousTrackingOptions = previousOptions

            RadarLocationManagerSwift.restartPreviousTrackingOptions()

            // Previous slot cleared, tracking is now active, and the live tracking options
            // equal the previous options — proving `Radar.startTracking(trackingOptions:)` was
            // called with the right argument.
            #expect(RadarSettings.previousTrackingOptions == nil)
            #expect(RadarSettings.tracking == true)
            #expect(RadarSettings.trackingOptions == previousOptions)
        }

        // MARK: - restartPreviousTrackingOptions — public method routing

        @Test("Public method routes to Swift twin when useSwiftLocationManager is enabled")
        func publicMethodRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarLocationManagerSwiftTestHelpers.installAuthorizedPermissions()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useSwiftLocationManager": true
            ])
            let previousOptions = RadarTrackingOptions.presetResponsive
            RadarSettings.previousTrackingOptions = previousOptions

            RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

            #expect(RadarSettings.previousTrackingOptions == nil)
            #expect(RadarSettings.tracking == true)
            #expect(RadarSettings.trackingOptions == previousOptions)
        }

        @Test("Public method uses ObjC body when useSwiftLocationManager is disabled")
        func publicMethodUsesObjCBodyWhenFlagDisabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarLocationManagerSwiftTestHelpers.installAuthorizedPermissions()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useSwiftLocationManager": false
            ])
            let previousOptions = RadarTrackingOptions.presetResponsive
            RadarSettings.previousTrackingOptions = previousOptions

            RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

            // ObjC body should land in the same end state as the Swift twin.
            #expect(RadarSettings.previousTrackingOptions == nil)
            #expect(RadarSettings.tracking == true)
            #expect(RadarSettings.trackingOptions == previousOptions)
        }

        // MARK: - matchBeaconIds (pure function)

        @Test("matchBeaconIds returns Radar IDs for beacons whose uuid/major/minor match a synced beacon")
        func matchBeaconIdsMatchesOnUUIDMajorMinor() {
            let synced = [
                RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "syncedA", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2"),
                RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "syncedB", uuid: "22222222-2222-2222-2222-222222222222", major: "3", minor: "4"),
            ]
            let ranged = [
                RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "rangedA", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2"),
                RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "rangedB", uuid: "33333333-3333-3333-3333-333333333333", major: "9", minor: "9"),
                RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "rangedC", uuid: "22222222-2222-2222-2222-222222222222", major: "3", minor: "4"),
            ]

            let matched = RadarLocationManagerSwift.matchBeaconIds(ranged: ranged, synced: synced)

            #expect(matched == ["syncedA", "syncedB"])
        }

        @Test("matchBeaconIds returns empty when no ranged beacon matches a synced beacon")
        func matchBeaconIdsReturnsEmptyWhenNoMatches() {
            let synced = [
                RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "syncedA", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2")
            ]
            let ranged = [
                RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "rangedA", uuid: "11111111-1111-1111-1111-111111111111", major: "9", minor: "9")
            ]

            let matched = RadarLocationManagerSwift.matchBeaconIds(ranged: ranged, synced: synced)

            #expect(matched.isEmpty)
        }

        @Test("matchBeaconIds is case-insensitive on UUID")
        func matchBeaconIdsLowercasesUUID() {
            let synced = [
                RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "syncedA", uuid: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA", major: "1", minor: "2")
            ]
            let ranged = [
                RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "rangedA", uuid: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", major: "1", minor: "2")
            ]

            let matched = RadarLocationManagerSwift.matchBeaconIds(ranged: ranged, synced: synced)

            #expect(matched == ["syncedA"])
        }

        @Test("matchBeaconIds returns empty for empty inputs")
        func matchBeaconIdsHandlesEmptyInputs() {
            let matched = RadarLocationManagerSwift.matchBeaconIds(ranged: [], synced: [])

            #expect(matched.isEmpty)
        }
    }
}
