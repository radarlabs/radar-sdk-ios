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

@Suite(.serialized)
actor RadarLocationManagerSwiftSeamTests {

    private func clearState() {
        RadarSettings.previousTrackingOptions = nil
        RadarSettings.sdkConfiguration = nil
    }

    private func makeBeacon(id: String, uuid: String, major: String, minor: String) -> RadarBeacon {
        let geometry = RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))!
        return RadarBeacon(
            id: id,
            description: nil,
            tag: "",
            externalId: "",
            uuid: uuid,
            major: major,
            minor: minor,
            metadata: nil,
            geometry: geometry
        )!
    }

    // MARK: - restartPreviousTrackingOptions (existing)

    @Test("Swift twin clears previousTrackingOptions when there are none to restart")
    func swiftTwinClearsPreviousTrackingOptionsWhenNone() {
        clearState()
        defer { clearState() }

        RadarLocationManagerSwift.restartPreviousTrackingOptions()

        #expect(RadarSettings.previousTrackingOptions == nil)
    }

    @Test("Swift twin clears previousTrackingOptions after restarting tracking")
    func swiftTwinClearsPreviousTrackingOptionsAfterRestart() {
        clearState()
        defer { clearState() }

        RadarSettings.previousTrackingOptions = RadarTrackingOptions.presetResponsive

        RadarLocationManagerSwift.restartPreviousTrackingOptions()

        #expect(RadarSettings.previousTrackingOptions == nil)
    }

    @Test("Public method routes to Swift twin when useSwiftLocationManager is enabled")
    func publicMethodRoutesToSwiftTwinWhenFlagEnabled() {
        clearState()
        defer { clearState() }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useSwiftLocationManager": true
        ])
        RadarSettings.previousTrackingOptions = RadarTrackingOptions.presetResponsive

        RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

        #expect(RadarSettings.previousTrackingOptions == nil)
    }

    @Test("Public method uses ObjC body when useSwiftLocationManager is disabled")
    func publicMethodUsesObjCBodyWhenFlagDisabled() {
        clearState()
        defer { clearState() }

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
            makeBeacon(id: "syncedA", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2"),
            makeBeacon(id: "syncedB", uuid: "22222222-2222-2222-2222-222222222222", major: "3", minor: "4"),
        ]
        let ranged = [
            makeBeacon(id: "rangedA", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2"),
            makeBeacon(id: "rangedB", uuid: "33333333-3333-3333-3333-333333333333", major: "9", minor: "9"),
            makeBeacon(id: "rangedC", uuid: "22222222-2222-2222-2222-222222222222", major: "3", minor: "4"),
        ]

        let matched = RadarLocationManagerSwift.matchBeaconIds(ranged: ranged, synced: synced)

        #expect(matched == ["syncedA", "syncedB"])
    }

    @Test("matchBeaconIds returns empty when no ranged beacon matches a synced beacon")
    func matchBeaconIdsReturnsEmptyWhenNoMatches() {
        let synced = [
            makeBeacon(id: "syncedA", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2")
        ]
        let ranged = [
            makeBeacon(id: "rangedA", uuid: "11111111-1111-1111-1111-111111111111", major: "9", minor: "9")
        ]

        let matched = RadarLocationManagerSwift.matchBeaconIds(ranged: ranged, synced: synced)

        #expect(matched.isEmpty)
    }

    @Test("matchBeaconIds is case-insensitive on UUID")
    func matchBeaconIdsLowercasesUUID() {
        let synced = [
            makeBeacon(id: "syncedA", uuid: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA", major: "1", minor: "2")
        ]
        let ranged = [
            makeBeacon(id: "rangedA", uuid: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", major: "1", minor: "2")
        ]

        let matched = RadarLocationManagerSwift.matchBeaconIds(ranged: ranged, synced: synced)

        #expect(matched == ["syncedA"])
    }

    @Test("matchBeaconIds returns empty for empty inputs")
    func matchBeaconIdsHandlesEmptyInputs() {
        let matched = RadarLocationManagerSwift.matchBeaconIds(ranged: [], synced: [])

        #expect(matched.isEmpty)
    }

    // MARK: - Region removal smoke tests

    @Test("Region removal methods do not crash when called against the shared instance")
    func regionRemovalMethodsDoNotCrash() {
        clearState()
        defer { clearState() }

        let locationManager = RadarLocationManager.sharedInstance().locationManager

        RadarLocationManagerSwift.removeBubbleGeofence(locationManager: locationManager)
        RadarLocationManagerSwift.removeSyncedGeofences(locationManager: locationManager)
        RadarLocationManagerSwift.removeSyncedBeacons(locationManager: locationManager)
        RadarLocationManagerSwift.removeAllRegions(locationManager: locationManager)
    }

    @Test("Public replaceSyncedBeacons routes to Swift twin when flag enabled")
    func publicReplaceSyncedBeaconsRoutesToSwiftTwinWhenFlagEnabled() {
        clearState()
        defer { clearState() }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useSwiftLocationManager": true,
            "useRadarModifiedBeacon": true
        ])

        RadarLocationManager.sharedInstance().replaceSyncedBeacons([])
    }

    // MARK: - replaceSyncedBeacons short-circuits

    @Test("replaceSyncedBeacons no-ops when useRadarModifiedBeacon is enabled")
    func replaceSyncedBeaconsNoOpsWhenUseRadarModifiedBeacon() {
        clearState()
        defer { clearState() }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useRadarModifiedBeacon": true
        ])
        let beacons = [
            makeBeacon(id: "syncedA", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2")
        ]

        RadarLocationManagerSwift.replaceSyncedBeacons(
            locationManager: RadarLocationManager.sharedInstance().locationManager,
            beacons: beacons
        )
    }

    @Test("replaceSyncedBeaconUUIDs no-ops when useRadarModifiedBeacon is enabled")
    func replaceSyncedBeaconUUIDsNoOpsWhenUseRadarModifiedBeacon() {
        clearState()
        defer { clearState() }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useRadarModifiedBeacon": true
        ])

        RadarLocationManagerSwift.replaceSyncedBeaconUUIDs(
            locationManager: RadarLocationManager.sharedInstance().locationManager,
            uuids: ["11111111-1111-1111-1111-111111111111"]
        )
    }
}
