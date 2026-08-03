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

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftLifecycleTests {

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
