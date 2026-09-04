//
//  RadarLocationManagerSwiftLifecycleTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

private func invokeGetLocation(on manager: RadarLocationManager) {
    manager.perform(NSSelectorFromString("getLocationWithCompletionHandler:"), with: nil)
}

// Keep lifecycle seam tests together so the direct twins and their shared host stay easy to compare.
// swiftlint:disable file_length

final class TrackingRadarActivityManager: RadarActivityManager, @unchecked Sendable {
    private(set) var stopActivityUpdatesCallCount = 0
    private(set) var stopRelativeAltitudeUpdatesCallCount = 0
    private(set) var stopAbsoluteAltitudeUpdatesCallCount = 0

    override func stopActivityUpdates() {
        stopActivityUpdatesCallCount += 1
    }

    override func stopRelativeAltitudeUpdates() {
        stopRelativeAltitudeUpdatesCallCount += 1
    }

    override func stopAbsoluteAltitudeUpdates() {
        stopAbsoluteAltitudeUpdatesCallCount += 1
    }
}

final class TrackingRadarLocationManagerHost: NSObject, RadarLocationManagerSwiftHost, @unchecked Sendable {
    private var startedValue = false
    private var startedIntervalValue: Int32 = 0
    var sendingValue = false
    private var timerValue: Timer?
    private(set) var cancelPendingShutdownCallCount = 0
    private(set) var scheduledShutdownDelays: [TimeInterval] = []
    private(set) var requestLocationCallCount = 0
    private(set) var addCompletionHandlerCallCount = 0

    func started() -> Bool { startedValue }

    func setStarted(_ started: Bool) { startedValue = started }

    func startedInterval() -> Int32 { startedIntervalValue }

    func setStartedInterval(_ interval: Int32) { startedIntervalValue = interval }

    func sending() -> Bool { sendingValue }

    func timer() -> Timer? { timerValue }

    func setTimer(_ timer: Timer?) { timerValue = timer }

    func cancelPendingShutdown() {
        cancelPendingShutdownCallCount += 1
    }

    func requestLocation() {
        requestLocationCallCount += 1
    }

    func scheduleShutdown(after delay: TimeInterval) {
        scheduledShutdownDelays.append(delay)
    }

    func addCompletionHandler(_ completionHandler: RadarLocationCompletionHandler?) {
        addCompletionHandlerCallCount += 1
    }
}

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftLifecycleTests {  // swiftlint:disable:this type_body_length

        // MARK: - startUpdates

        @Test("startUpdates starts low-power updates and stops primary updates without the blue bar")
        func startUpdatesUsesLowPowerManagerWithoutBlueBar() {
            let host = TrackingRadarLocationManagerHost()
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.startUpdates(
                host: host,
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager,
                interval: 10,
                blueBar: false
            )
            defer { host.timer()?.invalidate() }

            #expect(host.started())
            #expect(host.startedInterval() == 10)
            #expect(host.timer() != nil)
            #expect(host.cancelPendingShutdownCallCount == 1)
            #expect(lowPowerLocationManager.startUpdatingLocationCallCount == 1)
            #expect(locationManager.startUpdatingLocationCallCount == 0)
            #expect(locationManager.stopUpdatingLocationCallCount == 1)

            host.timer()?.fire()
            #expect(host.requestLocationCallCount == 1)
        }

        @Test("startUpdates starts primary updates for a short blue-bar interval")
        func startUpdatesStartsPrimaryManagerForShortBlueBarInterval() {
            let host = TrackingRadarLocationManagerHost()
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.startUpdates(
                host: host,
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager,
                interval: 5,
                blueBar: true
            )
            defer { host.timer()?.invalidate() }

            #expect(locationManager.startUpdatingLocationCallCount == 1)
            #expect(locationManager.stopUpdatingLocationCallCount == 0)
            #expect(lowPowerLocationManager.startUpdatingLocationCallCount == 1)
        }

        @Test("startUpdates stops primary updates for a long blue-bar interval")
        func startUpdatesStopsPrimaryManagerForLongBlueBarInterval() {
            let host = TrackingRadarLocationManagerHost()
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.startUpdates(
                host: host,
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager,
                interval: 6,
                blueBar: true
            )
            defer { host.timer()?.invalidate() }

            #expect(locationManager.startUpdatingLocationCallCount == 0)
            #expect(locationManager.stopUpdatingLocationCallCount == 1)
        }

        @Test("startUpdates does not replace a timer when the interval is unchanged")
        func startUpdatesSkipsUnchangedInterval() {
            let host = TrackingRadarLocationManagerHost()
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.startUpdates(
                host: host,
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager,
                interval: 10,
                blueBar: false
            )
            let originalTimer = host.timer()

            RadarLocationManagerSwift.startUpdates(
                host: host,
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager,
                interval: 10,
                blueBar: false
            )
            defer { host.timer()?.invalidate() }

            #expect(host.timer() === originalTimer)
            #expect(host.cancelPendingShutdownCallCount == 1)
            #expect(lowPowerLocationManager.startUpdatingLocationCallCount == 1)
        }

        @Test("startUpdates replaces the timer when the interval changes")
        func startUpdatesReplacesChangedInterval() {
            let host = TrackingRadarLocationManagerHost()
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.startUpdates(
                host: host,
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager,
                interval: 10,
                blueBar: false
            )
            let originalTimer = host.timer()

            RadarLocationManagerSwift.startUpdates(
                host: host,
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager,
                interval: 20,
                blueBar: false
            )
            defer { host.timer()?.invalidate() }

            #expect(originalTimer?.isValid == false)
            #expect(host.timer() !== originalTimer)
            #expect(host.startedInterval() == 20)
            #expect(host.cancelPendingShutdownCallCount == 2)
            #expect(lowPowerLocationManager.startUpdatingLocationCallCount == 2)
        }

        // MARK: - stopUpdates

        @Test("stopUpdates is a no-op when no timer exists")
        func stopUpdatesDoesNothingWithoutTimer() {
            let host = TrackingRadarLocationManagerHost()
            host.setStarted(true)
            host.setStartedInterval(10)
            let locationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.stopUpdates(host: host, locationManager: locationManager)

            #expect(host.started())
            #expect(host.startedInterval() == 10)
            #expect(locationManager.stopUpdatingLocationCallCount == 0)
            #expect(host.scheduledShutdownDelays.isEmpty)
        }

        @Test("stopUpdates invalidates the timer, clears state, and schedules a tracked shutdown")
        func stopUpdatesSchedulesTrackedShutdown() {
            let host = TrackingRadarLocationManagerHost()
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()
            RadarSettings.tracking = true

            RadarLocationManagerSwift.startUpdates(
                host: host,
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager,
                interval: 10,
                blueBar: false
            )
            let timer = host.timer()

            RadarLocationManagerSwift.stopUpdates(host: host, locationManager: locationManager)
            defer { host.timer()?.invalidate() }

            #expect(timer?.isValid == false)
            #expect(host.timer() === timer)
            #expect(host.started() == false)
            #expect(host.startedInterval() == 0)
            #expect(locationManager.stopUpdatingLocationCallCount == 2)
            #expect(host.scheduledShutdownDelays == [10])
        }

        @Test("stopUpdates does not schedule shutdown while a location is sending")
        func stopUpdatesSkipsShutdownWhileSending() {
            let host = TrackingRadarLocationManagerHost()
            host.sendingValue = true
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.startUpdates(
                host: host,
                locationManager: locationManager,
                lowPowerLocationManager: lowPowerLocationManager,
                interval: 10,
                blueBar: false
            )

            RadarLocationManagerSwift.stopUpdates(host: host, locationManager: locationManager)
            defer { host.timer()?.invalidate() }

            #expect(host.scheduledShutdownDelays.isEmpty)
        }

        // MARK: - stopTracking

        @Test("stopTracking clears tracking state without stopping motion services when disabled")
        func stopTrackingClearsStateWithoutMotionServices() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.tracking = true
            let options = RadarTrackingOptions.presetEfficient
            options.startTrackingAfter = Date()
            options.stopTrackingAfter = Date()
            RadarSettings.trackingOptions = options

            let locationManager = TrackingCLLocationManager()
            let activityManager = TrackingRadarActivityManager()
            RadarLocationManagerSwift.stopTracking(
                locationManager: locationManager,
                activityManager: activityManager
            )

            #expect(RadarSettings.tracking == false)
            #expect(RadarSettings.trackingOptions.startTrackingAfter == nil)
            #expect(RadarSettings.trackingOptions.stopTrackingAfter == nil)
            #expect(locationManager.stopUpdatingHeadingCallCount == 0)
            #expect(activityManager.stopActivityUpdatesCallCount == 0)
            #expect(activityManager.stopRelativeAltitudeUpdatesCallCount == 0)
            #expect(activityManager.stopAbsoluteAltitudeUpdatesCallCount == 0)
            #expect(bridge.callOrder == ["stopIndoorTracking", "updateTracking"])
        }

        @Test("stopTracking stops activity and heading updates when motion is enabled")
        func stopTrackingStopsMotionUpdates() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            let options = RadarTrackingOptions.presetEfficient
            options.useMotion = true
            RadarSettings.trackingOptions = options
            let locationManager = TrackingCLLocationManager()
            let activityManager = TrackingRadarActivityManager()

            RadarLocationManagerSwift.stopTracking(
                locationManager: locationManager,
                activityManager: activityManager
            )

            #expect(locationManager.stopUpdatingHeadingCallCount == 1)
            #expect(activityManager.stopActivityUpdatesCallCount == 1)
            #expect(activityManager.stopRelativeAltitudeUpdatesCallCount == 0)
            #expect(activityManager.stopAbsoluteAltitudeUpdatesCallCount == 0)
        }

        @Test("stopTracking stops altitude and heading updates when pressure is enabled")
        func stopTrackingStopsPressureUpdates() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            let options = RadarTrackingOptions.presetEfficient
            options.usePressure = true
            RadarSettings.trackingOptions = options
            let locationManager = TrackingCLLocationManager()
            let activityManager = TrackingRadarActivityManager()

            RadarLocationManagerSwift.stopTracking(
                locationManager: locationManager,
                activityManager: activityManager
            )

            #expect(locationManager.stopUpdatingHeadingCallCount == 1)
            #expect(activityManager.stopActivityUpdatesCallCount == 0)
            #expect(activityManager.stopRelativeAltitudeUpdatesCallCount == 1)
            #expect(activityManager.stopAbsoluteAltitudeUpdatesCallCount == 1)
        }

        @Test("stopTracking flushes replays before updating tracking when configured")
        func stopTrackingFlushesReplaysBeforeUpdatingTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["extendFlushReplays": true])
            RadarLocationManagerSwift.stopTracking(
                locationManager: TrackingCLLocationManager(),
                activityManager: nil
            )

            #expect(bridge.flushReplaysCallCount == 1)
            #expect(bridge.callOrder == ["stopIndoorTracking", "flushReplays", "updateTracking"])
        }

        // MARK: - shutDown

        @Test("shutDown stops updates on both the primary and low-power location managers")
        func shutDownStopsBothManagers() {
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.shutDown(locationManager: locationManager, lowPowerLocationManager: lowPowerLocationManager)

            #expect(locationManager.stopUpdatingLocationCallCount == 1)
            #expect(lowPowerLocationManager.stopUpdatingLocationCallCount == 1)
        }

        // MARK: - requestLocation

        @Test("requestLocation requests a location from the primary location manager")
        func requestLocationRequestsFromPrimaryManager() {
            let locationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.requestLocation(locationManager: locationManager)

            #expect(locationManager.requestLocationCallCount == 1)
        }

        // MARK: - getLocation

        @Test("getLocation uses high accuracy for authorized when-in-use requests")
        func getLocationUsesHighAccuracyForAuthorizedWhenInUse() {
            let host = TrackingRadarLocationManagerHost()
            let locationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.getLocation(
                host: host,
                authorizationStatus: .authorizedWhenInUse,
                locationManager: locationManager,
                desiredAccuracy: .high,
                completionHandler: { _, _, _ in }
            )

            #expect(host.addCompletionHandlerCallCount == 1)
            #expect(locationManager.desiredAccuracy == kCLLocationAccuracyBest)
            #expect(locationManager.requestLocationCallCount == 1)
        }

        @Test("getLocation uses low accuracy for authorized-always requests")
        func getLocationUsesLowAccuracyForAuthorizedAlways() {
            let host = TrackingRadarLocationManagerHost()
            let locationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.getLocation(
                host: host,
                authorizationStatus: .authorizedAlways,
                locationManager: locationManager,
                desiredAccuracy: .low,
                completionHandler: nil
            )

            #expect(host.addCompletionHandlerCallCount == 0)
            #expect(locationManager.desiredAccuracy == kCLLocationAccuracyKilometer)
            #expect(locationManager.requestLocationCallCount == 1)
        }

        @Test("getLocation uses medium accuracy in the default overload")
        func getLocationUsesMediumAccuracyByDefault() {
            let host = TrackingRadarLocationManagerHost()
            let locationManager = TrackingCLLocationManager()

            RadarLocationManagerSwift.getLocation(
                host: host,
                authorizationStatus: .authorizedAlways,
                locationManager: locationManager,
                completionHandler: nil
            )

            #expect(locationManager.desiredAccuracy == kCLLocationAccuracyHundredMeters)
            #expect(locationManager.requestLocationCallCount == 1)
        }

        @Test("getLocation reports permissions errors before changing location state")
        func getLocationReportsPermissionsErrorBeforeChangingLocationState() {
            let host = TrackingRadarLocationManagerHost()
            let locationManager = TrackingCLLocationManager()
            let originalAccuracy = locationManager.desiredAccuracy
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer { RadarSwift.bridge = originalBridge }

            var callbackStatus: RadarStatus?
            var callbackLocation: CLLocation?
            var callbackStopped: Bool?
            RadarLocationManagerSwift.getLocation(
                host: host,
                authorizationStatus: .notDetermined,
                locationManager: locationManager,
                desiredAccuracy: .high,
                completionHandler: { status, location, stopped in
                    callbackStatus = status
                    callbackLocation = location
                    callbackStopped = stopped
                }
            )

            #expect(bridge.lastFailStatus == .errorPermissions)
            #expect(callbackStatus == .errorPermissions)
            #expect(callbackLocation == nil)
            #expect(callbackStopped == false)
            #expect(host.addCompletionHandlerCallCount == 0)
            #expect(locationManager.desiredAccuracy == originalAccuracy)
            #expect(locationManager.requestLocationCallCount == 0)
        }
    }
}

extension RadarSerializedTests.RadarLocationManagerSwiftLifecycleTests {
    // MARK: - getLocation — public method routing

    @Test("Public getLocation routes to the Swift twin when useSwiftLocationManager is enabled")
    func publicGetLocationRoutesToSwiftTwinWhenFlagEnabled() {
        RadarLocationManagerSwiftTestHelpers.clearState()
        let bridge = MockRadarSwiftBridge()
        let originalBridge = RadarSwift.bridge
        let manager = RadarLocationManager.sharedInstance()
        let originalPermissionsHelper = manager.permissionsHelper
        RadarSwift.bridge = bridge
        defer {
            RadarSwift.bridge = originalBridge
            manager.permissionsHelper = originalPermissionsHelper
            RadarLocationManagerSwiftTestHelpers.clearState()
        }

        let permissionsHelper = RadarPermissionsHelperMock()
        permissionsHelper.mockLocationAuthorizationStatus = .notDetermined
        manager.permissionsHelper = permissionsHelper
        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": true])

        invokeGetLocation(on: manager)

        #expect(bridge.lastFailStatus == .errorPermissions)
    }

    @Test("Public getLocation keeps the Objective-C body when useSwiftLocationManager is disabled")
    func publicGetLocationUsesObjCBodyWhenFlagDisabled() {
        RadarLocationManagerSwiftTestHelpers.clearState()
        let bridge = MockRadarSwiftBridge()
        let originalBridge = RadarSwift.bridge
        let manager = RadarLocationManager.sharedInstance()
        let originalPermissionsHelper = manager.permissionsHelper
        RadarSwift.bridge = bridge
        defer {
            RadarSwift.bridge = originalBridge
            manager.permissionsHelper = originalPermissionsHelper
            RadarLocationManagerSwiftTestHelpers.clearState()
        }

        let permissionsHelper = RadarPermissionsHelperMock()
        permissionsHelper.mockLocationAuthorizationStatus = .notDetermined
        manager.permissionsHelper = permissionsHelper
        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])

        invokeGetLocation(on: manager)

        #expect(bridge.lastFailStatus == nil)
    }
}

extension RadarSerializedTests.RadarLocationManagerSwiftLifecycleTests {
    // MARK: - didEnterRegion and didExitRegion

    @Test("region callbacks handle synced beacon entry and exit with nearby beacons")
    @MainActor
    func regionCallbacksHandleSyncedBeaconEntryAndExit() async {
        RadarLocationManagerSwiftTestHelpers.clearState()
        let bridge = MockRadarSwiftBridge()
        let originalBridge = RadarSwift.bridge
        RadarSwift.bridge = bridge
        defer {
            RadarSwift.bridge = originalBridge
            RadarLocationManagerSwiftTestHelpers.clearState()
        }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useRadarModifiedBeacon": false
        ])
        RadarSettings.tracking = true
        let beaconManager = RadarBeaconManagerSwift.shared
        beaconManager.stopRanging()
        let locationManager = TrackingCLLocationManager()
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 40.7, longitude: -74.0),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date()
        )
        locationManager.mockLocation = location
        let region = CLBeaconRegion(
            uuid: UUID(),
            identifier: "radar_beacon_\(UUID().uuidString)"
        )

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            bridge.onHandledLocation = { continuation.resume() }
            RadarLocationManagerSwift.didEnterRegion(locationManager: locationManager, region: region)
        }
        bridge.onHandledLocation = nil

        #expect(bridge.lastHandledLocation === location)
        #expect(bridge.lastHandledSource == .beaconEnter)
        #expect(bridge.lastHandledBeacons?.isEmpty == false)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            bridge.onHandledLocation = { continuation.resume() }
            RadarLocationManagerSwift.didExitRegion(locationManager: locationManager, region: region)
        }
        bridge.onHandledLocation = nil

        #expect(bridge.lastHandledLocation === location)
        #expect(bridge.lastHandledSource == .beaconExit)
    }

    @Test("region callbacks use the current location for geofence entry and exit")
    @MainActor
    func regionCallbacksHandleGeofenceEntryAndExit() {
        RadarLocationManagerSwiftTestHelpers.clearState()
        let bridge = MockRadarSwiftBridge()
        let originalBridge = RadarSwift.bridge
        RadarSwift.bridge = bridge
        defer {
            RadarSwift.bridge = originalBridge
            RadarLocationManagerSwiftTestHelpers.clearState()
        }

        RadarSettings.tracking = true
        let locationManager = TrackingCLLocationManager()
        let location = CLLocation(latitude: 40.7, longitude: -74.0)
        locationManager.mockLocation = location
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: 100,
            identifier: "radar_geofence_\(UUID().uuidString)"
        )

        RadarLocationManagerSwift.didEnterRegion(locationManager: locationManager, region: region)

        #expect(bridge.lastHandledLocation === location)
        #expect(bridge.lastHandledSource == .geofenceEnter)

        RadarLocationManagerSwift.didExitRegion(locationManager: locationManager, region: region)

        #expect(bridge.lastHandledLocation === location)
        #expect(bridge.lastHandledSource == .geofenceExit)
    }
}

extension RadarSerializedTests.RadarLocationManagerSwiftSeamTests {
    @Test("Public region callbacks route to the Swift twins when enabled")
    @MainActor
    func publicRegionCallbacksRouteToSwiftTwinsWhenFlagEnabled() {
        RadarLocationManagerSwiftTestHelpers.clearState()
        let bridge = MockRadarSwiftBridge()
        let originalBridge = RadarSwift.bridge
        let manager = RadarLocationManager.sharedInstance()
        let originalLocationManager = manager.locationManager
        RadarSwift.bridge = bridge
        defer {
            RadarSwift.bridge = originalBridge
            manager.locationManager = originalLocationManager
            RadarLocationManagerSwiftTestHelpers.clearState()
        }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useSwiftLocationManager": true
        ])
        RadarSettings.tracking = true
        let locationManager = TrackingCLLocationManager()
        let location = CLLocation(latitude: 40.7, longitude: -74.0)
        locationManager.mockLocation = location
        manager.locationManager = locationManager
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: 100,
            identifier: "radar_geofence_\(UUID().uuidString)"
        )

        manager.locationManager(locationManager, didEnterRegion: region)
        #expect(bridge.lastHandledLocation === location)
        #expect(bridge.lastHandledSource == .geofenceEnter)

        manager.locationManager(locationManager, didExitRegion: region)
        #expect(bridge.lastHandledLocation === location)
        #expect(bridge.lastHandledSource == .geofenceExit)
    }

    @Test("Public region callbacks keep the Objective-C body when disabled")
    @MainActor
    func publicRegionCallbacksUseObjCBodyWhenFlagDisabled() {
        RadarLocationManagerSwiftTestHelpers.clearState()
        let bridge = MockRadarSwiftBridge()
        let originalBridge = RadarSwift.bridge
        let manager = RadarLocationManager.sharedInstance()
        let originalLocationManager = manager.locationManager
        RadarSwift.bridge = bridge
        defer {
            RadarSwift.bridge = originalBridge
            manager.locationManager = originalLocationManager
            RadarLocationManagerSwiftTestHelpers.clearState()
        }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useSwiftLocationManager": false
        ])
        RadarSettings.tracking = true
        let locationManager = TrackingCLLocationManager()
        let location = CLLocation(latitude: 40.7, longitude: -74.0)
        locationManager.mockLocation = location
        manager.locationManager = locationManager
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: 100,
            identifier: "radar_geofence_\(UUID().uuidString)"
        )

        manager.locationManager(locationManager, didEnterRegion: region)
        manager.locationManager(locationManager, didExitRegion: region)

        #expect(bridge.lastHandledLocation == nil)
        #expect(bridge.lastHandledSource == nil)
    }
}
