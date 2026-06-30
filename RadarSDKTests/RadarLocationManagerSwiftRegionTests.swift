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

        @Test("replaceBubbleGeofence removes existing bubbles but skips adding when tracking is false")
        func replaceBubbleGeofenceSkipsAddWhenNotTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = false

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_bubble_old", "radar_geofence_keep"])

            RadarLocationManagerSwift.replaceBubbleGeofence(
                locationManager: manager,
                location: CLLocation(latitude: 40.7, longitude: -74.0),
                radius: 100
            )

            // Old bubble removed, nothing added, non-bubble region preserved.
            let remaining = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(remaining == ["radar_geofence_keep"])
        }

        @Test("replaceBubbleGeofence replaces old bubble with exactly one new bubble region when tracking")
        func replaceBubbleGeofenceAddsOneWhenTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = true

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_bubble_old", "radar_geofence_keep"])

            RadarLocationManagerSwift.replaceBubbleGeofence(
                locationManager: manager,
                location: CLLocation(latitude: 40.7, longitude: -74.0),
                radius: 250
            )

            let bubbleRegions = manager.trackedRegions.filter { $0.identifier.hasPrefix("radar_bubble_") }
            // Exactly one bubble, and it is not the seeded one.
            #expect(bubbleRegions.count == 1)
            #expect(!bubbleRegions.contains { $0.identifier == "radar_bubble_old" })
            // Non-bubble region untouched.
            #expect(manager.trackedRegions.contains { $0.identifier == "radar_geofence_keep" })

            // New region carries the requested center and radius.
            let circular = bubbleRegions.first as? CLCircularRegion
            #expect(circular?.radius == 250)
            #expect(circular?.center.latitude == 40.7)
            #expect(circular?.center.longitude == -74.0)
        }

        // MARK: - removeBubbleGeofence

        @Test("removeBubbleGeofence removes only radar_bubble_* regions, leaves others")
        func removeBubbleGeofenceRemovesOnlyBubblePrefix() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let manager = TrackingCLLocationManager()
            manager.seed([
                "radar_bubble_a", "radar_bubble_b",
                "radar_geofence_keep", "radar_beacon_keep", "other_keep",
            ])

            RadarLocationManagerSwift.removeBubbleGeofence(locationManager: manager)

            let remaining = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(remaining == ["other_keep", "radar_beacon_keep", "radar_geofence_keep"])
        }

        // MARK: - replaceSyncedGeofences

        @Test("replaceSyncedGeofences with nil leaves existing regions untouched")
        func replaceSyncedGeofencesNilSkips() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_geofence_keep", "other_keep"])

            RadarLocationManagerSwift.replaceSyncedGeofences(locationManager: manager, geofences: nil)

            // nil returns before removeSyncedGeofences, so nothing is removed or added.
            let remaining = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(remaining == ["other_keep", "radar_geofence_keep"])
        }

        @Test("replaceSyncedGeofences adds one region per geofence with its center and radius")
        func replaceSyncedGeofencesAddsRegions() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let manager = TrackingCLLocationManager()
            RadarLocationManagerSwift.replaceSyncedGeofences(
                locationManager: manager,
                geofences: [
                    RadarLocationManagerSwiftTestHelpers.makeGeofence(id: "a", latitude: 1, longitude: 2, radius: 50),
                    RadarLocationManagerSwiftTestHelpers.makeGeofence(id: "b", latitude: 3, longitude: 4, radius: 75),
                ]
            )

            let identifiers = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(identifiers == ["radar_geofence_a", "radar_geofence_b"])

            let regionA = manager.trackedRegions.first { $0.identifier == "radar_geofence_a" } as? CLCircularRegion
            #expect(regionA?.radius == 50)
            #expect(regionA?.center.latitude == 1)
            #expect(regionA?.center.longitude == 2)
        }

        @Test("replaceSyncedGeofences removes existing synced geofences but keeps other regions")
        func replaceSyncedGeofencesRemovesOldFirst() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let manager = TrackingCLLocationManager()
            manager.seed(["radar_geofence_old", "radar_bubble_keep", "radar_beacon_keep", "other_keep"])

            RadarLocationManagerSwift.replaceSyncedGeofences(
                locationManager: manager,
                geofences: [RadarLocationManagerSwiftTestHelpers.makeGeofence(id: "new")]
            )

            let remaining = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(remaining == ["other_keep", "radar_beacon_keep", "radar_bubble_keep", "radar_geofence_new"])
        }

        @Test("replaceSyncedGeofences caps at 19 regions when beacons are off")
        func replaceSyncedGeofencesCapsAt19() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.trackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: false)

            let manager = TrackingCLLocationManager()
            let geofences = (0..<25).map { RadarLocationManagerSwiftTestHelpers.makeGeofence(id: "g\($0)") }

            RadarLocationManagerSwift.replaceSyncedGeofences(locationManager: manager, geofences: geofences)

            #expect(manager.trackedRegions.count == 19)
        }

        @Test("replaceSyncedGeofences caps at 9 regions when beacons are on")
        func replaceSyncedGeofencesCapsAt9() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.trackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)

            let manager = TrackingCLLocationManager()
            let geofences = (0..<25).map { RadarLocationManagerSwiftTestHelpers.makeGeofence(id: "g\($0)") }

            RadarLocationManagerSwift.replaceSyncedGeofences(locationManager: manager, geofences: geofences)

            #expect(manager.trackedRegions.count == 9)
        }

        @Test("replaceSyncedGeofences reads center and radius from polygon geometry")
        func replaceSyncedGeofencesPolygonGeometry() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let manager = TrackingCLLocationManager()
            RadarLocationManagerSwift.replaceSyncedGeofences(
                locationManager: manager,
                geofences: [
                    RadarLocationManagerSwiftTestHelpers.makePolygonGeofence(id: "poly", latitude: 5, longitude: 6, radius: 200)
                ]
            )

            let region = manager.trackedRegions.first { $0.identifier == "radar_geofence_poly" } as? CLCircularRegion
            #expect(region?.radius == 200)
            #expect(region?.center.latitude == 5)
            #expect(region?.center.longitude == 6)
        }

        // MARK: - removeSyncedGeofences

        @Test("removeSyncedGeofences removes only radar_geofence_* regions, leaves others")
        func removeSyncedGeofencesRemovesOnlyGeofencePrefix() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let manager = TrackingCLLocationManager()
            manager.seed([
                "radar_geofence_a", "radar_geofence_b",
                "radar_bubble_keep", "radar_beacon_keep", "radar_uuid_keep", "other_keep",
            ])

            RadarLocationManagerSwift.removeSyncedGeofences(locationManager: manager)

            let remaining = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(remaining == ["other_keep", "radar_beacon_keep", "radar_bubble_keep", "radar_uuid_keep"])
        }

        // MARK: - removeAllRegions

        @Test("removeAllRegions removes every radar_* region, leaves non-radar regions")
        func removeAllRegionsRemovesEveryRadarPrefix() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let manager = TrackingCLLocationManager()
            manager.seed([
                "radar_bubble_a", "radar_geofence_b", "radar_beacon_c", "radar_uuid_d",
                "other_keep", "notradar_keep",
            ])

            RadarLocationManagerSwift.removeAllRegions(locationManager: manager)

            let remaining = manager.trackedRegions.map { $0.identifier }.sorted()
            #expect(remaining == ["notradar_keep", "other_keep"])
        }
    }
}
