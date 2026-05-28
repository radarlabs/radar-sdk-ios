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

        // MARK: - replaceSyncedBeacons

        @Test("replaceSyncedBeacons no-ops when useRadarModifiedBeacon is enabled")
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

            // Short-circuit before remove or add, so existing region is preserved untouched.
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

        @Test("Public replaceSyncedBeacons routes to Swift twin when flag enabled")
        func publicReplaceSyncedBeaconsRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useSwiftLocationManager": true,
                "useRadarModifiedBeacon": true
            ])

            RadarLocationManager.sharedInstance().replaceSyncedBeacons([])
        }

        // MARK: - replaceSyncedBeaconUUIDs

        @Test("replaceSyncedBeaconUUIDs no-ops when useRadarModifiedBeacon is enabled")
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

        @Test("replaceSyncedBeaconUUIDs adds one region per UUID (capped at 9)")
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
                "22222222-2222-2222-2222-222222222222"
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

        // MARK: - requestLocation / shutDown

        @Test("requestLocation forwards to the underlying location manager")
        func requestLocationForwards() {
            let manager = TrackingCLLocationManager()

            RadarLocationManagerSwift.requestLocation(locationManager: manager)

            #expect(manager.requestLocationCallCount == 1)
        }

        @Test("shutDown stops updates on both the location manager and the low-power location manager")
        func shutDownStopsUpdatesOnBothManagers() {
            let manager = TrackingCLLocationManager()
            let lowPowerManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.shutDown(
                locationManager: manager,
                lowPowerLocationManager: lowPowerManager
            )

            #expect(manager.stopUpdatingLocationCallCount == 1)
            #expect(lowPowerManager.stopUpdatingLocationCallCount == 1)
        }
    }
}
