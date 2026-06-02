//
//  RadarLocationManagerSwiftBeaconSyncTests.swift
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
    actor RadarLocationManagerSwiftBeaconSyncTests {

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

        // MARK: - replaceSyncedBeacons

        @Test("replaceSyncedBeacons no-ops (does not even remove) when useRadarModifiedBeacon is enabled")
        func replaceSyncedBeaconsNoOpsWhenUseRadarModifiedBeacon() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useRadarModifiedBeacon": true
            ])

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_beacon_existing"])
            let beacons = [
                RadarLocationManagerSwiftTestHelpers.makeBeacon(
                    id: "syncedA", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2"
                )
            ]

            RadarLocationManagerSwift.replaceSyncedBeacons(locationManager: manager, beacons: beacons)

            // Short-circuit before remove or add — existing region preserved untouched.
            #expect(manager.trackedRegions.count == 1)
        }

        @Test("replaceSyncedBeacons removes existing beacons but skips adding when tracking is false")
        func replaceSyncedBeaconsSkipsAddWhenNotTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = false
            RadarSettings.trackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_beacon_existing", "radar_uuid_existing"])
            let beacons = [
                RadarLocationManagerSwiftTestHelpers.makeBeacon(
                    id: "syncedA", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2"
                )
            ]

            RadarLocationManagerSwift.replaceSyncedBeacons(locationManager: manager, beacons: beacons)

            #expect(manager.trackedRegions.isEmpty)
        }

        @Test("replaceSyncedBeacons skips adding when options.beacons is false")
        func replaceSyncedBeaconsSkipsAddWhenBeaconsOptionDisabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = true
            RadarSettings.trackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: false)

            let manager = TrackingCLLocationManager()
            let beacons = [
                RadarLocationManagerSwiftTestHelpers.makeBeacon(
                    id: "syncedA", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2"
                )
            ]

            RadarLocationManagerSwift.replaceSyncedBeacons(locationManager: manager, beacons: beacons)

            #expect(manager.trackedRegions.isEmpty)
        }

        @Test("replaceSyncedBeacons skips adding when beacons is nil")
        func replaceSyncedBeaconsSkipsAddWhenNilBeacons() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = true
            RadarSettings.trackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)

            let manager = TrackingCLLocationManager()

            RadarLocationManagerSwift.replaceSyncedBeacons(locationManager: manager, beacons: nil)

            #expect(manager.trackedRegions.isEmpty)
        }

        @Test("replaceSyncedBeacons adds one region per beacon (capped at 9) and requests state for each")
        func replaceSyncedBeaconsAddsAndRequestsState() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = true
            RadarSettings.trackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)

            let manager = TrackingCLLocationManager()
            // 10 beacons — the implementation caps at 9.
            let beacons = (0..<10).map { idx in
                RadarLocationManagerSwiftTestHelpers.makeBeacon(
                    id: "synced\(idx)",
                    uuid: "1111111\(idx)-1111-1111-1111-111111111111",
                    major: "1",
                    minor: "\(idx)"
                )
            }

            RadarLocationManagerSwift.replaceSyncedBeacons(locationManager: manager, beacons: beacons)

            let beaconRegions = manager.trackedRegions.filter { $0.identifier.hasPrefix("radar_beacon_") }
            #expect(beaconRegions.count == 9)
            #expect(manager.requestStateRegions.count == 9)
        }

        @Test("replaceSyncedBeacons skips beacons with an invalid UUID and continues with the rest")
        func replaceSyncedBeaconsSkipsInvalidUUID() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = true
            RadarSettings.trackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)

            let manager = TrackingCLLocationManager()
            let beacons = [
                RadarLocationManagerSwiftTestHelpers.makeBeacon(
                    id: "valid", uuid: "11111111-1111-1111-1111-111111111111", major: "1", minor: "2"
                ),
                RadarLocationManagerSwiftTestHelpers.makeBeacon(
                    id: "broken", uuid: "not-a-uuid", major: "1", minor: "2"
                ),
                RadarLocationManagerSwiftTestHelpers.makeBeacon(
                    id: "alsoValid", uuid: "22222222-2222-2222-2222-222222222222", major: "3", minor: "4"
                ),
            ]

            RadarLocationManagerSwift.replaceSyncedBeacons(locationManager: manager, beacons: beacons)

            let beaconRegions = manager.trackedRegions.filter { $0.identifier.hasPrefix("radar_beacon_") }
            #expect(beaconRegions.count == 2)
            #expect(beaconRegions.contains(where: { $0.identifier == "radar_beacon_valid" }))
            #expect(beaconRegions.contains(where: { $0.identifier == "radar_beacon_alsoValid" }))
        }

        // MARK: - replaceSyncedBeaconUUIDs

        @Test("replaceSyncedBeaconUUIDs no-ops (does not even remove) when useRadarModifiedBeacon is enabled")
        func replaceSyncedBeaconUUIDsNoOpsWhenUseRadarModifiedBeacon() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useRadarModifiedBeacon": true
            ])

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_uuid_existing"])

            RadarLocationManagerSwift.replaceSyncedBeaconUUIDs(
                locationManager: manager,
                uuids: ["11111111-1111-1111-1111-111111111111"]
            )

            #expect(manager.trackedRegions.count == 1)
        }

        @Test("replaceSyncedBeaconUUIDs adds one region per UUID (capped at 9) and requests state for each")
        func replaceSyncedBeaconUUIDsAddsAndCapsAtNine() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = true
            RadarSettings.trackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)

            let manager = TrackingCLLocationManager()
            let uuids = (0..<10).map { "1111111\($0)-1111-1111-1111-111111111111" }

            RadarLocationManagerSwift.replaceSyncedBeaconUUIDs(locationManager: manager, uuids: uuids)

            let uuidRegions = manager.trackedRegions.filter { $0.identifier.hasPrefix("radar_uuid_") }
            #expect(uuidRegions.count == 9)
            #expect(manager.requestStateRegions.count == 9)
        }

        @Test("replaceSyncedBeaconUUIDs skips invalid UUIDs and continues")
        func replaceSyncedBeaconUUIDsSkipsInvalidUUID() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = true
            RadarSettings.trackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)

            let manager = TrackingCLLocationManager()
            let uuids = [
                "11111111-1111-1111-1111-111111111111",
                "not-a-uuid",
                "22222222-2222-2222-2222-222222222222",
            ]

            RadarLocationManagerSwift.replaceSyncedBeaconUUIDs(locationManager: manager, uuids: uuids)

            let uuidRegions = manager.trackedRegions.filter { $0.identifier.hasPrefix("radar_uuid_") }
            #expect(uuidRegions.count == 2)
        }

        @Test("replaceSyncedBeaconUUIDs skips adding when not tracking")
        func replaceSyncedBeaconUUIDsSkipsAddWhenNotTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = false
            RadarSettings.trackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_uuid_existing"])

            RadarLocationManagerSwift.replaceSyncedBeaconUUIDs(
                locationManager: manager,
                uuids: ["11111111-1111-1111-1111-111111111111"]
            )

            // Existing removed, none added.
            #expect(manager.trackedRegions.isEmpty)
        }

        // MARK: - removeSyncedBeacons

        @Test("removeSyncedBeacons removes both radar_beacon_* and radar_uuid_* regions, leaves others")
        func removeSyncedBeaconsRemovesBeaconAndUUIDPrefixes() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let manager = TrackingCLLocationManager()
            manager.seed([
                "radar_beacon_a", "radar_uuid_a",
                "radar_geofence_keep", "radar_bubble_keep", "other_keep",
            ])

            RadarLocationManagerSwift.removeSyncedBeacons(locationManager: manager)

            let remaining = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(remaining == ["other_keep", "radar_bubble_keep", "radar_geofence_keep"])
        }

        @Test("removeSyncedBeacons no-ops when useRadarModifiedBeacon is enabled")
        func removeSyncedBeaconsNoOpsWhenUseRadarModifiedBeacon() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useRadarModifiedBeacon": true
            ])

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_beacon_a", "radar_uuid_a"])

            RadarLocationManagerSwift.removeSyncedBeacons(locationManager: manager)

            #expect(manager.trackedRegions.count == 2)
        }
    }
}
