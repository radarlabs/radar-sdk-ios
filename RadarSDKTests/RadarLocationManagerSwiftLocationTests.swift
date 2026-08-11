//
//  RadarLocationManagerSwiftLocationTests.swift
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
    actor RadarLocationManagerSwiftLocationTests {

        // MARK: - didUpdateLocations(_:completionHandlerCount:)

        @Test("location updates with no locations are ignored")
        func locationUpdatesIgnoreEmptyUpdates() {
            let mock = MockRadarSwiftBridge()
            let original = RadarSwift.bridge
            RadarSwift.bridge = mock
            defer { RadarSwift.bridge = original }

            RadarLocationManagerSwift.didUpdateLocations([], completionHandlerCount: 1)

            #expect(mock.lastHandledLocation == nil)
        }

        @Test("location updates requested by a completion handler use the foreground source when the foreground check is skipped")
        func locationUpdatesUseForegroundSourceWhenForegroundCheckIsSkipped() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let mock = MockRadarSwiftBridge()
            let original = RadarSwift.bridge
            RadarSwift.bridge = mock
            defer {
                RadarSwift.bridge = original
                RadarLocationManagerSwiftTestHelpers.clearState()
            }
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["skipForegroundCheck": true])
            let location = CLLocation(latitude: 40.7, longitude: -74.0)

            RadarLocationManagerSwift.didUpdateLocations([location], completionHandlerCount: 1)

            #expect(mock.lastHandledLocation === location)
            #expect(mock.lastHandledSource == .foregroundLocation)
        }

        @Test("location updates requested in the foreground use the foreground source")
        func locationUpdatesUseForegroundSourceWhenAppIsForeground() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let mock = MockRadarSwiftBridge()
            mock.mockIsForeground = true
            let original = RadarSwift.bridge
            RadarSwift.bridge = mock
            defer {
                RadarSwift.bridge = original
                RadarLocationManagerSwiftTestHelpers.clearState()
            }
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["skipForegroundCheck": false])

            let location = CLLocation(latitude: 40.7, longitude: -74.0)
            RadarLocationManagerSwift.didUpdateLocations([location], completionHandlerCount: 1)

            #expect(mock.lastHandledLocation === location)
            #expect(mock.lastHandledSource == .foregroundLocation)
        }

        @Test("tracked location updates use the background source")
        func trackedLocationUpdatesUseBackgroundSource() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = true
            let mock = MockRadarSwiftBridge()
            let original = RadarSwift.bridge
            RadarSwift.bridge = mock
            defer { RadarSwift.bridge = original }
            let location = CLLocation(latitude: 40.7, longitude: -74.0)

            RadarLocationManagerSwift.didUpdateLocations([location], completionHandlerCount: 0)

            #expect(mock.lastHandledLocation === location)
            #expect(mock.lastHandledSource == .backgroundLocation)
        }

        @Test("untracked background location updates are ignored")
        func untrackedBackgroundLocationUpdatesAreIgnored() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            RadarSettings.tracking = false
            let mock = MockRadarSwiftBridge()
            let original = RadarSwift.bridge
            RadarSwift.bridge = mock
            defer { RadarSwift.bridge = original }

            RadarLocationManagerSwift.didUpdateLocations([CLLocation(latitude: 40.7, longitude: -74.0)], completionHandlerCount: 0)

            #expect(mock.lastHandledLocation == nil)
        }

        // MARK: - effectiveLocation(for:)

        @Test("effectiveLocation prefers the manager's current valid location")
        func effectiveLocationPrefersValidManagerLocation() {
            let mock = MockRadarSwiftBridge()
            mock.mockLastLocation = CLLocation(latitude: 10, longitude: 10)
            let original = RadarSwift.bridge
            RadarSwift.bridge = mock
            defer { RadarSwift.bridge = original }

            let locationManager = TrackingCLLocationManager()
            let validLocation = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 40, longitude: -70),
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                timestamp: Date(timeIntervalSince1970: 0)
            )
            locationManager.mockLocation = validLocation

            let result = RadarLocationManagerSwift.effectiveLocation(for: locationManager)

            #expect(result === validLocation)
        }

        @Test("effectiveLocation falls back to the last known location when the manager's location is missing")
        func effectiveLocationFallsBackWhenManagerLocationMissing() {
            let mock = MockRadarSwiftBridge()
            let fallbackLocation = CLLocation(latitude: 10, longitude: 10)
            mock.mockLastLocation = fallbackLocation
            let original = RadarSwift.bridge
            RadarSwift.bridge = mock
            defer { RadarSwift.bridge = original }

            let locationManager = TrackingCLLocationManager()
            locationManager.mockLocation = nil

            let result = RadarLocationManagerSwift.effectiveLocation(for: locationManager)

            #expect(result === fallbackLocation)
        }

        @Test("effectiveLocation falls back to the last known location when the manager's location is invalid")
        func effectiveLocationFallsBackWhenManagerLocationInvalid() {
            let mock = MockRadarSwiftBridge()
            let fallbackLocation = CLLocation(latitude: 10, longitude: 10)
            mock.mockLastLocation = fallbackLocation
            let original = RadarSwift.bridge
            RadarSwift.bridge = mock
            defer { RadarSwift.bridge = original }

            let locationManager = TrackingCLLocationManager()
            // (0, 0) with zero accuracy fails `CLLocation.isValid`.
            locationManager.mockLocation = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date(timeIntervalSince1970: 0)
            )

            let result = RadarLocationManagerSwift.effectiveLocation(for: locationManager)

            #expect(result === fallbackLocation)
        }

    }
}
