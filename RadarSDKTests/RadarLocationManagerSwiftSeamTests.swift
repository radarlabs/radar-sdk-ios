//
//  RadarLocationManagerSwiftSeamTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftSeamTests {

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
        func swiftTwinRestartsTrackingAndClearsPreviousOptions() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            // Authorize location so `Radar.startTracking(trackingOptions:)` proceeds past the
            // permission gate in `RadarLocationManager.startTrackingWithOptions:`.
            RadarLocationManagerSwiftTestHelpers.installAuthorizedPermissions()
            let previousOptions = RadarTrackingOptions.presetResponsive
            RadarSettings.previousTrackingOptions = previousOptions

            RadarLocationManagerSwift.restartPreviousTrackingOptions()

            // Previous slot cleared, tracking is now active, and the live tracking options
            // equal the previous options — proving `Radar.startTracking(trackingOptions:)` was
            // called with the right argument.
            #expect(RadarSettings.previousTrackingOptions == nil)
            #expect(RadarSettings.tracking == true)
            #expect(RadarSettings.trackingOptions == previousOptions)
        }

        // MARK: - restartPreviousTrackingOptions — public method routing

        @Test("Public method routes to Swift twin when useSwiftLocationManager is enabled")
        func publicMethodRoutesToSwiftTwinWhenFlagEnabled() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarLocationManagerSwiftTestHelpers.installAuthorizedPermissions()
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
                "useSwiftLocationManager": true
            ])
            let previousOptions = RadarTrackingOptions.presetResponsive
            RadarSettings.previousTrackingOptions = previousOptions

            RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

            #expect(RadarSettings.previousTrackingOptions == nil)
            #expect(RadarSettings.tracking == true)
            #expect(RadarSettings.trackingOptions == previousOptions)
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
