//
//  RadarLocationManagerSwiftTrackingTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

private func trackingOptions(_ configure: (RadarTrackingOptions) -> Void) -> RadarTrackingOptions {
    let options = RadarTrackingOptions()
    configure(options)
    return options
}

private func drainMainQueue() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            continuation.resume()
        }
    }
}

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftTrackingTests {

        // Runs `updateTracking` against a fresh host with mocked bridge and permissions.
        private func runUpdateTracking(
            options: RadarTrackingOptions?,
            tracking: Bool,
            stopped: Bool = false,
            authorizationStatus: CLAuthorizationStatus = .authorizedAlways,
            sdkConfiguration: RadarSdkConfiguration? = nil,
            location: CLLocation? = CLLocation(latitude: 40.7, longitude: -74.0),
            fromInitialize: Bool = false,
            seedRegions: [String] = [],
            _ verify: (TrackingRadarLocationManagerHost, TrackingCLLocationManager, TrackingCLLocationManager) -> Void
        ) {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies(
                authorizationStatus: authorizationStatus
            ) { bridge in
                bridge.mockStopped = stopped
                RadarSettings.tracking = tracking
                RadarSettings.trackingOptions = options
                RadarSettings.sdkConfiguration = sdkConfiguration

                let host = TrackingRadarLocationManagerHost()
                let locationManager = host.trackingLocationManager
                let lowPowerLocationManager = host.trackingLowPowerLocationManager
                locationManager.seed(seedRegions)
                defer { host.timer()?.invalidate() }

                RadarLocationManagerSwift.updateTracking(host: host, location: location, fromInitialize: fromInitialize)

                verify(host, locationManager, lowPowerLocationManager)
            }
        }

        // MARK: - Tracking on

        @Test("Moving state starts updates at the moving interval and places a moving bubble geofence")
        func movingStateUsesMovingIntervalAndBubble() {
            let options = trackingOptions {
                $0.desiredMovingUpdateInterval = 150
                $0.desiredStoppedUpdateInterval = 0
                $0.useMovingGeofence = true
                $0.movingGeofenceRadius = 200
                $0.useStoppedGeofence = true
                $0.stoppedGeofenceRadius = 100
            }

            runUpdateTracking(options: options, tracking: true) { host, locationManager, lowPowerLocationManager in
                #expect(host.started())
                #expect(host.startedInterval() == 150)
                #expect(lowPowerLocationManager.startUpdatingLocationCallCount == 1)

                let bubbles = locationManager.monitoredRegions.compactMap { $0 as? CLCircularRegion }
                    .filter { $0.identifier.hasPrefix("radar_bubble_") }
                #expect(bubbles.count == 1)
                #expect(bubbles.first?.radius == 200)
            }
        }

        @Test("Stopped state starts updates at the stopped interval and places a stopped bubble geofence")
        func stoppedStateUsesStoppedIntervalAndBubble() {
            let options = trackingOptions {
                $0.desiredMovingUpdateInterval = 150
                $0.desiredStoppedUpdateInterval = 300
                $0.useMovingGeofence = true
                $0.movingGeofenceRadius = 200
                $0.useStoppedGeofence = true
                $0.stoppedGeofenceRadius = 100
            }

            runUpdateTracking(options: options, tracking: true, stopped: true) { host, locationManager, _ in
                #expect(host.started())
                #expect(host.startedInterval() == 300)

                let bubbles = locationManager.monitoredRegions.compactMap { $0 as? CLCircularRegion }
                    .filter { $0.identifier.hasPrefix("radar_bubble_") }
                #expect(bubbles.count == 1)
                #expect(bubbles.first?.radius == 100)
            }
        }

        @Test("A zero interval leaves updates stopped and an unused bubble geofence is removed")
        func zeroIntervalDoesNotStartUpdates() {
            let options = trackingOptions {
                $0.desiredMovingUpdateInterval = 0
                $0.useMovingGeofence = false
            }

            let seed = ["radar_bubble_old"]
            runUpdateTracking(options: options, tracking: true, seedRegions: seed) { host, locationManager, lowPower in
                #expect(!host.started())
                #expect(lowPower.startUpdatingLocationCallCount == 0)
                #expect(!locationManager.monitoredRegions.contains { $0.identifier == "radar_bubble_old" })
            }
        }

        @Test(
            "With when-in-use authorization, updates start only with the blue bar or startUpdatesWhileInUse",
            arguments: [(false, false, false), (true, false, true), (false, true, true)]
        )
        func whenInUseStartsUpdatesOnlyWhenAllowed(showBlueBar: Bool, startUpdatesWhileInUse: Bool, expectStarted: Bool) {
            let options = trackingOptions {
                $0.desiredMovingUpdateInterval = 150
                $0.showBlueBar = showBlueBar
            }
            let sdkConfiguration = RadarSdkConfiguration(dict: ["startUpdatesWhileInUse": startUpdatesWhileInUse])

            runUpdateTracking(
                options: options,
                tracking: true,
                authorizationStatus: .authorizedWhenInUse,
                sdkConfiguration: sdkConfiguration
            ) { host, _, _ in
                #expect(host.started() == expectStarted)
            }
        }

        @Test("Desired accuracy and blue bar are applied to the location managers")
        func appliesAccuracyAndBlueBar() {
            let options = trackingOptions {
                $0.desiredAccuracy = .low
                $0.showBlueBar = true
            }

            runUpdateTracking(options: options, tracking: true) { _, locationManager, lowPowerLocationManager in
                #expect(locationManager.desiredAccuracy == kCLLocationAccuracyKilometer)
                #expect(!locationManager.pausesLocationUpdatesAutomatically)
                #expect(lowPowerLocationManager.showsBackgroundLocationIndicator)
                #expect(!lowPowerLocationManager.pausesLocationUpdatesAutomatically)
            }
        }

        @Test("Visits and significant location changes follow the tracking options")
        func visitsAndSLCFollowOptions() {
            let enabled = trackingOptions {
                $0.useVisits = true
                $0.useSignificantLocationChanges = true
            }
            runUpdateTracking(options: enabled, tracking: true) { _, locationManager, _ in
                #expect(locationManager.startMonitoringVisitsCallCount == 1)
                #expect(locationManager.startMonitoringSLCCallCount == 1)
                #expect(locationManager.stopMonitoringVisitsCallCount == 0)
                #expect(locationManager.stopMonitoringSLCCallCount == 0)
            }

            let disabled = trackingOptions {
                $0.useVisits = false
                $0.useSignificantLocationChanges = false
            }
            runUpdateTracking(options: disabled, tracking: true) { _, locationManager, _ in
                #expect(locationManager.startMonitoringVisitsCallCount == 0)
                #expect(locationManager.startMonitoringSLCCallCount == 0)
                #expect(locationManager.stopMonitoringVisitsCallCount == 1)
                #expect(locationManager.stopMonitoringSLCCallCount == 1)
            }
        }

        @Test("Synced geofences and beacons are removed when their options are off")
        func removesSyncedRegionsWhenDisabled() {
            let seed = ["radar_geofence_a", "radar_beacon_b", "radar_uuid_c", "other_region"]

            let disabled = trackingOptions {
                $0.syncGeofences = false
                $0.beacons = false
            }
            runUpdateTracking(options: disabled, tracking: true, seedRegions: seed) { _, locationManager, _ in
                #expect(locationManager.monitoredRegions.map(\.identifier) == ["other_region"])
            }

            let enabled = trackingOptions {
                $0.syncGeofences = true
                $0.beacons = true
            }
            runUpdateTracking(options: enabled, tracking: true, seedRegions: seed) { _, locationManager, _ in
                #expect(Set(locationManager.monitoredRegions.map(\.identifier)) == Set(seed))
            }
        }

        @Test("Motion and pressure options call the host motion callback")
        func motionOptionsCallHost() {
            runUpdateTracking(options: trackingOptions { $0.useMotion = true }, tracking: true) { host, _, _ in
                #expect(host.startMotionUpdatesOptions.count == 1)
            }
            runUpdateTracking(options: trackingOptions { $0.usePressure = true }, tracking: true) { host, _, _ in
                #expect(host.startMotionUpdatesOptions.count == 1)
            }
            runUpdateTracking(options: trackingOptions { _ in }, tracking: true) { host, _, _ in
                #expect(host.startMotionUpdatesOptions.isEmpty)
            }
        }

        // MARK: - Time-based tracking

        @Test("A past startTrackingAfter turns tracking on")
        func startTrackingAfterTurnsTrackingOn() {
            let options = trackingOptions {
                $0.startTrackingAfter = Date(timeIntervalSinceNow: -60)
                $0.desiredMovingUpdateInterval = 150
            }

            runUpdateTracking(options: options, tracking: false) { host, _, _ in
                #expect(RadarSettings.tracking)
                #expect(host.started())
            }
        }

        @Test("A past stopTrackingAfter turns tracking off and removes Radar regions")
        func stopTrackingAfterTurnsTrackingOff() {
            let options = trackingOptions { $0.stopTrackingAfter = Date(timeIntervalSinceNow: -60) }

            runUpdateTracking(
                options: options,
                tracking: true,
                seedRegions: ["radar_geofence_a", "radar_bubble_b", "other_region"]
            ) { _, locationManager, _ in
                #expect(!RadarSettings.tracking)
                #expect(locationManager.monitoredRegions.map(\.identifier) == ["other_region"])
            }
        }

        @Test("A future startTrackingAfter leaves tracking off")
        func futureStartTrackingAfterLeavesTrackingOff() {
            let options = trackingOptions { $0.startTrackingAfter = Date(timeIntervalSinceNow: 60) }

            runUpdateTracking(options: options, tracking: false) { _, _, _ in
                #expect(!RadarSettings.tracking)
            }
        }

        // MARK: - Tracking off

        @Test("Tracking off stops visits and SLCs unless called from the initializer", arguments: [false, true])
        func trackingOffStopsMonitoringUnlessFromInitialize(fromInitialize: Bool) {
            runUpdateTracking(
                options: nil,
                tracking: false,
                fromInitialize: fromInitialize,
                seedRegions: ["radar_geofence_a", "other_region"]
            ) { _, locationManager, _ in
                let expectedStopCount = fromInitialize ? 0 : 1
                #expect(locationManager.stopMonitoringVisitsCallCount == expectedStopCount)
                #expect(locationManager.stopMonitoringSLCCallCount == expectedStopCount)
                #expect(locationManager.monitoredRegions.map(\.identifier) == ["other_region"])
            }
        }
    }

    @Suite(.serialized)
    actor UpdateTrackingRoutingTests {

        @Test("Public updateTracking reaches the same end state with the flag on or off", arguments: [true, false])
        func publicUpdateTrackingReachesSameEndState(useSwiftLocationManager: Bool) async {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let locationManager = TrackingCLLocationManager()
            locationManager.seed(["radar_geofence_a", "other_region"])
            defer {
                manager.locationManager = originalLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": useSwiftLocationManager])
            RadarSettings.tracking = true
            RadarSettings.trackingOptions = trackingOptions { $0.stopTrackingAfter = Date(timeIntervalSinceNow: -60) }
            manager.locationManager = locationManager

            manager.updateTracking()
            await drainMainQueue()

            #expect(!RadarSettings.tracking)
            #expect(locationManager.monitoredRegions.map(\.identifier) == ["other_region"])
            #expect(locationManager.stopMonitoringVisitsCallCount == 1)
            #expect(locationManager.stopMonitoringSLCCallCount == 1)
        }

        @Test("Public updateTracking routes to the Swift twin when useSwiftLocationManager is enabled")
        func publicUpdateTrackingRoutesToSwiftTwin() async {
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let originalLowPowerLocationManager = manager.lowPowerLocationManager
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()
            defer {
                manager.perform(NSSelectorFromString("stopUpdates"))
                manager.perform(NSSelectorFromString("cancelPendingShutdown"))
                manager.locationManager = originalLocationManager
                manager.lowPowerLocationManager = originalLowPowerLocationManager
            }

            // Only the Swift twin reads the injected permissions helper, so updates start only on the Swift path.
            let permissionsHelper = MockRadarPermissionsHelper()
            permissionsHelper.mockAuthorizationStatus = .authorizedAlways
            let originalPermissionsHelper = RadarLocationManagerSwift.permissionsHelper
            RadarLocationManagerSwift.permissionsHelper = permissionsHelper
            defer { RadarLocationManagerSwift.permissionsHelper = originalPermissionsHelper }

            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": true])
            RadarSettings.tracking = true
            RadarSettings.trackingOptions = trackingOptions {
                $0.desiredMovingUpdateInterval = 150
                $0.desiredStoppedUpdateInterval = 150
                $0.desiredAccuracy = .low
            }
            manager.locationManager = locationManager
            manager.lowPowerLocationManager = lowPowerLocationManager

            manager.updateTracking()
            await drainMainQueue()

            #expect(lowPowerLocationManager.startUpdatingLocationCallCount == 1)
            #expect(locationManager.desiredAccuracy == kCLLocationAccuracyKilometer)
        }
    }

    @Suite(.serialized)
    actor SwiftStartTrackingIndoorBootstrapTests {

        @Test("start tracking bootstraps indoor tracking after updating tracking")
        @MainActor
        func startTrackingBootstrapsIndoorTracking() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                var updateTrackingCallCountAtBootstrap: Int?
                RadarLocationManagerSwift.bootstrapIndoorTracking = {
                    updateTrackingCallCountAtBootstrap = bridge.updateTrackingCallCount
                }

                RadarLocationManagerSwift.startTracking(options: .presetResponsive)

                #expect(updateTrackingCallCountAtBootstrap == 1)
            }
        }

        @Test("start tracking does not bootstrap indoor tracking when unauthorized")
        @MainActor
        func startTrackingSkipsIndoorBootstrapWhenUnauthorized() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies(authorizationStatus: .denied) { _ in
                var bootstrapCallCount = 0
                RadarLocationManagerSwift.bootstrapIndoorTracking = { bootstrapCallCount += 1 }

                RadarLocationManagerSwift.startTracking(options: .presetResponsive)

                #expect(bootstrapCallCount == 0)
            }
        }
    }
}
