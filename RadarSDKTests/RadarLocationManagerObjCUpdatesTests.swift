//
//  RadarLocationManagerObjCUpdatesTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

// Covers `startUpdates:blueBar:` in RadarLocationManager.m, the body that runs while
// `useSwiftLocationManager` is off. The Swift twin in RadarLocationManager+Swift.swift is
// covered by RadarLocationManagerSwiftLifecycleTests.

private func invokeStartUpdates(on manager: RadarLocationManager, interval: Int32, blueBar: Bool) {
    typealias StartUpdatesFunction = @convention(c) (AnyObject, Selector, Int32, Bool) -> Void

    let selector = NSSelectorFromString("startUpdates:blueBar:")
    guard let implementation = manager.method(for: selector) else {
        preconditionFailure("RadarLocationManager does not respond to startUpdates:blueBar:")
    }

    unsafeBitCast(implementation, to: StartUpdatesFunction.self)(manager, selector, interval, blueBar)
}

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerObjCUpdatesTests {
        /// Starts updates on the shared manager with tracking location managers, fires the timer
        /// once, and returns the number of `requestLocation` calls on the primary manager.
        private func requestLocationCountAfterTimerFires(interval: Int32, blueBar: Bool) -> Int {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let originalLowPowerLocationManager = manager.lowPowerLocationManager
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()
            defer {
                (manager.value(forKey: "timer") as? Timer)?.invalidate()
                manager.setValue(nil, forKey: "timer")
                manager.setValue(false, forKey: "started")
                manager.setValue(0, forKey: "startedInterval")
                manager.locationManager = originalLocationManager
                manager.lowPowerLocationManager = originalLowPowerLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            manager.setValue(false, forKey: "started")
            manager.locationManager = locationManager
            manager.lowPowerLocationManager = lowPowerLocationManager

            invokeStartUpdates(on: manager, interval: interval, blueBar: blueBar)

            let timer = manager.value(forKey: "timer") as? Timer
            #expect(timer != nil)
            timer?.fire()

            return locationManager.requestLocationCallCount
        }

        @Test("Objective-C startUpdates timer does not request a location while continuous updates run")
        func objCStartUpdatesTimerSkipsRequestDuringContinuousUpdates() {
            #expect(requestLocationCountAfterTimerFires(interval: 5, blueBar: true) == 0)
        }

        @Test("Objective-C startUpdates timer requests a location for a long blue-bar interval")
        func objCStartUpdatesTimerRequestsForLongBlueBarInterval() {
            #expect(requestLocationCountAfterTimerFires(interval: 10, blueBar: true) == 1)
        }

        @Test("Objective-C startUpdates timer requests a location without the blue bar")
        func objCStartUpdatesTimerRequestsWithoutBlueBar() {
            #expect(requestLocationCountAfterTimerFires(interval: 5, blueBar: false) == 1)
        }
    }
}
