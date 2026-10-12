//
//  RadarLocationManagerObjCTrackingTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

// Covers fixes to the Objective-C `RadarLocationManager` bodies that run while
// `useSwiftLocationManager` is off. The Swift twins have matching tests in the
// RadarLocationManagerSwift*Tests suites.

private func invokeStartUpdates(on manager: RadarLocationManager, interval: Int32, blueBar: Bool) {
    typealias StartUpdatesFunction = @convention(c) (AnyObject, Selector, Int32, Bool) -> Void

    let selector = NSSelectorFromString("startUpdates:blueBar:")
    guard let implementation = manager.method(for: selector) else {
        preconditionFailure("RadarLocationManager does not respond to startUpdates:blueBar:")
    }

    unsafeBitCast(implementation, to: StartUpdatesFunction.self)(manager, selector, interval, blueBar)
}

private func invokeStopUpdates(on manager: RadarLocationManager) {
    manager.perform(NSSelectorFromString("stopUpdates"))
}

private func invokeReplaceBubbleGeofence(on manager: RadarLocationManager, location: CLLocation, radius: Int32) {
    typealias ReplaceBubbleGeofenceFunction = @convention(c) (AnyObject, Selector, CLLocation, Int32) -> Void

    let selector = NSSelectorFromString("replaceBubbleGeofence:radius:")
    guard let implementation = manager.method(for: selector) else {
        preconditionFailure("RadarLocationManager does not respond to replaceBubbleGeofence:radius:")
    }

    unsafeBitCast(implementation, to: ReplaceBubbleGeofenceFunction.self)(manager, selector, location, radius)
}

private func invokeRemoveBubbleGeofence(on manager: RadarLocationManager) {
    manager.perform(NSSelectorFromString("removeBubbleGeofence"))
}

/// Wait for blocks already queued on the main queue, such as the body of the Objective-C
/// `updateTracking`, which dispatches asynchronously.
private func drainMainQueue() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async { continuation.resume() }
    }
}

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerObjCTrackingTests {
        @Test("Objective-C back-to-back replaceBubbleGeofence calls leave one bubble while monitoredRegions is stale")
        func objCReplaceBubbleGeofenceBackToBackLeavesOneBubble() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let locationManager = TrackingCLLocationManager()
            defer {
                manager.locationManager = originalLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            RadarSettings.tracking = true
            manager.locationManager = locationManager
            locationManager.staleMonitoredRegions = []
            let location = CLLocation(latitude: 40.7, longitude: -74.0)

            for _ in 0..<3 {
                invokeReplaceBubbleGeofence(on: manager, location: location, radius: 100)
            }

            let bubbleRegions = locationManager.trackedRegions.filter { $0.identifier.hasPrefix("radar_bubble_") }
            #expect(bubbleRegions.count == 1)
        }

        @Test("Objective-C removeBubbleGeofence removes the last registered bubble while monitoredRegions is stale")
        func objCRemoveBubbleGeofenceRemovesLastRegisteredBubble() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let locationManager = TrackingCLLocationManager()
            defer {
                manager.locationManager = originalLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            RadarSettings.tracking = true
            manager.locationManager = locationManager
            locationManager.staleMonitoredRegions = []

            invokeReplaceBubbleGeofence(on: manager, location: CLLocation(latitude: 40.7, longitude: -74.0), radius: 100)
            invokeRemoveBubbleGeofence(on: manager)

            #expect(locationManager.trackedRegions.isEmpty)
        }

        @Test("A second Objective-C stopUpdates is a no-op once the timer is invalidated")
        func objCStopUpdatesTwiceStopsOnce() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let originalLowPowerLocationManager = manager.lowPowerLocationManager
            let locationManager = TrackingCLLocationManager()
            defer {
                manager.perform(NSSelectorFromString("cancelPendingShutdown"))
                manager.locationManager = originalLocationManager
                manager.lowPowerLocationManager = originalLowPowerLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            manager.locationManager = locationManager
            manager.lowPowerLocationManager = TrackingCLLocationManager()

            invokeStartUpdates(on: manager, interval: 10, blueBar: false)
            invokeStopUpdates(on: manager)
            invokeStopUpdates(on: manager)

            // One call from startUpdates (no blue bar) and one from the first stopUpdates.
            #expect(locationManager.stopUpdatingLocationCallCount == 2)
        }

        @Test("Objective-C updateTracking stops a running timer when updates should no longer start")
        func objCUpdateTrackingStopsTimerWhenUpdatesShouldNotStart() async throws {
            // The Objective-C body reads the real authorization status. Under Always, updates
            // should keep running, so this scenario doesn't apply.
            try #require(CLLocationManager.authorizationStatus() != .authorizedAlways)

            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let originalLowPowerLocationManager = manager.lowPowerLocationManager
            defer {
                invokeStopUpdates(on: manager)
                manager.perform(NSSelectorFromString("cancelPendingShutdown"))
                manager.locationManager = originalLocationManager
                manager.lowPowerLocationManager = originalLowPowerLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            RadarSettings.tracking = true
            manager.locationManager = TrackingCLLocationManager()
            manager.lowPowerLocationManager = TrackingCLLocationManager()

            let blueBarOptions = RadarTrackingOptions()
            blueBarOptions.desiredMovingUpdateInterval = 30
            blueBarOptions.desiredStoppedUpdateInterval = 30
            blueBarOptions.showBlueBar = true
            RadarSettings.trackingOptions = blueBarOptions
            manager.updateTracking()
            await drainMainQueue()
            #expect(manager.value(forKey: "started") as? Bool == true)

            let noBlueBarOptions = RadarTrackingOptions()
            noBlueBarOptions.desiredMovingUpdateInterval = 30
            noBlueBarOptions.desiredStoppedUpdateInterval = 30
            RadarSettings.trackingOptions = noBlueBarOptions
            manager.updateTracking()
            await drainMainQueue()

            #expect(manager.value(forKey: "started") as? Bool == false)
            #expect((manager.value(forKey: "timer") as? Timer)?.isValid == false)
        }
    }
}
