//
//  RadarSyncManagerTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 3/19/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import XCTest
@testable import RadarSDK

class RadarSyncManagerTests: XCTestCase {
    
    let testLat = 40.78382
    let testLng = -73.97536
    let testLatNearby = 40.78427
    let testLatFar = 40.78562

    override func setUp() {
        super.setUp()
        Radar.initialize(publishableKey: "prj_test_pk_0000000000000000")
        RadarSyncManager.syncStore.clear()
    }
    
    override func tearDown() {
        RadarSyncManager.syncStore.clear()
        RadarSettings.setSdkConfiguration(nil)
        super.tearDown()
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
    
    func test_shouldTrack_noSyncedRegion() {
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let options = RadarTrackingOptions()
        options.syncLocations = .events
        
        XCTAssertTrue(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    func test_shouldTrack_outsideSyncedRegion() {
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 100
        setState(state)
        
        let location = CLLocation(latitude: testLatFar, longitude: testLng)
        let options = RadarTrackingOptions()
        options.syncLocations = .events
        
        XCTAssertTrue(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    func test_shouldTrack_geofenceEntry() {
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
        
        XCTAssertTrue(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    func test_shouldTrack_geofenceExit() {
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
        
        XCTAssertTrue(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    func test_shouldNotTrack_noStateChange() {
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
        
        XCTAssertFalse(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    // MARK: - getGeofences
    
    func test_getGeofences_insideCircle() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        
        XCTAssertEqual(geofences.count, 1)
        XCTAssertEqual(geofences.first?.id, "geofence1")
    }
    
    func test_getGeofences_outsideCircle() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLatFar, lng: testLng, radius: 50)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        
        XCTAssertEqual(geofences.count, 0)
    }
    
    func test_getGeofences_noNearbyGeofences() {
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        
        XCTAssertEqual(geofences.count, 0)
    }
    
    // MARK: - geofenceStateChanged
    
    func test_geofenceStateChanged_entry() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    func test_geofenceStateChanged_exit() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLatFar, lng: testLng, radius: 50)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date().timeIntervalSince1970]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }

    func test_geofenceStateChanged_noChange() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date().timeIntervalSince1970]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertFalse(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }

    // MARK: - getBeacons
    
    func test_getBeacons_withinRange() {
        let beacon = makeBeacon(id: "beacon1", lat: testLat, lng: testLng)
        var state = RadarSyncState()
        state.syncedBeacons = [beacon]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let beacons = RadarSyncManager.getBeacons(for: location)
        
        XCTAssertEqual(beacons.count, 1)
        XCTAssertEqual(beacons.first?.id, "beacon1")
    }
    
    func test_getBeacons_outsideRange() {
        let beacon = makeBeacon(id: "beacon1", lat: testLatFar, lng: testLng)
        var state = RadarSyncState()
        state.syncedBeacons = [beacon]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let beacons = RadarSyncManager.getBeacons(for: location)
        
        XCTAssertEqual(beacons.count, 0)
    }
    
    // MARK: - beaconStateChanged
    
    func test_beaconStateChanged_entry() {
        let beacon = makeBeacon(id: "beacon1", lat: testLat, lng: testLng)
        var state = RadarSyncState()
        state.syncedBeacons = [beacon]
        state.lastSyncedBeaconIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.hasBeaconStateChanged(location: location))
    }
    
    func test_beaconStateChanged_exit() {
        let beacon = makeBeacon(id: "beacon1", lat: testLatFar, lng: testLng)
        var state = RadarSyncState()
        state.syncedBeacons = [beacon]
        state.lastSyncedBeaconIds = ["beacon1"]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.hasBeaconStateChanged(location: location))
    }
    
    // MARK: - getPlaces
    
    func test_getPlaces_withinRadius() {
        let place = makePlace(id: "place1", lat: testLat, lng: testLng)
        var state = RadarSyncState()
        state.syncedPlaces = [place]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let places = RadarSyncManager.getPlaces(for: location)
        
        XCTAssertEqual(places.count, 1)
        XCTAssertEqual(places.first?.id, "place1")
    }
    
    func test_getPlaces_outsideRadius() {
        let place = makePlace(id: "place1", lat: testLatFar, lng: testLng)
        var state = RadarSyncState()
        state.syncedPlaces = [place]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let places = RadarSyncManager.getPlaces(for: location)
        
        XCTAssertEqual(places.count, 0)
    }

    // MARK: - placeStateChanged
    
    func test_placeStateChanged_entry() {
        let place = makePlace(id: "place1", lat: testLat, lng: testLng)
        var state = RadarSyncState()
        state.syncedPlaces = [place]
        state.lastSyncedPlaceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.hasPlaceStateChanged(location: location))
    }
    
    func test_placeStateChanged_exit() {
        let place = makePlace(id: "place1", lat: testLatFar, lng: testLng)
        var state = RadarSyncState()
        state.syncedPlaces = [place]
        state.lastSyncedPlaceIds = ["place1"]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.hasPlaceStateChanged(location: location))
    }
    
    //MARK: - isOutsideSyncedRegion
    
    func test_isOutsideSyncedRegion_nil() {
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.isOutsideSyncedRegion(location: location))
    }
    
    func test_isOutsideSyncedRegion_inside() {
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 100
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertFalse(RadarSyncManager.isOutsideSyncedRegion(location: location))
    }
    
    func test_isOutsideSyncedRegion_outside() {
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 100
        setState(state)
        
        let location = CLLocation(latitude: testLatFar, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.isOutsideSyncedRegion(location: location))
    }
    
    // MARK: - isPointInsideCircle
    
    func test_isPointInsideCircle_inside() {
        let point = CLLocation(latitude: testLat, longitude: testLng)
        let center = CLLocationCoordinate2D(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.isPoint(point, insideCircleWithCenter: center, radius: 100))
    }
    
    func test_isPointInsideCircle_outside() {
        let point = CLLocation(latitude: testLatFar, longitude: testLng)
        let center = CLLocationCoordinate2D(latitude: testLat, longitude: testLng)
        XCTAssertFalse(RadarSyncManager.isPoint(point, insideCircleWithCenter: center, radius: 100))
    }
    
    // MARK: - Multiple geofences
    
    func test_multipleGeofences_shouldTrackWhenCrossingNearestBoundary() {
        let geofenceA = makeCircleGeofence(id: "geofenceA", lat: testLatNearby, lng: testLng, radius: 100)
        let geofenceB = makeCircleGeofence(id: "geofenceB", lat: testLatFar, lng: testLng, radius: 50)
        var state = RadarSyncState()
        state.syncedGeofences = [geofenceA, geofenceB]
        state.lastSyncedGeofenceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLatNearby, longitude: testLng)
        let options = RadarTrackingOptions()
        options.syncLocations = .events
        
        XCTAssertTrue(RadarSyncManager.shouldTrack(location: location, options: options))
    }
    
    func test_multipleGeofences_detectsCorrectGeofences() {
        let geofenceA = makeCircleGeofence(id: "geofenceA", lat: testLat, lng: testLng, radius: 100)
        let geofenceB = makeCircleGeofence(id: "geofenceB", lat: testLatNearby, lng: testLng, radius: 100)
        let geofenceC = makeCircleGeofence(id: "geofenceC", lat: testLatFar, lng: testLng, radius: 50)
        var state = RadarSyncState()
        state.syncedGeofences = [geofenceA, geofenceB, geofenceC]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        let geofences = RadarSyncManager.getGeofences(for: location)
        XCTAssertEqual(geofences.count, 2)
        
        let ids = Set(geofences.map { $0.id })
        XCTAssertTrue(ids.contains("geofenceA"))
        XCTAssertTrue(ids.contains("geofenceB"))
        XCTAssertFalse(ids.contains("geofenceC"))
    }
    
    // MARK: - Polygon geofences
    
    func test_getGeofences_insidePolygon() {
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
        
        XCTAssertEqual(geofences.count, 1)
        XCTAssertEqual(geofences.first?.id, "poly1")
    }
    
    func test_getGeofences_outsidePolygon() {
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
        
        XCTAssertEqual(geofences.count, 0)
    }
    
    func test_getGeofences_mixedCircleAndPolygon() {
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
        XCTAssertEqual(geofences.count, 2)
        
        let ids = Set(geofences.map { $0.id })
        XCTAssertTrue(ids.contains("circle1"))
        XCTAssertTrue(ids.contains("poly1"))
    }
    
    // MARK: - Buffered entry
    
    func test_getGeofences_bufferedEntry() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        setState(state)
        
        let config = RadarSdkConfiguration(dict: ["bufferGeofenceEntries": true])
        RadarSettings.sdkConfiguration = config
        
        let offsetLat = testLat + 0.001
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: offsetLat, longitude: testLng),
            altitude: 0, horizontalAccuracy: 20, verticalAccuracy: 10, timestamp: Date()
        )
        let geofences = RadarSyncManager.getGeofences(for: location)
        XCTAssertEqual(geofences.count, 1)
    }
    
    func test_getGeofences_bufferingDisabled() {
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
        XCTAssertEqual(geofences.count, 0)
    }
    
    // MARK: - Stop detection
    
    func test_geofenceEntry_stopDetectionBlocks() {
        RadarState.setStopped(false)
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100, stopDetection: true)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertFalse(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    func test_geofenceEntry_stopDetectionAllows() {
        RadarState.setStopped(true)
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100, stopDetection: true)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = []
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    // MARK: - Dwell
    
    func test_geofenceDwell_thresholdReached() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date(timeIntervalSinceNow: -600).timeIntervalSince1970]
        setState(state)
        
        let config = RadarSdkConfiguration(dict: ["defaultGeofenceDwellThreshold": 5])
        RadarSettings.setSdkConfiguration(config)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    func test_geofenceDwell_thresholdNotReached() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date(timeIntervalSinceNow: -60).timeIntervalSince1970]
        setState(state)
        
        let config = RadarSdkConfiguration(dict: ["defaultGeofenceDwellThreshold": 5])
        RadarSettings.setSdkConfiguration(config)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertFalse(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    func test_geofenceDwell_perGeofenceOverride() {
        let geofence = makeCircleGeofence(id: "geofence1", lat: testLat, lng: testLng, radius: 100, dwellThreshold: 2)
        var state = RadarSyncState()
        state.syncedGeofences = [geofence]
        state.lastSyncedGeofenceIds = ["geofence1"]
        state.geofenceEntryTimestamps = ["geofence1": Date(timeIntervalSinceNow: -180).timeIntervalSince1970]
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    func test_geofenceDwell_alreadyFired() {
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
        XCTAssertFalse(RadarSyncManager.hasGeofenceStateChanged(location: location))
    }
    
    // MARK: - isNearSyncedRegionBoundary
    
    func test_isNearSyncedRegionBoundary_near() {
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 1000
        setState(state)
        
        let location = CLLocation(latitude: testLat + 0.0081, longitude: testLng)
        XCTAssertTrue(RadarSyncManager.isNearSyncedRegionBoundary(location: location))
    }
    
    func test_isNearSyncedRegionBoundary_notNear() {
        var state = RadarSyncState()
        state.syncedRegionCenter = RadarCoordinateSwift(latitude: testLat, longitude: testLng)
        state.syncedRegionRadius = 1000
        setState(state)
        
        let location = CLLocation(latitude: testLat, longitude: testLng)
        XCTAssertFalse(RadarSyncManager.isNearSyncedRegionBoundary(location: location))
    }
}
