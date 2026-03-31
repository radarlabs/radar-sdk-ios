//
//  RadarSyncManagerTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 3/19/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
@testable import RadarSDK

@Suite(.serialized)
struct RadarSyncManagerTests {
    
    let testLat = 40.78382
    let testLng = -73.97536
    let testLatNearby = 40.78427
    let testLatFar = 40.78562

    init() {
        Radar.initialize(publishableKey: "prj_test_pk_0000000000000000")
        RadarSyncManager.syncStore.clear()
        RadarSettings.setSdkConfiguration(nil)
    }
    
    // MARK: - Helpers
    
    func makeCircleGeofence(id: String, lat: Double, lng: Double, radius: Double,
                            dwellThreshold: Double? = nil, stopDetection: Bool? = nil) -> RadarGeofenceSwift {
        let center = RadarCoordinateSwift(latitude: lat, longitude: lng)
        
        return RadarGeofenceSwift(
            id: id, description: "Test Geofence", tag: "test", externalId: id,
            geometry: .circle(center: center, radius: radius),
            dwellThreshold: dwellThreshold, geofenceStopDetection: stopDetection
        )
    }
    
    func makePolygonGeofence(id: String, coords: [RadarCoordinateSwift],
                             center: RadarCoordinateSwift, radius: Double) -> RadarGeofenceSwift {
        
        return RadarGeofenceSwift(
            id: id, description: "Test Polygon", tag: "test", externalId: id,
            geometry: .polygon(coordinates: coords, center: center, radius: radius),
            dwellThreshold: nil, geofenceStopDetection: nil
        )
    }
    
    func makeBeacon(id: String, lat: Double, lng: Double) -> RadarBeaconSwift {
        
        return RadarBeaconSwift(
            id: id, description: "Test Beacon", tag: "test", externalId: id,
            uuid: "test-uuid", major: "1", minor: "1",
            geometry: RadarCoordinateSwift(latitude: lat, longitude: lng)
        )
    }
    
    func makePlace(id: String, lat: Double, lng: Double) -> RadarPlaceSwift {
        
        return RadarPlaceSwift(
            id: id, name: "Test Place", categories: ["test"],
            location: RadarCoordinateSwift(latitude: lat, longitude: lng), group: "test"
        )
    }
    
    func setState(_ state: RadarSyncState) {
        RadarSyncManager.syncStore.write(state)
    }
    
    // MARK: - shouldTrack
    
    @Test("shouldTrack returns true when no synced region")
    func shouldTrack_noSyncedRegion() {
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let options = RadarTrackingOptions()
        options.syncLocations = .events
        
        #expect(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    @Test("shouldTrack returns true when outside synced region")
    func shouldTrack_outsideSyncedRegion() {
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 100
        setState(state)
        
        let location = CLLocation(latitude: testLatFar, longitude: testLng)
        let options = RadarTrackingOptions()
        options.syncLocations = .events
        
        #expect(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    @Test("shouldTrack returns true on geofence entry")
    func shouldTrack_geofenceEntry() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 500
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let options = RadarTrackingOptions()
        options.syncLocations = .events
        
        #expect(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    @Test("shouldTrack returns true on geofence exit")
    func shouldTrack_geofenceExit() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLatFar, lng: testLng, radius: 50)
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 500
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let options = RadarTrackingOptions()
        options.syncLocations = .events
        
        #expect(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    @Test("shouldTrack returns false when no state change")
    func shouldNotTrack_noStateChange() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 500
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date().timeIntervalSince1970]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let options = RadarTrackingOptions()
        options.syncLocations = .events
        
        #expect(!RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    // MARK: - getGeofences
    
    @Test("getGeofences returns geofence when inside circle")
    func getGeofences_insideCircle() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        
        #expect(geofences.count == 1)
        #expect(geofences.first?.id == "geofence1")
    }
    
    @Test("getGeofences returns empty when outside circle")
    func getGeofences_outsideCircle() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLatFar, lng: testLng, radius: 50)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        
        #expect(geofences.count == 0)
    }
    
    @Test("getGeofences returns empty when no nearby geofences")
    func getGeofences_noNearbyGeofences() {
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        
        #expect(geofences.count == 0)
    }
    
    // MARK: - geofenceStateChanged
    
    @Test("geofenceStateChanged detects entry")
    func geofenceStateChanged_entry() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    @Test("geofenceStateChanged detects exit")
    func geofenceStateChanged_exit() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLatFar, lng: testLng, radius: 50)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date().timeIntervalSince1970]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }

    @Test("geofenceStateChanged returns false when no change")
    func geofenceStateChanged_noChange() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date().timeIntervalSince1970]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(!RadarSyncManager.hasGeofenceStateChanged(location: location))
    }

    // MARK: - getBeacons
    
    @Test("getBeacons returns beacon when within range")
    func getBeacons_withinRange() {
        let beacon = makeBeacon(id: "beacon1", lat: testLat, lng: testLng)
        var state = RadarSyncState()
        state.syncedBeacons = [beacon]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let beacons = RadarSyncManager.getBeacons(for: location)
        
        #expect(beacons.count == 1)
        #expect(beacons.first?.id == "beacon1")
    }
    
    @Test("getBeacons returns empty when outside range")
    func getBeacons_outsideRange() {
        let beacon = makeBeacon(id: "beacon1", lat: testLatFar, lng: testLng)
        var state = RadarSyncState()
        state.syncedBeacons = [beacon]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let beacons = RadarSyncManager.getBeacons(for: location)
        
        #expect(beacons.count == 0)
    }
    
    // MARK: - beaconStateChanged
    
    @Test("beaconStateChanged detects entry")
    func beaconStateChanged_entry() {
        let beacon = makeBeacon(id: "beacon1", lat: testLat, lng: testLng)
        var state = RadarSyncState()
        state.syncedBeacons = [beacon]
        state.lastSyncedBeaconIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.hasBeaconStateChanged(location: location))
    }
    
    @Test("beaconStateChanged detects exit")
    func beaconStateChanged_exit() {
        let beacon = makeBeacon(id: "beacon1", lat: testLatFar, lng: testLng)
        var state = RadarSyncState()
        state.syncedBeacons = [beacon]
        state.lastSyncedBeaconIds = ["beacon1"]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.hasBeaconStateChanged(location: location))
    }
    
    // MARK: - getPlaces
    
    @Test("getPlaces returns place when within radius")
    func getPlaces_withinRadius() {
        let place = makePlace(id: "place1", lat: testLat, lng: testLng)
        var state = RadarSyncState()
        state.syncedPlaces = [place]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let places = RadarSyncManager.getPlaces(for: location)
        
        #expect(places.count == 1)
        #expect(places.first?.id == "place1")
    }
    
    @Test("getPlaces returns empty when outside radius")
    func getPlaces_outsideRadius() {
        let place = makePlace(id: "place1", lat: testLatFar, lng: testLng)
        var state = RadarSyncState()
        state.syncedPlaces = [place]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let places = RadarSyncManager.getPlaces(for: location)
        
        #expect(places.count == 0)
    }

    // MARK: - placeStateChanged
    
    @Test("placeStateChanged detects entry")
    func placeStateChanged_entry() {
        let place = makePlace(id: "place1", lat: testLat, lng: testLng)
        var state = RadarSyncState()
        state.syncedPlaces = [place]
        state.lastSyncedPlaceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.hasPlaceStateChanged(location: location))
    }
    
    @Test("placeStateChanged detects exit")
    func placeStateChanged_exit() {
        let place = makePlace(id: "place1", lat: testLatFar, lng: testLng)
        var state = RadarSyncState()
        state.syncedPlaces = [place]
        state.lastSyncedPlaceIds = ["place1"]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.hasPlaceStateChanged(location: location))
    }
    
    // MARK: - isOutsideSyncedRegion
    
    @Test("isOutsideSyncedRegion returns true when no region")
    func isOutsideSyncedRegion_nil() {
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.isOutsideSyncedRegion(location: location))
    }
    
    @Test("isOutsideSyncedRegion returns false when inside")
    func isOutsideSyncedRegion_inside() {
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 100
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(!RadarSyncManager.isOutsideSyncedRegion(location: location))
    }
    
    @Test("isOutsideSyncedRegion returns true when outside")
    func isOutsideSyncedRegion_outside() {
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 100
        setState(state)
        
        let location = CLLocation(latitude: testLatFar, longitude: testLng)
        #expect(RadarSyncManager.isOutsideSyncedRegion(location: location))
    }
    
    // MARK: - isPointInsideCircle
    
    @Test("isPointInsideCircle returns true when inside")
    func isPointInsideCircle_inside() {
        let point = CLLocation(latitude: testLat, longitude: testLng)
        let center = CLLocationCoordinate2D(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.isPoint(point, insideCircleWithCenter: center, radius: 100))
    }
    
    @Test("isPointInsideCircle returns false when outside")
    func isPointInsideCircle_outside() {
        let point = CLLocation(latitude: testLatFar, longitude: testLng)
        let center = CLLocationCoordinate2D(latitude: testLat, longitude: testLng)
        #expect(!RadarSyncManager.isPoint(point, insideCircleWithCenter: center, radius: 100))
    }
    
    // MARK: - Multiple geofences
    
    @Test("shouldTrack with multiple geofences when crossing nearest boundary")
    func multipleGeofences_shouldTrackWhenCrossingNearestBoundary() {
        let geofenceA = makeCircleGeofence(id: "geofenceA", lat: testLatNearby, lng: testLng, radius: 100)
        let geofenceB = makeCircleGeofence(id: "geofenceB", lat: testLatFar, lng: testLng, radius: 50)
        var state = RadarSyncState()
        state.syncedGeofences = [geofenceA, geofenceB]
        state.lastSyncedGeofenceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLatNearby, longitude: testLng)
        let options = RadarTrackingOptions()
        options.syncLocations = .events
        
        #expect(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    @Test("detects correct geofences from multiple")
    func multipleGeofences_detectsCorrectGeofences() {
        let geofenceA = makeCircleGeofence(id: "geofenceA", lat: testLat, lng: testLng, radius: 100)
        let geofenceB = makeCircleGeofence(id: "geofenceB", lat: testLatNearby, lng: testLng, radius: 100)
        let geofenceC = makeCircleGeofence(id: "geofenceC", lat: testLatFar, lng: testLng, radius: 50)
        var state = RadarSyncState()
        state.syncedGeofences = [geofenceA, geofenceB, geofenceC]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        #expect(geofences.count == 2)
        
        let ids = Set(geofences.map { $0.id })
        #expect(ids.contains("geofenceA"))
        #expect(ids.contains("geofenceB"))
        #expect(!ids.contains("geofenceC"))
    }
    
    // MARK: - Polygon geofences
    
    @Test("getGeofences returns geofence when inside polygon")
    func getGeofences_insidePolygon() {
        let coords = [
            RadarCoordinateSwift(latitude: testLat + 0.001, longitude: testLng - 0.001),
            RadarCoordinateSwift(latitude: testLat + 0.001, longitude: testLng + 0.001),
            RadarCoordinateSwift(latitude: testLat - 0.001, longitude: testLng + 0.001),
            RadarCoordinateSwift(latitude: testLat - 0.001, longitude: testLng - 0.001),
            RadarCoordinateSwift(latitude: testLat + 0.001, longitude: testLng - 0.001),
        ]
        let center = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        let geofence = makePolygonGeofence(id: "poly1", coords: coords, center: center, radius: 150)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        
        #expect(geofences.count == 1)
        #expect(geofences.first?.id == "poly1")
    }
    
    @Test("getGeofences returns empty when outside polygon")
    func getGeofences_outsidePolygon() {
        let coords = [
            RadarCoordinateSwift(latitude: testLatFar + 0.001, longitude: testLng - 0.001),
            RadarCoordinateSwift(latitude: testLatFar + 0.001, longitude: testLng + 0.001),
            RadarCoordinateSwift(latitude: testLatFar - 0.001, longitude: testLng + 0.001),
            RadarCoordinateSwift(latitude: testLatFar - 0.001, longitude: testLng - 0.001),
            RadarCoordinateSwift(latitude: testLatFar + 0.001, longitude: testLng - 0.001),
        ]
        let center = RadarCoordinateSwift(latitude: testLatFar, longitude: testLng)
        let geofence = makePolygonGeofence(id: "poly1", coords: coords, center: center, radius: 150)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        
        #expect(geofences.count == 0)
    }
    
    @Test("getGeofences handles mixed circle and polygon")
    func getGeofences_mixedCircleAndPolygon() {
        let circleGeofence = makeCircleGeofence(id: "circle1", lat: testLat, lng: testLng, radius: 100)
        let coords = [
            RadarCoordinateSwift(latitude: testLat + 0.001, longitude: testLng - 0.001),
            RadarCoordinateSwift(latitude: testLat + 0.001, longitude: testLng + 0.001),
            RadarCoordinateSwift(latitude: testLat - 0.001, longitude: testLng + 0.001),
            RadarCoordinateSwift(latitude: testLat - 0.001, longitude: testLng - 0.001),
            RadarCoordinateSwift(latitude: testLat + 0.001, longitude: testLng - 0.001),
        ]
        let center = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        let polyGeofence = makePolygonGeofence(id: "poly1", coords: coords, center: center, radius: 150)
        var state = RadarSyncState()
        state.syncedGeofences = [circleGeofence, polyGeofence]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        #expect(geofences.count == 2)
        
        let ids = Set(geofences.map { $0.id })
        #expect(ids.contains("circle1"))
        #expect(ids.contains("poly1"))
    }
    
    // MARK: - Buffered entry
    
    @Test("getGeofences includes buffered entry when enabled")
    func getGeofences_bufferedEntry() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        setState(state)
        
        let config = RadarSdkConfiguration(dict: ["bufferGeofenceEntries": true])
        RadarSettings.setSdkConfiguration(config)
        
        let offsetLat = testLat + 0.001
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: offsetLat, longitude: testLng),
            altitude: 0, horizontalAccuracy: 20, verticalAccuracy: 10, timestamp: Date()
        )
        let geofences = RadarSyncManager.getGeofences(for: location)
        #expect(geofences.count == 1)
    }
    
    @Test("getGeofences excludes buffered entry when disabled")
    func getGeofences_bufferingDisabled() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        setState(state)
        
        let config = RadarSdkConfiguration(dict: ["bufferGeofenceEntries": false])
        RadarSettings.setSdkConfiguration(config)
        
        let offsetLat = testLat + 0.001
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: offsetLat, longitude: testLng),
            altitude: 0, horizontalAccuracy: 20, verticalAccuracy: 10, timestamp: Date()
        )
        let geofences = RadarSyncManager.getGeofences(for: location)
        #expect(geofences.count == 0)
    }
    
    // MARK: - Stop detection
    
    @Test("stop detection blocks geofence entry when not stopped")
    func geofenceEntry_stopDetectionBlocks() {
        RadarState.setStopped(false)
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100, stopDetection: true)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(!RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    @Test("stop detection allows geofence entry when stopped")
    func geofenceEntry_stopDetectionAllows() {
        RadarState.setStopped(true)
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100, stopDetection: true)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    // MARK: - Dwell
    
    @Test("dwell threshold reached triggers state change")
    func geofenceDwell_thresholdReached() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date(timeIntervalSinceNow: -600).timeIntervalSince1970]
        setState(state)
        
        let config = RadarSdkConfiguration(dict: ["defaultGeofenceDwellThreshold": 5])
        RadarSettings.setSdkConfiguration(config)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    @Test("dwell threshold not reached does not trigger state change")
    func geofenceDwell_thresholdNotReached() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date(timeIntervalSinceNow: -60).timeIntervalSince1970]
        setState(state)
        
        let config = RadarSdkConfiguration(dict: ["defaultGeofenceDwellThreshold": 5])
        RadarSettings.setSdkConfiguration(config)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(!RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    @Test("per-geofence dwell threshold override")
    func geofenceDwell_perGeofenceOverride() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100, dwellThreshold: 2)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date(timeIntervalSinceNow: -180).timeIntervalSince1970]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    @Test("dwell event already fired does not trigger again")
    func geofenceDwell_alreadyFired() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date(timeIntervalSinceNow: -600).timeIntervalSince1970]
        state.dwellEventsFired = ["geofence1"]
        setState(state)
        
        let config = RadarSdkConfiguration(dict: ["defaultGeofenceDwellThreshold": 5])
        RadarSettings.setSdkConfiguration(config)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(!RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    // MARK: - isNearSyncedRegionBoundary
    
    @Test("isNearSyncedRegionBoundary returns true when near boundary")
    func isNearSyncedRegionBoundary_near() {
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 1000
        setState(state)
        
        let location = CLLocation(latitude: testLat + 0.0081, longitude: testLng)
        #expect(RadarSyncManager.isNearSyncedRegionBoundary(location: location))
    }
    
    @Test("isNearSyncedRegionBoundary returns false when not near boundary")
    func isNearSyncedRegionBoundary_notNear() {
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 1000
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        #expect(!RadarSyncManager.isNearSyncedRegionBoundary(location: location))
    }
}
