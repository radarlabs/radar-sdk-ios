//
//  RadarLocationManager+SwiftLocation.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Swift port of `handleLocation:source:beacons:` in RadarLocationManager.m. It decides whether a
// location updates the stopped state and whether it is sent to the server. Sending stays in
// Objective-C behind the host's `sendLocation` until that method is ported.
extension RadarLocationManagerSwift {

    @objc(handleLocationWithHost:location:source:beacons:)
    static func handleLocation(  // swiftlint:disable:this cyclomatic_complexity function_body_length
        host: RadarLocationManagerSwiftHost,
        location: CLLocation,
        source: RadarLocationSource,
        beacons: [RadarBeacon]?
    ) {
        let sourceString = Radar.stringForLocationSource(source)
        RadarLogger.shared.debug("🦅 Handling location | source = \(sourceString); location = \(location)")

        let bypassDeviceLocationState = shouldBypassDeviceLocationState(for: source)

        if !bypassDeviceLocationState {
            host.cancelTimeouts()
        }

        guard location.isValid else {
            RadarLogger.shared.debug("🦅 Invalid location | source = \(sourceString); location = \(location)")
            host.callCompletionHandlers(status: .errorLocation, location: nil)
            return
        }

        let bridge = RadarSwift.bridge
        let options = Radar.getTrackingOptions()
        let wasStopped = bridge?.isStopped() ?? false
        var stopped = false

        let force =
            source == .foregroundLocation || source == .manualLocation
            || (options.syncLocations != .events
                && (source == .beaconEnter || source == .beaconExit || source == .visitArrival))
        if !bypassDeviceLocationState && wasStopped && !force && location.horizontalAccuracy >= 1000
            && options.desiredAccuracy != .low
        {
            RadarLogger.shared.debug("🦅 Skipping location: inaccurate | accuracy = \(location.horizontalAccuracy)")
            host.updateTracking(location)
            return
        }

        if !force && !RadarSettings.tracking {
            RadarLogger.shared.debug("🦅 Skipping location: not tracking")
            return
        }

        var distance = CLLocationDistanceMax
        if bypassDeviceLocationState {
            // Indoor updates carry the last device fix only as request metadata. Keep the device's
            // movement state until Core Location gives us a new fix.
            stopped = wasStopped
        } else if options.stopDistance > 0 && options.stopDuration > 0 {
            var lastMovedLocation = bridge?.lastMovedLocation()
            if lastMovedLocation == nil {
                lastMovedLocation = location
                bridge?.setLastMovedLocation(location)
            }
            var lastMovedAt = bridge?.lastMovedAt()
            if lastMovedAt == nil {
                lastMovedAt = location.timestamp
                bridge?.setLastMovedAt(location.timestamp)
            }
            if let lastMovedLocation, let lastMovedAt {
                if !force && lastMovedAt.timeIntervalSince(location.timestamp) > 0 {
                    RadarLogger.shared.debug(
                        "🦅 Skipping location: old | lastMovedAt = \(lastMovedAt); location.timestamp = \(location.timestamp)"
                    )
                    return
                }

                distance = location.distance(from: lastMovedLocation)
                var duration = location.timestamp.timeIntervalSince(lastMovedAt)
                if duration == 0 {
                    duration = -location.timestamp.timeIntervalSinceNow
                }
                let arrival = source == .visitArrival
                stopped =
                    (distance <= CLLocationDistance(options.stopDistance)
                        && duration >= TimeInterval(options.stopDuration)) || arrival

                RadarLogger.shared.debug(
                    "🦅 Calculating stopped | stopped = \(stopped); arrival = \(arrival); distance = \(distance); "
                        + "duration = \(duration); location.timestamp = \(location.timestamp); lastMovedAt = \(lastMovedAt)"
                )

                if distance > CLLocationDistance(options.stopDistance) {
                    bridge?.setLastMovedLocation(location)

                    if !stopped {
                        bridge?.setLastMovedAt(location.timestamp)
                    }
                }
            }
        } else {
            stopped = force || source == .visitArrival
        }

        let justStopped = stopped && !wasStopped
        if !bypassDeviceLocationState {
            bridge?.setStopped(stopped)
            bridge?.setLastLocation(location)
            bridge?.didUpdateClientLocation(location, stopped: stopped, source: source)

            if source != .manualLocation {
                host.updateTracking(location)
            }

            host.callCompletionHandlers(status: .success, location: location)
        }

        let sdkConfiguration = RadarSettings.sdkConfiguration
        if !bypassDeviceLocationState && sdkConfiguration?.useSyncRegion == true {
            if !RadarSyncManager.hasSyncedRegion() {
                RadarSyncManager.fetchSyncRegion()
            } else if sdkConfiguration?.offlineEventGenerationEnabled == true
                && (RadarSyncManager.isOutsideSyncedRegion(location: location)
                    || RadarSyncManager.isNearSyncedRegionBoundary(location: location))
            {
                RadarSyncManager.fetchSyncRegion()
            }
        }

        var sendLocation = location
        var replayed = false
        if !bypassDeviceLocationState && options.replay == .stops && !justStopped,
            let lastFailedStoppedLocation = bridge?.lastFailedStoppedLocation()
        {
            sendLocation = lastFailedStoppedLocation
            stopped = true
            replayed = true
            bridge?.setLastFailedStoppedLocation(nil)

            RadarLogger.shared.debug("🦅 Replaying location | location = \(sendLocation); stopped = \(stopped)")
        }

        let lastSentAt = bridge?.lastSentAt()
        let ignoreSync =
            lastSentAt == nil || host.completionHandlerCount() > 0 || justStopped || replayed
            || source == .beaconEnter || source == .beaconExit
        if !ignoreSync, let lastSentAt {
            let lastSyncInterval = Date().timeIntervalSince(lastSentAt)

            if !bypassDeviceLocationState && !force && stopped && wasStopped
                && distance <= CLLocationDistance(options.stopDistance)
                && (options.desiredStoppedUpdateInterval == 0
                    || (options.syncLocations != .all && options.syncLocations != .events))
            {
                RadarLogger.shared.debug("🦅 Skipping sync: already stopped | stopped = \(stopped); wasStopped = \(wasStopped)")
                return
            }

            // add a 0.1 second buffer to account for the fact that the timer may fire slightly before the desired interval
            let lastSyncIntervalWithBuffer = lastSyncInterval + 0.1
            if lastSyncIntervalWithBuffer < TimeInterval(options.desiredSyncInterval) {
                RadarLogger.shared.debug(
                    "🦅 Skipping sync: desired sync interval | desiredSyncInterval = \(options.desiredSyncInterval); "
                        + "lastSyncInterval = \(lastSyncIntervalWithBuffer)"
                )
                return
            }

            if !force && !justStopped && lastSyncInterval < 1 {
                RadarLogger.shared.debug(
                    "🦅 Skipping sync: rate limit | justStopped = \(justStopped); lastSyncInterval = \(lastSyncInterval)"
                )
                return
            }

            let syncLocationsString = RadarTrackingOptions.string(for: options.syncLocations)
            if options.syncLocations == .none {
                RadarLogger.shared.debug("🦅 Skipping sync: sync mode | sync = \(syncLocationsString)")
                return
            }

            let canExit = bridge?.canExit() ?? false
            if !canExit && options.syncLocations == .stopsAndExits {
                RadarLogger.shared.debug("🦅 Skipping sync: can't exit | sync = \(syncLocationsString); canExit = \(canExit)")
                return
            }
        }

        if !bypassDeviceLocationState && source != .foregroundLocation && source != .manualLocation
            && sdkConfiguration?.useSyncRegion == true && options.syncLocations == .events
        {
            if location.horizontalAccuracy >= 1000 && options.desiredAccuracy != .low {
                RadarLogger.shared.info(
                    "🦅 Skipping sync region eval: inaccurate | accuracy = \(location.horizontalAccuracy)"
                )
                return
            }

            if RadarSyncManager.shouldTrack(location: location, options: options) {
                bridge?.updateLastSentAt()
                host.sendLocation(
                    sendLocation, stopped: stopped, source: source, replayed: replayed, beacons: beacons, forceTrack: true)
                return
            }

            if options.beacons {
                host.sendLocation(
                    sendLocation, stopped: stopped, source: source, replayed: replayed, beacons: beacons, forceTrack: false)
                return
            }

            RadarLogger.shared.info("🦅 Skipping track: useSyncRegion - no state change detected | source = \(sourceString)")
            return
        }

        bridge?.updateLastSentAt()

        if source == .foregroundLocation {
            return
        }

        host.sendLocation(
            sendLocation, stopped: stopped, source: source, replayed: replayed, beacons: beacons, forceTrack: true)
    }
}
