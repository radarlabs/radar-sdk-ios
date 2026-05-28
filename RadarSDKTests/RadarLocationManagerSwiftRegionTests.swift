//
//  RadarLocationManagerSwiftRegionTests.swift
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
    actor RadarLocationManagerSwiftRegionTests {

        // MARK: - replaceBubbleGeofence

        @Test("replaceBubbleGeofence adds a radar_bubble_* region when tracking is true")
        func replaceBubbleGeofenceAddsRegionWhenTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = true

            let manager = TrackingCLLocationManager()
            let location = CLLocation(latitude: 40.0, longitude: -74.0)

            RadarLocationManagerSwift.replaceBubbleGeofence(locationManager: manager, location: location, radius: 250)

            #expect(manager.trackedRegions.count == 1)
            let region = manager.trackedRegions.first
            #expect(region?.identifier.hasPrefix("radar_bubble_") == true)
            if let circle = region as? CLCircularRegion {
                #expect(circle.radius == 250)
                #expect(abs(circle.center.latitude - 40.0) < 0.0001)
                #expect(abs(circle.center.longitude - -74.0) < 0.0001)
            } else {
                Issue.record("Expected CLCircularRegion")
            }
        }

        @Test("replaceBubbleGeofence removes existing bubble but does not add a new one when not tracking")
        func replaceBubbleGeofenceRemovesButDoesNotAddWhenNotTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = false

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_bubble_existing", "radar_geofence_keep"])

            RadarLocationManagerSwift.replaceBubbleGeofence(
                locationManager: manager,
                location: CLLocation(latitude: 0, longitude: 0),
                radius: 100
            )

            // Existing bubble removed, no new bubble added, unrelated region preserved.
            #expect(!manager.trackedRegions.contains(where: { $0.identifier.hasPrefix("radar_bubble_") }))
            #expect(manager.trackedRegions.contains(where: { $0.identifier == "radar_geofence_keep" }))
        }

        @Test("replaceBubbleGeofence removes prior bubble before adding a new one")
        func replaceBubbleGeofenceReplacesPriorBubble() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = true

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_bubble_old"])

            RadarLocationManagerSwift.replaceBubbleGeofence(
                locationManager: manager,
                location: CLLocation(latitude: 1, longitude: 1),
                radius: 100
            )

            let bubbles = manager.trackedRegions.filter { $0.identifier.hasPrefix("radar_bubble_") }
            #expect(bubbles.count == 1)
            #expect(bubbles.first?.identifier != "radar_bubble_old")
        }

        // MARK: - Region removal

        @Test("removeBubbleGeofence removes only radar_bubble_* regions")
        func removeBubbleGeofenceRemovesOnlyBubblePrefix() {
            let manager = TrackingCLLocationManager()
            manager.seed([
                "radar_bubble_a", "radar_bubble_b",
                "radar_geofence_keep", "radar_beacon_keep", "radar_uuid_keep", "other_keep"
            ])

            RadarLocationManagerSwift.removeBubbleGeofence(locationManager: manager)

            let remaining = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(remaining == ["other_keep", "radar_beacon_keep", "radar_geofence_keep", "radar_uuid_keep"])
        }

        @Test("removeSyncedGeofences removes only radar_geofence_* regions")
        func removeSyncedGeofencesRemovesOnlyGeofencePrefix() {
            let manager = TrackingCLLocationManager()
            manager.seed([
                "radar_geofence_a", "radar_geofence_b",
                "radar_bubble_keep", "radar_beacon_keep", "radar_uuid_keep"
            ])

            RadarLocationManagerSwift.removeSyncedGeofences(locationManager: manager)

            #expect(!manager.trackedRegions.contains(where: { $0.identifier.hasPrefix("radar_geofence_") }))
            #expect(manager.trackedRegions.count == 3)
        }

        @Test("removeSyncedBeacons removes both radar_beacon_* and radar_uuid_* regions")
        func removeSyncedBeaconsRemovesBeaconAndUUIDPrefixes() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let manager = TrackingCLLocationManager()
            manager.seed([
                "radar_beacon_a", "radar_uuid_a",
                "radar_geofence_keep", "radar_bubble_keep"
            ])

            RadarLocationManagerSwift.removeSyncedBeacons(locationManager: manager)

            let remaining = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(remaining == ["radar_bubble_keep", "radar_geofence_keep"])
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

        @Test("removeAllRegions removes anything with the radar_ prefix")
        func removeAllRegionsRemovesEverythingPrefixedRadar() {
            let manager = TrackingCLLocationManager()
            manager.seed([
                "radar_bubble_a", "radar_geofence_a", "radar_beacon_a", "radar_uuid_a",
                "other_keep_1", "other_keep_2"
            ])

            RadarLocationManagerSwift.removeAllRegions(locationManager: manager)

            let remaining = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(remaining == ["other_keep_1", "other_keep_2"])
        }
    }
}
