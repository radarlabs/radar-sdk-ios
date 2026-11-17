//
//  RadarLocationManager+SwiftMotion.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import CoreMotion
import Foundation

/// Moves the location manager and the activity manager to the main actor. Both are only used there.
private struct RadarMotionStopBox: @unchecked Sendable {
    let locationManager: CLLocationManager
    let activityManager: RadarActivityManager?
}

// Swift port of `startMotionUpdatesWithOptions:` in RadarLocationManager.m. With `useMotion`, it
// starts heading updates and stores each new motion activity, then starts a track. With
// `usePressure`, it stores relative and absolute altitude data. `RadarActivityManager` reads Core
// Motion.
extension RadarLocationManagerSwift {

    /// Mirror of the heading filter in RadarLocationManager.m. Kept in sync by hand until that file
    /// is fully ported.
    private static let motionHeadingFilter: CLLocationDegrees = 5

    /// Relative and absolute altitude updates arrive on different Core Motion queues. Both read,
    /// change, and write the same stored dictionary, so this lock keeps one from losing the other's keys.
    private static let altitudeLock = NSLock()

    /// Starts a track after the motion activity changes. Tests replace it so they don't call the track API.
    nonisolated(unsafe) static var trackOnceAfterActivityChange: () -> Void = {
        Radar.trackOnce(completionHandler: nil)
    }

    /// Stops each motion sensor that still runs but that `options` does not use. With nil `options`,
    /// for example when tracking is off, it stops every sensor that runs. Call it on the main thread.
    @objc(stopUnusedMotionUpdatesOnLocationManager:activityManager:options:)
    static func stopUnusedMotionUpdates(
        locationManager: CLLocationManager,
        activityManager: RadarActivityManager?,
        options: RadarTrackingOptions?
    ) {
        guard let activityManager else {
            return
        }
        if options?.useMotion != true, activityManager.isUpdatingActivity {
            RadarLogger.shared.debug("Stopping motion activity updates that the tracking options do not use")
            locationManager.stopUpdatingHeading()
            activityManager.stopActivityUpdates()
        }
        if options?.usePressure != true {
            if activityManager.isUpdatingPressure {
                RadarLogger.shared.debug("Stopping relative altitude updates that the tracking options do not use")
                activityManager.stopRelativeAltitudeUpdates()
            }
            if activityManager.isUpdatingAbsoluteAltitude {
                RadarLogger.shared.debug("Stopping absolute altitude updates that the tracking options do not use")
                activityManager.stopAbsoluteAltitudeUpdates()
            }
        }
    }

    /// Stops the motion sensors when tracking stops. It stops each sensor that the local or the
    /// remote tracking options use, and each sensor that still runs. Tracking starts the sensors
    /// from the remote options when they exist, so the local options alone can miss one.
    ///
    /// `RadarActivityManager` reads and writes its flags on the main thread, and apps can call
    /// `stopTracking` from any thread. Off the main thread, this runs later on the main actor.
    @objc(stopMotionUpdatesForStopTrackingOnLocationManager:activityManager:)
    static func stopMotionUpdatesForStopTracking(
        locationManager: CLLocationManager,
        activityManager: RadarActivityManager?
    ) {
        let localOptions = RadarSettings.trackingOptions ?? .presetEfficient
        let options = Radar.getTrackingOptions()
        let useMotion = localOptions.useMotion || options.useMotion
        let usePressure = localOptions.usePressure || options.usePressure
        let boxes = RadarMotionStopBox(locationManager: locationManager, activityManager: activityManager)

        let stop = {
            let locationManager = boxes.locationManager
            let activityManager = boxes.activityManager
            if useMotion || usePressure {
                locationManager.stopUpdatingHeading()
            }
            if let activityManager {
                if usePressure {
                    activityManager.stopRelativeAltitudeUpdates()
                    activityManager.stopAbsoluteAltitudeUpdates()
                }
                if useMotion {
                    activityManager.stopActivityUpdates()
                }
            }
            stopUnusedMotionUpdates(locationManager: locationManager, activityManager: activityManager, options: nil)
        }

        if Thread.isMainThread {
            stop()
        } else {
            Task { @MainActor in
                stop()
            }
        }
    }

    static func startMotionUpdates(host: RadarLocationManagerSwiftHost, options: RadarTrackingOptions) {
        guard options.useMotion || options.usePressure else {
            return
        }

        // Keep the activity manager on the host, so `stopTracking` stops the same instance. The host
        // only ever holds the shared instance, except in tests.
        let activityManager = host.activityManager as? RadarActivityManager ?? RadarActivityManager.shared
        host.activityManager = activityManager

        if options.useMotion {
            let locationManager = host.locationManager
            locationManager.headingFilter = motionHeadingFilter
            locationManager.startUpdatingHeading()

            activityManager.startActivityUpdates { activity in
                recordMotionActivity(activity, options: options)
            }
        }

        if options.usePressure {
            // Without the bridge (before `Radar.initialize`), keep the stored value instead of clearing it.
            let authorization = RadarSwift.bridge?.motionAuthorizationString()
            if let authorization {
                RadarState.shared.motionAuthorizationString = authorization
            }

            RadarLogger.shared.debug(
                "🦅 usePressure enabled: starting relative and absolute altitude updates, "
                    + "auth status: \(authorization ?? "unknown")")
            activityManager.startRelativeAltitude { altitudeData in
                recordRelativeAltitude(altitudeData)
            }
            activityManager.startAbsoluteAltitude { altitudeData in
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

        updateStoredAltitude { altitude in
            altitude["pressure"] = pressure
            altitude["relativeAltitude"] = relativeAltitude
            altitude["relativeAltitudeTimestamp"] = Date().timeIntervalSince1970
        }

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

        updateStoredAltitude { altitude in
            altitude["altitude"] = altitudeData.altitude
            altitude["accuracy"] = altitudeData.accuracy
            altitude["precision"] = altitudeData.precision
            altitude["absoluteAltitudeTimestamp"] = Date().timeIntervalSince1970
        }

        RadarLogger.shared.debug(
            "🦅 Stored absolute altitude: altitude=\(String(format: "%.3f", altitudeData.altitude)) m, "
                + "accuracy=\(String(format: "%.3f", altitudeData.accuracy)) m, "
                + "precision=\(String(format: "%.3f", altitudeData.precision)) m"
        )
    }

    /// Changes the stored altitude dictionary as one step, under `altitudeLock`.
    private static func updateStoredAltitude(_ change: (inout [String: Any]) -> Void) {
        altitudeLock.withLock {
            let state = RadarState.shared
            var altitude = state.lastRelativeAltitudeData ?? [:]
            change(&altitude)
            state.lastRelativeAltitudeData = altitude
        }
    }
}
