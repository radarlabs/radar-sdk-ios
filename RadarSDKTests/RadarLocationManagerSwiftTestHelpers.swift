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

    /// Build `RadarTrackingOptions` with `beacons` toggled as requested.
    /// Starts from `presetResponsive` to get a valid preset.
    static func trackingOptions(beacons: Bool) -> RadarTrackingOptions {
        let options = RadarTrackingOptions.presetResponsive
        options.beacons = beacons
        return options
    }
}
