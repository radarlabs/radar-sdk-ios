//
//  RadarLocationManagerSwiftSeamTests.swift
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
    actor RadarLocationManagerSwiftSeamTests {

        // MARK: - startTracking(options:)

        @Test("start tracking reports a permissions error without changing state when unauthorized")
        @MainActor
        func startTrackingRejectsUnauthorizedStatus() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies(authorizationStatus: .denied) { bridge in
                let existingOptions = RadarTrackingOptions.presetContinuous
                RadarSettings.trackingOptions = existingOptions

                RadarLocationManagerSwift.startTracking(options: .presetResponsive)

                #expect(bridge.lastFailStatus == .errorPermissions)
                #expect(bridge.updateTrackingCallCount == 0)
                #expect(RadarSettings.tracking == false)
                #expect(RadarSettings.trackingOptions == existingOptions)
            }
        }

        @Test(arguments: [CLAuthorizationStatus.authorizedWhenInUse, .authorizedAlways])
        @MainActor
        func startTrackingAcceptsAuthorizedStatus(authorizationStatus: CLAuthorizationStatus) {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies(authorizationStatus: authorizationStatus) { bridge in
                let options = RadarTrackingOptions.presetResponsive

                RadarLocationManagerSwift.startTracking(options: options)

                #expect(bridge.lastFailStatus == nil)
                #expect(bridge.updateTrackingCallCount == 1)
                #expect(RadarSettings.tracking == true)
                #expect(RadarSettings.trackingOptions == options)
            }
        }

        @Test("public start tracking method routes to the Swift twin when enabled")
        @MainActor
        func publicStartTrackingRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies(authorizationStatus: .denied) { bridge in
                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                    "useSwiftLocationManager": true
                ])

                RadarLocationManager.sharedInstance().startTracking(with: .presetResponsive)

                #expect(bridge.lastFailStatus == .errorPermissions)
                #expect(bridge.updateTrackingCallCount == 0)
                #expect(RadarSettings.tracking == false)
            }
        }

        // MARK: - restartPreviousTrackingOptions — Swift twin

        @Test("Swift twin calls Radar.stopTracking and clears previousTrackingOptions when none to restart")
        func swiftTwinStopsTrackingWhenNoPreviousOptions() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            // Seed `tracking = true` to observe that `Radar.stopTracking()` actually flipped it off.
            RadarSettings.tracking = true

            RadarLocationManagerSwift.restartPreviousTrackingOptions()

            #expect(RadarSettings.previousTrackingOptions == nil)
            #expect(RadarSettings.tracking == false)
        }

        @Test("Swift twin restarts tracking with previous options and clears previousTrackingOptions")
        @MainActor
        func swiftTwinRestartsTrackingAndClearsPreviousOptions() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                    "useSwiftLocationManager": true
                ])
                let previousOptions = RadarTrackingOptions.presetResponsive
                RadarSettings.previousTrackingOptions = previousOptions

                RadarLocationManagerSwift.restartPreviousTrackingOptions()

                #expect(RadarSettings.previousTrackingOptions == nil)
                #expect(RadarSettings.tracking == true)
                #expect(RadarSettings.trackingOptions == previousOptions)
                #expect(bridge.updateTrackingCallCount == 1)
            }
        }

        // MARK: - restartPreviousTrackingOptions — public method routing

        @Test("Public method routes to Swift twin when useSwiftLocationManager is enabled")
        @MainActor
        func publicMethodRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                    "useSwiftLocationManager": true
                ])
                let previousOptions = RadarTrackingOptions.presetResponsive
                RadarSettings.previousTrackingOptions = previousOptions

                RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

                #expect(RadarSettings.previousTrackingOptions == nil)
                #expect(RadarSettings.tracking == true)
                #expect(RadarSettings.trackingOptions == previousOptions)
                #expect(bridge.updateTrackingCallCount == 1)
            }
        }

        @Test("Public method uses ObjC body when useSwiftLocationManager is disabled")
        func publicMethodUsesObjCBodyWhenFlagDisabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarLocationManagerSwiftTestHelpers.installAuthorizedPermissions()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useSwiftLocationManager": false
            ])
            let previousOptions = RadarTrackingOptions.presetResponsive
            RadarSettings.previousTrackingOptions = previousOptions

            RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

            // ObjC body should land in the same end state as the Swift twin.
            #expect(RadarSettings.previousTrackingOptions == nil)
            #expect(RadarSettings.tracking == true)
            #expect(RadarSettings.trackingOptions == previousOptions)
        }

        // MARK: - Beacon sync — public method routing

        @Test("Public replaceSyncedBeacons routes to Swift twin when flag enabled")
        func publicReplaceSyncedBeaconsRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            // useRadarModifiedBeacon on so the Swift twin short-circuits — exercises only
            // that the dispatch shim routes to the Swift implementation, not the body.
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useSwiftLocationManager": true,
                "useRadarModifiedBeacon": true,
            ])

            RadarLocationManager.sharedInstance().replaceSyncedBeacons([])
        }
    }
}
