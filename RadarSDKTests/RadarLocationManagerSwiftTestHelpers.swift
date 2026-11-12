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

    /// Swift tracking crosses both injection seams; keeping their lifetime scoped together
    /// prevents a test's bridge or authorization state from leaking into the next test.
    static func withMockedSwiftTrackingDependencies(
        authorizationStatus: CLAuthorizationStatus = .authorizedAlways,
        _ body: (MockRadarSwiftBridge) throws -> Void
    ) rethrows {
        clearState()
        defer { clearState() }

        let bridge = MockRadarSwiftBridge()
        let originalBridge = RadarSwift.bridge
        RadarSwift.bridge = bridge
        defer { RadarSwift.bridge = originalBridge }

        let permissionsHelper = MockRadarPermissionsHelper()
        permissionsHelper.mockAuthorizationStatus = authorizationStatus
        let originalPermissionsHelper = RadarLocationManagerSwift.permissionsHelper
        RadarLocationManagerSwift.permissionsHelper = permissionsHelper
        defer { RadarLocationManagerSwift.permissionsHelper = originalPermissionsHelper }

        let originalBootstrapIndoorTracking = RadarLocationManagerSwift.bootstrapIndoorTracking
        RadarLocationManagerSwift.bootstrapIndoorTracking = {}
        defer { RadarLocationManagerSwift.bootstrapIndoorTracking = originalBootstrapIndoorTracking }

        // Record what `handleLocation` sends on the test host instead of calling the track API.
        let originalSendLocationHandler = RadarLocationManagerSwift.sendLocationHandler
        RadarLocationManagerSwift.sendLocationHandler = { host, send in
            (host as? TrackingRadarLocationManagerHost)?.recordSentLocation(send)
        }
        defer { RadarLocationManagerSwift.sendLocationHandler = originalSendLocationHandler }

        // Record completion handler calls instead of starting real 20 second timeouts.
        try withRecordingCompletionStore { _ in
            try body(bridge)
        }
    }

    /// The completion store `withRecordingCompletionStore` installed. Valid only inside its body.
    nonisolated(unsafe) private(set) static var completions = RecordingCompletionStore()

    /// Replaces the Swift completion store with a recording store for the body, then restores it.
    static func withRecordingCompletionStore<T>(_ body: (RecordingCompletionStore) throws -> T) rethrows -> T {
        let store = RecordingCompletionStore()
        let originalStore = RadarLocationManagerSwift.completionStore
        let originalCompletions = completions
        RadarLocationManagerSwift.completionStore = store
        completions = store
        defer {
            RadarLocationManagerSwift.completionStore = originalStore
            completions = originalCompletions
        }

        return try body(store)
    }

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
        RadarLocationManagerSwift.bubbleGeofenceRegion = nil
        RadarLocationManager.sharedInstance().setValue(nil, forKey: "bubbleGeofenceRegion")
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
            geofenceStopDetection: nil,
            activeIndoorModelId: nil
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

/// Records calls to the Swift completion store. It keeps the added handlers but never times them out.
final class RecordingCompletionStore: RadarLocationCompletionStoring, @unchecked Sendable {
    private(set) var addCallCount = 0
    private(set) var cancelTimeoutsCallCount = 0
    private(set) var statuses: [RadarStatus] = []
    /// Handlers that `count` reports in addition to the added ones.
    var extraPendingCount = 0
    private var handlers: [RadarLocationCompletionHandler] = []

    var count: Int { handlers.count + extraPendingCount }

    func add(_ completionHandler: @escaping RadarLocationCompletionHandler) {
        addCallCount += 1
        handlers.append(completionHandler)
    }

    func cancelTimeouts() {
        cancelTimeoutsCallCount += 1
    }

    func call(status: RadarStatus, location: CLLocation?) {
        statuses.append(status)
        let waiting = handlers
        handlers.removeAll()
        waiting.forEach { $0(status, location, false) }
    }
}
