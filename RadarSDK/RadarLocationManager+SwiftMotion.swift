//
//  RadarLocationManager+SwiftMotion.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import CoreMotion
import Foundation

// Swift port of `startMotionUpdatesWithOptions:` in RadarLocationManager.m. With `useMotion`, it
// starts heading updates and stores each new motion activity, then starts a track. With
// `usePressure`, it stores relative and absolute altitude data. The Objective-C
// `RadarActivityManager` still reads Core Motion, through the host.
extension RadarLocationManagerSwift {

    /// Mirror of the heading filter in RadarLocationManager.m. Kept in sync by hand until that file
    /// is fully ported.
    private static let motionHeadingFilter: CLLocationDegrees = 5

    /// Starts a track after the motion activity changes. Tests replace it so they don't call the track API.
    nonisolated(unsafe) static var trackOnceAfterActivityChange: () -> Void = {
        Radar.trackOnce(completionHandler: nil)
    }

    static func startMotionUpdates(host: RadarLocationManagerSwiftHost, options: RadarTrackingOptions) {
        if options.useMotion {
            let locationManager = host.locationManager
            locationManager.headingFilter = motionHeadingFilter
            locationManager.startUpdatingHeading()

            host.startActivityUpdates { activity in
                recordMotionActivity(activity, options: options)
            }
        }

        if options.usePressure {
            let authorization = RadarSwift.bridge?.motionAuthorizationString()
            RadarState.shared.motionAuthorizationString = authorization
            let authorizationDescription = authorization ?? "unknown"

            RadarLogger.shared.debug(
                "🦅 usePressure enabled: starting relative altitude updates, auth status: \(authorizationDescription)")
            host.startRelativeAltitude { altitudeData in
                recordRelativeAltitude(altitudeData)
            }

            RadarLogger.shared.debug(
                "🦅 usePressure enabled: starting absolute altitude updates (iOS 15+), auth status: \(authorizationDescription)"
            )
            host.startAbsoluteAltitude { altitudeData in
                recordAbsoluteAltitude(altitudeData)
            }
        }
    }

    static func activityType(for activity: CMMotionActivity) -> RadarActivityType {
        if activity.stationary {
            return .stationary
        }
        if activity.walking || activity.running {
            return .foot
        }
        if activity.automotive {
            return .car
        }
        if activity.cycling {
            return .bike
        }
        return .unknown
    }

    /// Stores a new motion activity and starts a track. It skips unknown activities and activities
    /// of the same type as the last one.
    static func recordMotionActivity(_ activity: CMMotionActivity, options: RadarTrackingOptions) {
        let activityType = activityType(for: activity)
        guard activityType != .unknown else {
            return
        }

        let type = Radar.stringForActivityType(activityType)
        let state = RadarState.shared
        if let previousType = state.lastMotionActivityData?["type"] as? String, previousType == type {
            return
        }

        state.lastMotionActivityData = [
            "type": type,
            "timestamp": activity.startDate.timeIntervalSince1970,
            "confidence": activity.confidence.rawValue,
        ]

        if options.syncLocations != .events {
            RadarLogger.shared.debug("🦅 Activity detected, initiating trackOnce")
            trackOnceAfterActivityChange()
        }
    }

    static func recordRelativeAltitude(_ altitudeData: CMAltitudeData?) {
        guard let altitudeData else {
            RadarLogger.shared.warning("🦅 Relative altitude callback received nil data")
            return
        }

        // Core Motion gives the pressure in kPa. Store it in hPa.
        let pressure = altitudeData.pressure.doubleValue * 10
        let relativeAltitude = altitudeData.relativeAltitude.doubleValue

        let state = RadarState.shared
        var altitude = state.lastRelativeAltitudeData ?? [:]
        altitude["pressure"] = pressure
        altitude["relativeAltitude"] = relativeAltitude
        altitude["relativeAltitudeTimestamp"] = Date().timeIntervalSince1970
        state.lastRelativeAltitudeData = altitude

        RadarLogger.shared.debug(
            "🦅 Stored relative altitude: pressure=\(String(format: "%.1f", pressure)) hPa, "
                + "relative=\(String(format: "%.3f", relativeAltitude)) m"
        )
    }

    static func recordAbsoluteAltitude(_ altitudeData: CMAbsoluteAltitudeData?) {
        guard let altitudeData else {
            RadarLogger.shared.warning("🦅 Absolute altitude callback received nil data")
            return
        }

        let state = RadarState.shared
        var altitude = state.lastRelativeAltitudeData ?? [:]
        altitude["altitude"] = altitudeData.altitude
        altitude["accuracy"] = altitudeData.accuracy
        altitude["precision"] = altitudeData.precision
        altitude["absoluteAltitudeTimestamp"] = Date().timeIntervalSince1970
        state.lastRelativeAltitudeData = altitude

        RadarLogger.shared.debug(
            "🦅 Stored absolute altitude: altitude=\(String(format: "%.3f", altitudeData.altitude)) m, "
                + "accuracy=\(String(format: "%.3f", altitudeData.accuracy)) m, "
                + "precision=\(String(format: "%.3f", altitudeData.precision)) m"
        )
    }
}
