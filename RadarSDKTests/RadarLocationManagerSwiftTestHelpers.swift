//
//  RadarLocationManagerSwiftTestHelpers.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//
//  Shared helpers for the Swift-port test suites in
//  `RadarLocationManagerSwift*Tests.swift`. As more Swift twins land, this
//  file will grow with additional shared builders (e.g. for beacons and
//  tracking-options fixtures).
//

import CoreLocation
import Foundation

@testable import RadarSDK

enum RadarLocationManagerSwiftTestHelpers {

    /// Reset every `RadarSettings` key the seam tests write so each test starts
    /// from a known state, and restore the shared `RadarLocationManager`'s
    /// permissions helper to a real one. Call at the beginning of each test
    /// and in a `defer` block after.
    static func clearState() {
        RadarSettings.previousTrackingOptions = nil
        RadarSettings.sdkConfiguration = nil
        RadarSettings.tracking = false
        RadarSettings.trackingOptions = nil
        RadarSettings.remoteTrackingOptions = nil
        RadarLocationManager.sharedInstance().permissionsHelper = RadarPermissionsHelper()
    }

    /// Install a `RadarPermissionsHelperMock` reporting `authorizedAlways` so
    /// that `Radar.startTracking(trackingOptions:)` doesn't bail early on the
    /// permission gate in `RadarLocationManager.startTrackingWithOptions:`.
    /// Tests that need to observe tracking side effects should call this after
    /// `clearState()`.
    static func installAuthorizedPermissions() {
        let mock = RadarPermissionsHelperMock()
        mock.mockLocationAuthorizationStatus = .authorizedAlways
        RadarLocationManager.sharedInstance().permissionsHelper = mock
    }

    /// Construct a `RadarBeacon` with all the fields `matchBeaconIds` and
    /// `replaceSyncedBeacons` read.
    static func makeBeacon(id: String, uuid: String, major: String, minor: String) -> RadarBeacon {
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

    /// Construct a circle `RadarGeofence` with the fields `replaceSyncedGeofences` reads
    /// (`_id` and a `RadarCircleGeometry` center/radius).
    static func makeGeofence(id: String, latitude: Double = 0, longitude: Double = 0, radius: Double = 100) -> RadarGeofence {
        let center = RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))!
        return geofence(id: id, geometry: RadarCircleGeometry(center: center, radius: radius))
    }

    /// Construct a polygon `RadarGeofence`; `replaceSyncedGeofences` reads the polygon's
    /// computed `center`/`radius`.
    static func makePolygonGeofence(id: String, latitude: Double = 0, longitude: Double = 0, radius: Double = 100) -> RadarGeofence {
        let center = RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))!
        return geofence(id: id, geometry: RadarPolygonGeometry(coordinates: [center], center: center, radius: radius))
    }

    private static func geofence(id: String, geometry: RadarGeofenceGeometry) -> RadarGeofence {
        return RadarGeofence(
            id: id,
            description: id,
            tag: nil,
            externalId: nil,
            metadata: nil,
            operatingHours: nil,
            geometry: geometry,
            dwellThreshold: nil,
            geofenceStopDetection: nil
        )!
    }

    /// Build `RadarTrackingOptions` with `beacons` toggled as requested.
    /// Starts from `presetResponsive` to get a valid preset.
    static func trackingOptions(beacons: Bool) -> RadarTrackingOptions {
        let options = RadarTrackingOptions.presetResponsive
        options.beacons = beacons
        return options
    }
}
