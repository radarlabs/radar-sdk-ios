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
        private static func uptime(age: TimeInterval) -> TimeInterval {
            ProcessInfo.processInfo.systemUptime - age
        }

        /// Calls `startUpdates:blueBar:` once for each entry in `starts` on the shared manager with
        /// tracking location managers, fires the last timer once, and returns the primary manager.
        /// `expectedTimerCount` is the number of different timers the calls must create; by default,
        /// each call replaces the timer.
        private func primaryManagerAfterTimerFires(
            starts: [(interval: Int32, blueBar: Bool)],
            lastUpdateAge: TimeInterval? = 1,
            expectedTimerCount: Int? = nil
        ) -> TrackingCLLocationManager {
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
                manager.setValue(0, forKey: "lastLocationUpdateUptime")
                manager.locationManager = originalLocationManager
                manager.lowPowerLocationManager = originalLowPowerLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            manager.setValue(false, forKey: "started")
            manager.setValue(false, forKey: "startedContinuousUpdates")
            manager.setValue(lastUpdateAge.map(Self.uptime(age:)) ?? 0, forKey: "lastLocationUpdateUptime")
            manager.locationManager = locationManager
            manager.lowPowerLocationManager = lowPowerLocationManager

            var timers: [Timer] = []
            for start in starts {
                invokeStartUpdates(on: manager, interval: start.interval, blueBar: start.blueBar)
                if let timer = manager.value(forKey: "timer") as? Timer, !timers.contains(where: { $0 === timer }) {
                    timers.append(timer)
                }
            }
            // Only the last timer stays valid.
            #expect(timers.count == (expectedTimerCount ?? starts.count))
            #expect(timers.dropLast().allSatisfy { !$0.isValid })

            let timer = manager.value(forKey: "timer") as? Timer
            #expect(timer != nil)
            timer?.fire()

            return locationManager
        }

        private func requestLocationCountAfterTimerFires(interval: Int32, blueBar: Bool, lastUpdateAge: TimeInterval? = 1) -> Int {
            primaryManagerAfterTimerFires(starts: [(interval, blueBar)], lastUpdateAge: lastUpdateAge).requestLocationCallCount
        }

        @Test("Objective-C startUpdates timer does not request a location while continuous updates run")
        func objCStartUpdatesTimerSkipsRequestDuringContinuousUpdates() {
            #expect(requestLocationCountAfterTimerFires(interval: 5, blueBar: true) == 0)
        }

        @Test("Objective-C startUpdates timer requests a location in continuous mode when updates are stale")
        func objCStartUpdatesTimerRequestsForStaleContinuousUpdates() {
            #expect(requestLocationCountAfterTimerFires(interval: 5, blueBar: true, lastUpdateAge: 30) == 1)
            #expect(requestLocationCountAfterTimerFires(interval: 5, blueBar: true, lastUpdateAge: nil) == 1)
        }

        @Test("Objective-C delegate records the update time only for the primary location manager")
        func objCDelegateRecordsPrimaryManagerUpdateTime() throws {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
            let originalLowPowerLocationManager = manager.lowPowerLocationManager
            let locationManager = TrackingCLLocationManager()
            let lowPowerLocationManager = TrackingCLLocationManager()
            defer {
                manager.setValue(0, forKey: "lastLocationUpdateUptime")
                manager.locationManager = originalLocationManager
                manager.lowPowerLocationManager = originalLowPowerLocationManager
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            manager.locationManager = locationManager
            manager.lowPowerLocationManager = lowPowerLocationManager
            manager.setValue(0, forKey: "lastLocationUpdateUptime")
            let location = CLLocation(latitude: 40.7, longitude: -74.0)
            let delegate: CLLocationManagerDelegate = manager

            delegate.locationManager?(lowPowerLocationManager, didUpdateLocations: [location])
            #expect(manager.value(forKey: "lastLocationUpdateUptime") as? TimeInterval == 0)

            delegate.locationManager?(locationManager, didUpdateLocations: [])
            #expect(manager.value(forKey: "lastLocationUpdateUptime") as? TimeInterval == 0)

            let before = ProcessInfo.processInfo.systemUptime
            delegate.locationManager?(locationManager, didUpdateLocations: [location])
            let recorded = try #require(manager.value(forKey: "lastLocationUpdateUptime") as? TimeInterval)
            #expect(recorded >= before)
            #expect(recorded <= ProcessInfo.processInfo.systemUptime)
        }

        @Test("Objective-C startUpdates restarts updates when a blueBar change turns off continuous updates")
        func objCStartUpdatesRestartsWhenContinuousUpdatesChange() {
            let locationManager = primaryManagerAfterTimerFires(starts: [(5, true), (5, false)])

            #expect(locationManager.startUpdatingLocationCallCount == 1)
            #expect(locationManager.stopUpdatingLocationCallCount == 1)
            #expect(locationManager.requestLocationCallCount == 1)
        }

        @Test("Objective-C startUpdates keeps the timer when a blueBar change does not change continuous updates")
        func objCStartUpdatesKeepsTimerWhenContinuousUpdatesDoNotChange() {
            let locationManager = primaryManagerAfterTimerFires(starts: [(10, false), (10, true)], expectedTimerCount: 1)

            #expect(locationManager.startUpdatingLocationCallCount == 0)
            #expect(locationManager.stopUpdatingLocationCallCount == 1)
            #expect(locationManager.requestLocationCallCount == 1)
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
