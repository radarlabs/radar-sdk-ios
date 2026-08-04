//
//  RadarIndoorsUpdateTrackingTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing

@testable import RadarSDK

/// A stand-in for the optional `RadarSDKIndoors` framework's instance.
///
/// `RadarSDKIndoors` (the Swift wrapper in RadarIndoors.swift) reaches into its wrapped
/// `NSObject` via `perform(...)`, so a mock only needs to respond to the five selectors the
/// wrapper calls. It records start/stop/useModel calls so tests can assert exactly what
/// `RadarIndoors.updateTracking(geofences:)` does with beacon ranging, mirroring
/// `MockFraudInstance` in RadarRevealRiskTests.swift.
final class MockIndoorsInstance: NSObject, @unchecked Sendable {
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var useModelCallCount = 0
    private(set) var lastModelName: String?

    @objc(useModelWithConfig:completionHandler:)
    func useModel(config: [String: Any], completionHandler: @escaping () -> Void) {
        useModelCallCount += 1
        lastModelName = config["name"] as? String
        completionHandler()
    }

    @objc(getLocationWithCompletionHandler:)
    func getLocation(completionHandler: @escaping (CLLocation?) -> Void) {
        completionHandler(nil)
    }

    @objc(startWithCompletionHandler:)
    func start(completionHandler: @escaping () -> Void) {
        startCallCount += 1
        completionHandler()
    }

    @objc(stopWithCompletionHandler:)
    func stop(completionHandler: @escaping () -> Void) {
        stopCallCount += 1
        completionHandler()
    }

    @objc(setOnLocationUpdate:)
    func setOnLocationUpdate(_ block: @escaping (CLLocation) -> Void) {}
}

/// Covers `RadarIndoors.updateTracking(geofences:)`, in particular the fix for indoor beacon
/// ranging that never stopped once started (it kept running, and logging, after the user left
/// the indoor geofence or called `Radar.stopTracking()`). Exercises the real actor-isolated
/// method against an injected mock, via the testable `RadarIndoors(sdk:)` / `RadarSDKIndoors
/// (instance:)` initializers, rather than the process-wide `RadarIndoors.shared` singleton (whose
/// `sdk` is always nil in this test target since the optional RadarSDKIndoors framework isn't
/// linked).
extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarIndoorsUpdateTrackingTests {

        // MARK: - fixtures

        private func makeIndoors() -> (indoors: RadarIndoors, mock: MockIndoorsInstance) {
            let mock = MockIndoorsInstance()
            // The mock responds to every selector `RadarSDKIndoors` calls, so this always succeeds.
            let sdk = RadarSDKIndoors(instance: mock)!
            return (RadarIndoors(sdk: sdk), mock)
        }

        private func setIndoorScanEnabled(_ enabled: Bool) {
            let options = RadarTrackingOptions.presetContinuous
            options.useIndoorScan = enabled
            RadarSettings.trackingOptions = options
            // `Radar.getTrackingOptions()` returns `remoteTrackingOptions ?? trackingOptions`; clear
            // any remote options so the local options set above are the ones that take effect.
            RadarSettings.remoteTrackingOptions = nil
        }

        private func geofence(id: String, activeIndoorModelId: String?) -> RadarGeofence {
            let center = RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))!
            return RadarGeofence(
                id: id,
                description: id,
                tag: nil,
                externalId: nil,
                metadata: nil,
                operatingHours: nil,
                geometry: RadarCircleGeometry(center: center, radius: 100),
                dwellThreshold: nil,
                geofenceStopDetection: nil,
                activeIndoorModelId: activeIndoorModelId
            )!
        }

        // MARK: - the fix: leaving the indoor geofence stops the scan

        @Test("stops indoor scanning once the current geofences no longer include an active indoor model")
        func stopsWhenGeofenceLosesModel() async {
            setIndoorScanEnabled(true)
            let (indoors, mock) = makeIndoors()

            // Enter a geofence with an indoor model: starts beacon ranging.
            await indoors.updateTracking(geofences: [geofence(id: "g1", activeIndoorModelId: "model-1")])
            #expect(mock.startCallCount == 1)
            #expect(mock.stopCallCount == 0)

            // Leave it: the next `/track` response reports geofences with no active indoor model.
            await indoors.updateTracking(geofences: [geofence(id: "g2", activeIndoorModelId: nil)])

            #expect(mock.stopCallCount == 1, "leaving the indoor geofence must stop beacon ranging")
        }

        @Test("stops indoor scanning when the next geofence list is nil (e.g. stopTracking's forced refresh)")
        func stopsWhenGeofencesAreNil() async {
            setIndoorScanEnabled(true)
            let (indoors, mock) = makeIndoors()

            await indoors.updateTracking(geofences: [geofence(id: "g1", activeIndoorModelId: "model-1")])
            #expect(mock.startCallCount == 1)

            // Mirrors what `RadarLocationManager.stopTracking` now does: force a re-evaluation with
            // no geofences.
            await indoors.updateTracking(geofences: nil)

            #expect(mock.stopCallCount == 1)
        }

        @Test("does not call stop when no scan was ever started")
        func noOpWhenNeverStarted() async {
            setIndoorScanEnabled(true)
            let (indoors, mock) = makeIndoors()

            await indoors.updateTracking(geofences: [geofence(id: "g1", activeIndoorModelId: nil)])

            #expect(mock.stopCallCount == 0, "there is nothing to stop if ranging was never started")
            #expect(mock.startCallCount == 0)
        }

        // MARK: - regression guards for existing behavior

        @Test("disabling useIndoorScan stops an active scan")
        func disablingFlagStopsActiveScan() async {
            setIndoorScanEnabled(true)
            let (indoors, mock) = makeIndoors()
            await indoors.updateTracking(geofences: [geofence(id: "g1", activeIndoorModelId: "model-1")])
            #expect(mock.startCallCount == 1)

            setIndoorScanEnabled(false)
            await indoors.updateTracking(geofences: [geofence(id: "g1", activeIndoorModelId: "model-1")])

            #expect(mock.stopCallCount == 1)
        }

        @Test("re-evaluating the same active model does not restart the scan")
        func sameModelDoesNotRestart() async {
            setIndoorScanEnabled(true)
            let (indoors, mock) = makeIndoors()

            await indoors.updateTracking(geofences: [geofence(id: "g1", activeIndoorModelId: "model-1")])
            await indoors.updateTracking(geofences: [geofence(id: "g1", activeIndoorModelId: "model-1")])

            #expect(mock.startCallCount == 1, "the model is already active; start() should not be called again")
            #expect(mock.useModelCallCount == 1)
        }

        @Test("switching to a different indoor model starts the new one")
        func switchingModelsStartsNewOne() async {
            setIndoorScanEnabled(true)
            let (indoors, mock) = makeIndoors()

            await indoors.updateTracking(geofences: [geofence(id: "g1", activeIndoorModelId: "model-1")])
            await indoors.updateTracking(geofences: [geofence(id: "g2", activeIndoorModelId: "model-2")])

            #expect(mock.startCallCount == 2)
            #expect(mock.lastModelName == "model-2.mlmodel")
        }
    }
}
