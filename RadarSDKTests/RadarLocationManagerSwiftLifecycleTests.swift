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

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftLifecycleTests {

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
    }
}
