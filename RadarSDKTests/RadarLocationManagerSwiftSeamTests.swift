//
//  RadarLocationManagerSwiftSeamTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftSeamTests {

        // MARK: - restartPreviousTrackingOptions

        @Test("Swift twin clears previousTrackingOptions when there are none to restart")
        func swiftTwinClearsPreviousTrackingOptionsWhenNone() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarLocationManagerSwift.restartPreviousTrackingOptions()

            #expect(RadarSettings.previousTrackingOptions == nil)
        }

        @Test("Swift twin clears previousTrackingOptions after restarting tracking")
        func swiftTwinClearsPreviousTrackingOptionsAfterRestart() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarSettings.previousTrackingOptions = RadarTrackingOptions.presetResponsive

            RadarLocationManagerSwift.restartPreviousTrackingOptions()

            #expect(RadarSettings.previousTrackingOptions == nil)
        }

        @Test("Public method routes to Swift twin when useSwiftLocationManager is enabled")
        func publicMethodRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useSwiftLocationManager": true
            ])
            RadarSettings.previousTrackingOptions = RadarTrackingOptions.presetResponsive

            RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

            #expect(RadarSettings.previousTrackingOptions == nil)
        }

        @Test("Public method uses ObjC body when useSwiftLocationManager is disabled")
        func publicMethodUsesObjCBodyWhenFlagDisabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useSwiftLocationManager": false
            ])
            RadarSettings.previousTrackingOptions = RadarTrackingOptions.presetResponsive

            RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

            #expect(RadarSettings.previousTrackingOptions == nil)
        }

        // MARK: - matchBeaconIds (pure)

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
