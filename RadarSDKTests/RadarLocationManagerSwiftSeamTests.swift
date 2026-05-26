//
//  RadarLocationManagerSwiftSeamTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite(.serialized)
actor RadarLocationManagerSwiftSeamTests {

    private func clearState() {
        RadarSettings.previousTrackingOptions = nil
        RadarSettings.sdkConfiguration = nil
    }

    @Test("Swift twin clears previousTrackingOptions when there are none to restart")
    func swiftTwinClearsPreviousTrackingOptionsWhenNone() {
        clearState()
        defer { clearState() }

        RadarLocationManagerSwift.restartPreviousTrackingOptions()

        #expect(RadarSettings.previousTrackingOptions == nil)
    }

    @Test("Swift twin clears previousTrackingOptions after restarting tracking")
    func swiftTwinClearsPreviousTrackingOptionsAfterRestart() {
        clearState()
        defer { clearState() }

        RadarSettings.previousTrackingOptions = RadarTrackingOptions.presetResponsive

        RadarLocationManagerSwift.restartPreviousTrackingOptions()

        #expect(RadarSettings.previousTrackingOptions == nil)
    }

    @Test("Public method routes to Swift twin when useSwiftLocationManager is enabled")
    func publicMethodRoutesToSwiftTwinWhenFlagEnabled() {
        clearState()
        defer { clearState() }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useSwiftLocationManager": true
        ])
        RadarSettings.previousTrackingOptions = RadarTrackingOptions.presetResponsive

        RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

        #expect(RadarSettings.previousTrackingOptions == nil)
    }

    @Test("Public method uses ObjC body when useSwiftLocationManager is disabled")
    func publicMethodUsesObjCBodyWhenFlagDisabled() {
        clearState()
        defer { clearState() }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "useSwiftLocationManager": false
        ])
        RadarSettings.previousTrackingOptions = RadarTrackingOptions.presetResponsive

        RadarLocationManager.sharedInstance().restartPreviousTrackingOptions()

        #expect(RadarSettings.previousTrackingOptions == nil)
    }
}
