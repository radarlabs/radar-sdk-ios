//
//  RadarLocationManager+Swift.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

// Swift port of `RadarLocationManager` methods, added one at a time as the class
// migrates from Objective-C. Each method here has a twin in `RadarLocationManager.m`
// that dispatches to it when `useSwiftLocationManager` is enabled. When a method's
// Swift port is trusted, the ObjC body is deleted and the original method name takes
// over the call site. Until then, both implementations coexist.
//
// `RadarLocationManager.h` is a project-visibility header and is not in the framework's
// auto-synthesized Swift module, so we cannot extend `RadarLocationManager` from Swift.
// Static methods on this class are called from `RadarLocationManager.m` via
// `RadarSDK-Swift.h`. When a method needs state from the manager instance, pass it in
// via a small @objc protocol.
@objc(RadarLocationManagerSwift)
final class RadarLocationManagerSwift: NSObject {

    @objc static func restartPreviousTrackingOptions() {
        let previousTrackingOptions = RadarSettings.previousTrackingOptions
        RadarLogger.shared.debug("🦅 Restarting previous tracking options")

        if let previousTrackingOptions {
            Radar.startTracking(trackingOptions: previousTrackingOptions)
        } else {
            Radar.stopTracking()
        }

        RadarSettings.previousTrackingOptions = nil
    }
}
