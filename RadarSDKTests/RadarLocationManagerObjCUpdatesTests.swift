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

private struct ObjCStartUpdatesResult {
    let locationManager: TrackingCLLocationManager
    /// The number of different timers that the `startUpdates:blueBar:` calls made.
    let timerCount: Int
    let startedContinuousUpdates: Bool?
}

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerObjCUpdatesTests {
        /// Calls `startUpdates:blueBar:` once for each entry in `starts` on the shared manager with
        /// tracking location managers, then restores the manager.
        private func startUpdates(_ starts: [(interval: Int32, blueBar: Bool)]) -> ObjCStartUpdatesResult {
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
                manager.setValue(false, forKey: "startedContinuousUpdates")
                manager.locationManager = originalLocationManager
                manager.lowPowerLocationManager = originalLowPowerLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            manager.setValue(false, forKey: "started")
            manager.setValue(false, forKey: "startedContinuousUpdates")
            manager.locationManager = locationManager
            manager.lowPowerLocationManager = lowPowerLocationManager

            var timers: [Timer] = []
            for start in starts {
                invokeStartUpdates(on: manager, interval: start.interval, blueBar: start.blueBar)
                if let timer = manager.value(forKey: "timer") as? Timer, !timers.contains(where: { $0 === timer }) {
                    timers.append(timer)
                }
            }
            #expect(timers.dropLast().allSatisfy { !$0.isValid })

            return ObjCStartUpdatesResult(
                locationManager: locationManager,
                timerCount: timers.count,
                startedContinuousUpdates: manager.value(forKey: "startedContinuousUpdates") as? Bool
            )
        }

        @Test("Objective-C startUpdates restarts updates when a blueBar change turns off continuous updates")
        func objCStartUpdatesRestartsWhenContinuousUpdatesChange() {
            let result = startUpdates([(5, true), (5, false)])

            #expect(result.timerCount == 2)
            #expect(result.startedContinuousUpdates == false)
            #expect(result.locationManager.startUpdatingLocationCallCount == 1)
            #expect(result.locationManager.stopUpdatingLocationCallCount == 1)
        }

        @Test("Objective-C startUpdates restarts updates when a blueBar change turns on continuous updates")
        func objCStartUpdatesRestartsWhenContinuousUpdatesStart() {
            let result = startUpdates([(5, false), (5, true)])

            #expect(result.timerCount == 2)
            #expect(result.startedContinuousUpdates == true)
            #expect(result.locationManager.stopUpdatingLocationCallCount == 1)
            #expect(result.locationManager.startUpdatingLocationCallCount == 1)
        }

        @Test("Objective-C startUpdates keeps the timer when a blueBar change does not change continuous updates")
        func objCStartUpdatesKeepsTimerWhenContinuousUpdatesDoNotChange() {
            let result = startUpdates([(10, false), (10, true)])

            #expect(result.timerCount == 1)
            #expect(result.startedContinuousUpdates == false)
            #expect(result.locationManager.startUpdatingLocationCallCount == 0)
            #expect(result.locationManager.stopUpdatingLocationCallCount == 1)
        }
    }
}
