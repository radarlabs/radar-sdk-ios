//
//  RadarLocationManager+SwiftLocation.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Keep handleLocation's steps private to this file, next to the entry point that runs them in order.
// swiftlint:disable file_length

// Swift port of `handleLocation:source:beacons:` in RadarLocationManager.m. It decides whether a
// location updates the stopped state and whether it is sent to the server. Sending is in
// RadarLocationManager+SwiftSend.swift.
extension RadarLocationManagerSwift {

    @objc(handleLocationWithHost:location:source:beacons:)
    static func handleLocation(
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
        let context = HandledLocation(
            location: location,
            source: source,
            beacons: beacons,
            bypassDeviceLocationState: bypassDeviceLocationState,
            bridge: bridge
        )

        if isInaccurateWhileStopped(context) {
            RadarLogger.shared.debug("🦅 Skipping location: inaccurate | accuracy = \(location.horizontalAccuracy)")
            host.updateTracking(location)
            return
        }

        if !context.force && !RadarSettings.tracking {
            RadarLogger.shared.debug("🦅 Skipping location: not tracking")
            return
        }

        guard let movement = calculateMovement(context, bridge: bridge) else {
            return
        }

        if !bypassDeviceLocationState {
            recordDeviceLocation(context, movement: movement, host: host, bridge: bridge)
            refreshSyncRegionIfNeeded(context)
        }

        let outgoing = outgoingLocation(context, movement: movement, bridge: bridge)

        if shouldSkipSync(context, movement: movement, outgoing: outgoing, host: host, bridge: bridge) {
            return
        }

        if usesSyncRegionEvaluation(context) {
            evaluateSyncRegion(context, outgoing: outgoing, host: host, bridge: bridge)
            return
        }

        bridge?.updateLastSentAt()

        if source == .foregroundLocation {
            return
        }

        send(outgoing, context: context, host: host, forceTrack: true)
    }

    // MARK: - Classifying the location

    /// A fix of 1 km or worse can't move a stopped device unless low accuracy was requested.
    private static func isInaccurateWhileStopped(_ context: HandledLocation) -> Bool {
        !context.bypassDeviceLocationState && context.wasStopped && !context.force
            && context.location.horizontalAccuracy >= 1000 && context.options.desiredAccuracy != .low
    }

    // MARK: - Stop detection

    /// Returns `nil` when the location is older than the last recorded move and should be dropped.
    private static func calculateMovement(
        _ context: HandledLocation,
        bridge: RadarSwiftBridgeProtocol?
    ) -> LocationMovement? {
        if context.bypassDeviceLocationState {
            // Indoor updates carry the last device fix only as request metadata. Keep the device's
            // movement state until Core Location gives us a new fix.
            return LocationMovement(stopped: context.wasStopped, distance: CLLocationDistanceMax, wasStopped: context.wasStopped)
        }

        if context.options.stopDistance > 0 && context.options.stopDuration > 0 {
            return detectStop(context, bridge: bridge)
        }

        let stopped = context.force || context.source == .visitArrival
        return LocationMovement(stopped: stopped, distance: CLLocationDistanceMax, wasStopped: context.wasStopped)
    }

    /// The device is stopped once it stays within `stopDistance` of where it last moved for at
    /// least `stopDuration`, or when it arrives at a visit.
    private static func detectStop(
        _ context: HandledLocation,
        bridge: RadarSwiftBridgeProtocol?
    ) -> LocationMovement? {
        let location = context.location
        let options = context.options

        let lastMovedLocation: CLLocation
        if let storedLocation = bridge?.lastMovedLocation() {
            lastMovedLocation = storedLocation
        } else {
            lastMovedLocation = location
            bridge?.setLastMovedLocation(location)
        }
        let lastMovedAt: Date
        if let storedDate = bridge?.lastMovedAt() {
            lastMovedAt = storedDate
        } else {
            lastMovedAt = location.timestamp
            bridge?.setLastMovedAt(location.timestamp)
        }

        if !context.force && lastMovedAt.timeIntervalSince(location.timestamp) > 0 {
            RadarLogger.shared.debug(
                "🦅 Skipping location: old | lastMovedAt = \(lastMovedAt); location.timestamp = \(location.timestamp)"
            )
            return nil
        }

        let distance = location.distance(from: lastMovedLocation)
        var duration = location.timestamp.timeIntervalSince(lastMovedAt)
        if duration == 0 {
            duration = -location.timestamp.timeIntervalSinceNow
        }
        let arrival = context.source == .visitArrival
        let stopped =
            (distance <= CLLocationDistance(options.stopDistance) && duration >= TimeInterval(options.stopDuration))
            || arrival

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

        return LocationMovement(stopped: stopped, distance: distance, wasStopped: context.wasStopped)
    }

    // MARK: - Device state

    /// Stores the new device location and stopped state, then notifies the delegate, tracking, and
    /// any waiting location requests.
    private static func recordDeviceLocation(
        _ context: HandledLocation,
        movement: LocationMovement,
        host: RadarLocationManagerSwiftHost,
        bridge: RadarSwiftBridgeProtocol?
    ) {
        bridge?.setStopped(movement.stopped)
        bridge?.setLastLocation(context.location)
        bridge?.didUpdateClientLocation(context.location, stopped: movement.stopped, source: context.source)

        if context.source != .manualLocation {
            host.updateTracking(context.location)
        }

        host.callCompletionHandlers(status: .success, location: context.location)
    }

    /// Fetches the sync region when there isn't one yet, or when offline events are on and the
    /// device has left or is near the edge of the current one.
    private static func refreshSyncRegionIfNeeded(_ context: HandledLocation) {
        guard let sdkConfiguration = context.sdkConfiguration, sdkConfiguration.useSyncRegion else {
            return
        }

        if !RadarSyncManager.hasSyncedRegion() {
            RadarSyncManager.fetchSyncRegion()
        } else if sdkConfiguration.offlineEventGenerationEnabled
            && (RadarSyncManager.isOutsideSyncedRegion(location: context.location)
                || RadarSyncManager.isNearSyncedRegionBoundary(location: context.location))
        {
            RadarSyncManager.fetchSyncRegion()
        }
    }

    // MARK: - Replay

    /// Sends the last stopped location that failed to send, in place of this one, unless the
    /// device just stopped.
    private static func outgoingLocation(
        _ context: HandledLocation,
        movement: LocationMovement,
        bridge: RadarSwiftBridgeProtocol?
    ) -> OutgoingLocation {
        guard !context.bypassDeviceLocationState && context.options.replay == .stops && !movement.justStopped,
            let lastFailedStoppedLocation = bridge?.lastFailedStoppedLocation()
        else {
            return OutgoingLocation(location: context.location, stopped: movement.stopped, replayed: false)
        }

        bridge?.setLastFailedStoppedLocation(nil)
        RadarLogger.shared.debug("🦅 Replaying location | location = \(lastFailedStoppedLocation); stopped = true")

        return OutgoingLocation(location: lastFailedStoppedLocation, stopped: true, replayed: true)
    }

    // MARK: - Sync gating

    /// Applies the sync throttles. They're skipped when nothing has been sent yet, a location
    /// request is waiting, the device just stopped, a stop is being replayed, or a beacon was
    /// entered or exited.
    private static func shouldSkipSync(
        _ context: HandledLocation,
        movement: LocationMovement,
        outgoing: OutgoingLocation,
        host: RadarLocationManagerSwiftHost,
        bridge: RadarSwiftBridgeProtocol?
    ) -> Bool {
        let lastSentAt = bridge?.lastSentAt()
        let ignoreSync =
            lastSentAt == nil || host.completionHandlerCount() > 0 || movement.justStopped || outgoing.replayed
            || context.source == .beaconEnter || context.source == .beaconExit
        guard !ignoreSync, let lastSentAt else {
            return false
        }

        let options = context.options
        let lastSyncInterval = Date().timeIntervalSince(lastSentAt)

        if !context.bypassDeviceLocationState && !context.force && outgoing.stopped && context.wasStopped
            && movement.distance <= CLLocationDistance(options.stopDistance)
            && (options.desiredStoppedUpdateInterval == 0
                || (options.syncLocations != .all && options.syncLocations != .events))
        {
            RadarLogger.shared.debug(
                "🦅 Skipping sync: already stopped | stopped = \(outgoing.stopped); wasStopped = \(context.wasStopped)"
            )
            return true
        }

        // add a 0.1 second buffer to account for the fact that the timer may fire slightly before the desired interval
        let lastSyncIntervalWithBuffer = lastSyncInterval + 0.1
        if lastSyncIntervalWithBuffer < TimeInterval(options.desiredSyncInterval) {
            RadarLogger.shared.debug(
                "🦅 Skipping sync: desired sync interval | desiredSyncInterval = \(options.desiredSyncInterval); "
                    + "lastSyncInterval = \(lastSyncIntervalWithBuffer)"
            )
            return true
        }

        if !context.force && !movement.justStopped && lastSyncInterval < 1 {
            RadarLogger.shared.debug(
                "🦅 Skipping sync: rate limit | justStopped = \(movement.justStopped); lastSyncInterval = \(lastSyncInterval)"
            )
            return true
        }

        let syncLocationsString = RadarTrackingOptions.string(for: options.syncLocations)
        if options.syncLocations == .none {
            RadarLogger.shared.debug("🦅 Skipping sync: sync mode | sync = \(syncLocationsString)")
            return true
        }

        let canExit = bridge?.canExit() ?? false
        if !canExit && options.syncLocations == .stopsAndExits {
            RadarLogger.shared.debug("🦅 Skipping sync: can't exit | sync = \(syncLocationsString); canExit = \(canExit)")
            return true
        }

        return false
    }

    // MARK: - Sync region

    /// Background locations in events-only mode with a sync region are checked locally, and only
    /// sent when the geofence or place state changes or beacons need ranging.
    private static func usesSyncRegionEvaluation(_ context: HandledLocation) -> Bool {
        !context.bypassDeviceLocationState && context.source != .foregroundLocation
            && context.source != .manualLocation && context.sdkConfiguration?.useSyncRegion == true
            && context.options.syncLocations == .events
    }

    private static func evaluateSyncRegion(
        _ context: HandledLocation,
        outgoing: OutgoingLocation,
        host: RadarLocationManagerSwiftHost,
        bridge: RadarSwiftBridgeProtocol?
    ) {
        let location = context.location
        let options = context.options

        if location.horizontalAccuracy >= 1000 && options.desiredAccuracy != .low {
            RadarLogger.shared.info("🦅 Skipping sync region eval: inaccurate | accuracy = \(location.horizontalAccuracy)")
            return
        }

        if RadarSyncManager.shouldTrack(location: location, options: options) {
            bridge?.updateLastSentAt()
            send(outgoing, context: context, host: host, forceTrack: true)
            return
        }

        if options.beacons {
            send(outgoing, context: context, host: host, forceTrack: false)
            return
        }

        let sourceString = Radar.stringForLocationSource(context.source)
        RadarLogger.shared.info("🦅 Skipping track: useSyncRegion - no state change detected | source = \(sourceString)")
    }

    // MARK: - Sending

    private static func send(
        _ outgoing: OutgoingLocation,
        context: HandledLocation,
        host: RadarLocationManagerSwiftHost,
        forceTrack: Bool
    ) {
        sendLocationHandler(
            host,
            LocationToSend(
                location: outgoing.location,
                stopped: outgoing.stopped,
                source: context.source,
                replayed: outgoing.replayed,
                beacons: context.beacons,
                forceTrack: forceTrack
            )
        )
    }
}

/// The inputs `handleLocation` reads once and passes to each step.
private struct HandledLocation {
    let location: CLLocation
    let source: RadarLocationSource
    let beacons: [RadarBeacon]?
    let options: RadarTrackingOptions
    let sdkConfiguration: RadarSdkConfiguration?
    let bypassDeviceLocationState: Bool
    let wasStopped: Bool
    let force: Bool

    init(
        location: CLLocation,
        source: RadarLocationSource,
        beacons: [RadarBeacon]?,
        bypassDeviceLocationState: Bool,
        bridge: RadarSwiftBridgeProtocol?
    ) {
        let options = Radar.getTrackingOptions()
        self.location = location
        self.source = source
        self.beacons = beacons
        self.options = options
        self.sdkConfiguration = RadarSettings.sdkConfiguration
        self.bypassDeviceLocationState = bypassDeviceLocationState
        self.wasStopped = bridge?.isStopped() ?? false
        self.force = Self.isForced(source: source, options: options)
    }

    /// Foreground and manual locations are always handled. Beacon and visit-arrival locations are
    /// too, unless the SDK only syncs events.
    private static func isForced(source: RadarLocationSource, options: RadarTrackingOptions) -> Bool {
        if source == .foregroundLocation || source == .manualLocation {
            return true
        }
        return options.syncLocations != .events
            && (source == .beaconEnter || source == .beaconExit || source == .visitArrival)
    }
}

/// The result of stop detection for a location.
private struct LocationMovement {
    let stopped: Bool
    let distance: CLLocationDistance
    let justStopped: Bool

    init(stopped: Bool, distance: CLLocationDistance, wasStopped: Bool) {
        self.stopped = stopped
        self.distance = distance
        self.justStopped = stopped && !wasStopped
    }
}

/// The location to send, which is a replayed stop when one failed to send earlier.
private struct OutgoingLocation {
    let location: CLLocation
    let stopped: Bool
    let replayed: Bool
}
