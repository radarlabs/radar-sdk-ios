//
//  RadarOfflineEventManagerBeaconDwellTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarOfflineEventManagerBeaconDwellTests {

        let testLat = 40.78382
        let testLng = -73.97536
        let testLatFar = 40.78562

        init() {
            Radar.initialize(publishableKey: "prj_test_pk_0000000000000000")
            RadarSyncManager.syncStore.clear()
            RadarSettings.sdkConfiguration = nil
            RadarSettings.trackingOptions = nil
            RadarOfflineEventManager.reset()

            let cachedUser = RadarUser(object: [
                "_id": "test-user",
                "location": ["coordinates": [testLng, testLat]],
            ])
            RadarSyncTestHelper.setRadarUser(cachedUser)
        }

        // MARK: - Helpers

        func makeCircleGeofence(id: String, lat: Double, lng: Double, radius: Double) -> RadarGeofenceSwift {
            let center = RadarCoordinateSwift(latitude: lat, longitude: lng)
            return RadarGeofenceSwift(
                id: id, description: "Test Geofence", tag: "test", externalId: id,
                geometry: .circle(center: center, radius: radius),
                dwellThreshold: nil, geofenceStopDetection: nil, metadata: nil
            )
        }

        func makeBeacon(id: String, lat: Double, lng: Double) -> RadarBeaconSwift {
            return RadarBeaconSwift(
                id: id, description: "Test Beacon", tag: "test", externalId: id,
                uuid: "test-uuid", major: "1", minor: "1",
                geometry: RadarCoordinateSwift(latitude: lat, longitude: lng)
            )
        }

        func setState(_ state: RadarSyncState) {
            RadarSyncManager.syncStore.write(state)
        }

        // MARK: - generateEvents (beacons)

        @Test("generateEvents detects beacon entry")
        func generateEvents_beaconEntry() {
            let beacon = makeBeacon(id: "beacon1", lat: testLat, lng: testLng)
            var state = RadarSyncState()
            state.syncedBeacons = [beacon]
            state.lastSyncedBeaconIds = []
            setState(state)

            let options = RadarTrackingOptions.presetResponsive
            options.beacons = true
            RadarSettings.trackingOptions = options

            let location = CLLocation(latitude: testLat, longitude: testLng)

            var resultUser: RadarUser?
            RadarOfflineEventManager.generateEvents(location: location) { _, user, _ in
                resultUser = user
            }

            // Synthetic user reflects the beacon now in range
            // proves the entry path ran and beacon dictionary was built correctly
            #expect(resultUser?.beacons?.count == 1)
            #expect(resultUser?.beacons?.first?._id == "beacon1")
        }

        @Test("generateEvents detects beacon exit")
        func generateEvents_beaconExit() {
            let beacon = makeBeacon(id: "beacon1", lat: testLatFar, lng: testLng)
            var state = RadarSyncState()
            state.syncedBeacons = [beacon]
            state.lastSyncedBeaconIds = ["beacon1"]
            setState(state)

            let options = RadarTrackingOptions.presetResponsive
            options.beacons = true
            RadarSettings.trackingOptions = options

            let location = CLLocation(latitude: testLat, longitude: testLng)

            var resultUser: RadarUser?
            RadarOfflineEventManager.generateEvents(location: location) { _, user, _ in
                resultUser = user
            }

            // User is out of beacon range now. Synthetic user should have no beacons.
            #expect(resultUser?.beacons?.count == 0)
        }

        @Test("generateEvents returns empty when no beacon state change")
        func generateEvents_beaconNoChange() {
            let beacon = makeBeacon(id: "beacon1", lat: testLat, lng: testLng)
            var state = RadarSyncState()
            state.syncedBeacons = [beacon]
            state.lastSyncedBeaconIds = ["beacon1"]
            setState(state)

            let options = RadarTrackingOptions.presetResponsive
            options.beacons = true
            RadarSettings.trackingOptions = options

            let location = CLLocation(latitude: testLat, longitude: testLng)

            var resultEvents: [RadarEvent] = []
            RadarOfflineEventManager.generateEvents(location: location) { events, _, _ in
                resultEvents = events
            }

            #expect(resultEvents.isEmpty)
        }

        // MARK: - generateEvents (dwell)

        @Test("generateEvents fires dwell when threshold reached")
        func generateEvents_dwellThresholdReached() {
            let geofence = makeCircleGeofence(id: "geo1", lat: testLat, lng: testLng, radius: 100)
            var state = RadarSyncState()
            state.syncedGeofences = [geofence]
            state.lastSyncedGeofenceIds = ["geo1"]
            state.geofenceEntryTimestamps = ["geo1": Date(timeIntervalSinceNow: -600).timeIntervalSince1970]
            setState(state)

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["defaultGeofenceDwellThreshold": 5])

            let location = CLLocation(latitude: testLat, longitude: testLng)
            RadarOfflineEventManager.generateEvents(location: location) { _, _, _ in }

            let updatedState = RadarSyncManager.syncStore.read()
            #expect(updatedState?.dwellEventsFired.contains("geo1") == true)
        }

        @Test("generateEvents does not fire dwell when threshold not reached")
        func generateEvents_dwellThresholdNotReached() {
            let geofence = makeCircleGeofence(id: "geo1", lat: testLat, lng: testLng, radius: 100)
            var state = RadarSyncState()
            state.syncedGeofences = [geofence]
            state.lastSyncedGeofenceIds = ["geo1"]
            state.geofenceEntryTimestamps = ["geo1": Date(timeIntervalSinceNow: -60).timeIntervalSince1970]
            setState(state)

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["defaultGeofenceDwellThreshold": 5])

            let location = CLLocation(latitude: testLat, longitude: testLng)
            RadarOfflineEventManager.generateEvents(location: location) { _, _, _ in }

            let updatedState = RadarSyncManager.syncStore.read()
            #expect(updatedState?.dwellEventsFired.isEmpty == true)
        }

        @Test("generateEvents does not re-fire dwell when already fired")
        func generateEvents_dwellAlreadyFired() {
            let geofence = makeCircleGeofence(id: "geo1", lat: testLat, lng: testLng, radius: 100)
            var state = RadarSyncState()
            state.syncedGeofences = [geofence]
            state.lastSyncedGeofenceIds = ["geo1"]
            state.geofenceEntryTimestamps = ["geo1": Date(timeIntervalSinceNow: -600).timeIntervalSince1970]
            state.dwellEventsFired = ["geo1"]
            setState(state)

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["defaultGeofenceDwellThreshold": 5])

            let location = CLLocation(latitude: testLat, longitude: testLng)
            RadarOfflineEventManager.generateEvents(location: location) { _, _, _ in }

            let updatedState = RadarSyncManager.syncStore.read()
            #expect(updatedState?.dwellEventsFired == ["geo1"])
        }

        @Test("generateEvents records entry timestamp on geofence entry")
        func generateEvents_entry_recordsTimestamp() {
            let geofence = makeCircleGeofence(id: "geo1", lat: testLat, lng: testLng, radius: 100)
            var state = RadarSyncState()
            state.syncedGeofences = [geofence]
            state.lastSyncedGeofenceIds = []
            setState(state)

            let location = CLLocation(latitude: testLat, longitude: testLng)
            RadarOfflineEventManager.generateEvents(location: location) { _, _, _ in }

            let updatedState = RadarSyncManager.syncStore.read()
            #expect(updatedState?.geofenceEntryTimestamps["geo1"] != nil)
        }

        @Test("generateEvents clears entry timestamp on geofence exit")
        func generateEvents_exit_clearsTimestamp() {
            let geofence = makeCircleGeofence(id: "geo1", lat: testLatFar, lng: testLng, radius: 50)
            var state = RadarSyncState()
            state.syncedGeofences = [geofence]
            state.lastSyncedGeofenceIds = ["geo1"]
            state.geofenceEntryTimestamps = ["geo1": Date().timeIntervalSince1970]
            state.dwellEventsFired = ["geo1"]
            setState(state)

            let location = CLLocation(latitude: testLat, longitude: testLng)
            RadarOfflineEventManager.generateEvents(location: location) { _, _, _ in }

            let updatedState = RadarSyncManager.syncStore.read()
            #expect(updatedState?.geofenceEntryTimestamps["geo1"] == nil)
            #expect(updatedState?.dwellEventsFired.contains("geo1") == false)
        }
    }
}
