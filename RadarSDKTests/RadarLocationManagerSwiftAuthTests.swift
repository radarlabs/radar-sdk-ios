//
//  RadarLocationManagerSwiftAuthTests.swift
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
    actor RadarLocationManagerSwiftAuthTests {

        // MARK: - didChangeAuthorizationStatus

        @Test("didChangeAuthorizationStatus persists the new status")
        func didChangeAuthorizationStatusStoresStatus() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer {
                RadarLocationManagerSwiftTestHelpers.clearState()
                RadarUserDefaults.set(nil, forKey: .LocationAuthorizationStatus)
            }
            RadarUserDefaults.set(nil, forKey: .LocationAuthorizationStatus)

            // Flags off so the authorized branch takes no tracking side effect.
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "trackOnceOnAppOpen": false,
                "startTrackingOnInitialize": false,
            ])

            RadarLocationManagerSwift.didChangeAuthorizationStatus(.authorizedWhenInUse)

            #expect(RadarState().locationAuthorizationStatus == .authorizedWhenInUse)
        }

        @Test("didChangeAuthorizationStatus is a no-op when status is unchanged")
        func didChangeAuthorizationStatusNoOpOnSameStatus() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer {
                RadarLocationManagerSwiftTestHelpers.clearState()
                RadarUserDefaults.set(nil, forKey: .LocationAuthorizationStatus)
            }

            // Seed the persisted status so the incoming status matches it.
            RadarState().locationAuthorizationStatus = .authorizedAlways

            // Flags on + authorized permissions: if the guard didn't early-return on the
            // unchanged status, this would start tracking.
            RadarLocationManagerSwiftTestHelpers.installAuthorizedPermissions()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "startTrackingOnInitialize": true
            ])

            RadarLocationManagerSwift.didChangeAuthorizationStatus(.authorizedAlways)

            #expect(RadarSettings.tracking == false)
        }

        @Test("didChangeAuthorizationStatus does not start tracking when config flags are off")
        func didChangeAuthorizationStatusNoTrackingWhenFlagsOff() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer {
                RadarLocationManagerSwiftTestHelpers.clearState()
                RadarUserDefaults.set(nil, forKey: .LocationAuthorizationStatus)
            }
            RadarUserDefaults.set(nil, forKey: .LocationAuthorizationStatus)

            RadarLocationManagerSwiftTestHelpers.installAuthorizedPermissions()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "trackOnceOnAppOpen": false,
                "startTrackingOnInitialize": false,
            ])

            RadarLocationManagerSwift.didChangeAuthorizationStatus(.authorizedAlways)

            #expect(RadarState().locationAuthorizationStatus == .authorizedAlways)
            #expect(RadarSettings.tracking == false)
        }

        @Test("didChangeAuthorizationStatus starts tracking when authorized with startTrackingOnInitialize")
        func didChangeAuthorizationStatusStartsTrackingOnInitialize() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer {
                RadarLocationManagerSwiftTestHelpers.clearState()
                RadarUserDefaults.set(nil, forKey: .LocationAuthorizationStatus)
            }
            RadarUserDefaults.set(nil, forKey: .LocationAuthorizationStatus)

            RadarLocationManagerSwiftTestHelpers.installAuthorizedPermissions()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "startTrackingOnInitialize": true
            ])

            // Baseline is notDetermined, so authorizedAlways is a real change.
            RadarLocationManagerSwift.didChangeAuthorizationStatus(.authorizedAlways)

            // Radar.startTracking flipped tracking on. (Radar.trackOnce also fires an async
            // network request; we assert only the synchronous local state, as the existing
            // restartPreviousTrackingOptions tests do.)
            #expect(RadarSettings.tracking == true)
        }
    }
}
