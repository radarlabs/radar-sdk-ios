//
//  RadarLocationManager+SwiftSend.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Swift port of `sendLocation:stopped:source:replayed:beacons:forceTrack:` in
// RadarLocationManager.m. It ranges nearby beacons when the tracking options ask for them, sends
// the location to the track API, and applies the response. The track and beacon search requests
// still go through the Objective-C `RadarAPIClient` behind `RadarSwiftBridge`.
extension RadarLocationManagerSwift {

    /// Ranges beacons once. Tests replace it so they don't range with Core Location.
    nonisolated(unsafe) static var rangeBeacons: @MainActor ([RadarBeacon], @escaping RadarBeaconCompletionHandler) -> Void = { beacons, completionHandler in
        RadarOneShotBeaconManager.shared.rangeBeacons(beacons, completionHandler: completionHandler)
    }

    /// Ranges beacon UUIDs once. Tests replace it so they don't range with Core Location.
    nonisolated(unsafe) static var rangeBeaconUUIDs: @MainActor ([String], @escaping RadarBeaconCompletionHandler) -> Void = { uuids, completionHandler in
        RadarOneShotBeaconManager.shared.rangeBeaconUUIDs(uuids, completionHandler: completionHandler)
    }

    /// Gets the indoor location sent with each track request. Tests replace it so they don't wait
    /// on the indoor SDK.
    nonisolated(unsafe) static var getIndoorLocation: (@escaping @Sendable (CLLocation?) -> Void) -> Void = {
        RadarIndoors.shared.getLocation(completionHandler: $0)
    }

    /// Sends a location `handleLocation` decided to send. Tests replace it to record sends without
    /// calling the track API.
    nonisolated(unsafe) static var sendLocationHandler: (RadarLocationManagerSwiftHost, LocationToSend) -> Void =
        sendLocation(host:_:)

    @objc(sendLocationWithHost:location:stopped:source:replayed:beacons:forceTrack:)
    static func sendLocation(  // swiftlint:disable:this function_parameter_count
        host: RadarLocationManagerSwiftHost,
        location: CLLocation,
        stopped: Bool,
        source: RadarLocationSource,
        replayed: Bool,
        beacons: [RadarBeacon]?,
        forceTrack: Bool
    ) {
        sendLocation(
            host: host,
            LocationToSend(
                location: location,
                stopped: stopped,
                source: source,
                replayed: replayed,
                beacons: beacons,
                forceTrack: forceTrack
            )
        )
    }

    static func sendLocation(host: RadarLocationManagerSwiftHost, _ send: LocationToSend) {
        RadarLogger.shared.debug(
            "🦅 Sending location | source = \(Radar.stringForLocationSource(send.source)); location = \(send.location); "
                + "stopped = \(send.stopped); replayed = \(send.replayed); beacons = \(String(describing: send.beacons)); "
                + "forceTrack = \(send.forceTrack)"
        )

        host.setSending(true)

        guard let bridge = RadarSwift.bridge else {
            RadarLogger.shared.error("🦅 Skipping track: missing Swift bridge")
            host.setSending(false)
            return
        }

        let pending = PendingSend(host: host, bridge: bridge, send: send)
        let options = Radar.getTrackingOptions()

        if RadarSettings.useRadarModifiedBeacon {
            sendWithModifiedBeacons(pending, options: options)
        } else {
            sendWithSyncedBeacons(pending, options: options)
        }
    }

    // MARK: - Beacon search

    /// Beacon entries and exits already carry their beacons, and mock and manual locations aren't
    /// near the device, so only other sources search for beacons.
    private static func searchesBeacons(for source: RadarLocationSource) -> Bool {
        source != .beaconEnter && source != .beaconExit && source != .mockLocation && source != .manualLocation
    }

    /// The synced region's beacons near `location`, or `nil` when there is no synced region to use.
    private static func syncedRegionBeacons(near location: CLLocation) -> [RadarBeacon]? {
        guard RadarSettings.sdkConfiguration?.useSyncRegion == true, RadarSyncManager.hasSyncedRegion(),
            !RadarSyncManager.isOutsideSyncedRegion(location: location)
        else {
            return nil
        }
        return RadarSyncManager.getObjCBeacons(for: location)
    }

    private static func range(_ beacons: [RadarBeacon], completionHandler: @escaping RadarBeaconCompletionHandler) {
        let box = RangeRequest(beacons: beacons, completionHandler: completionHandler)
        Task { @MainActor in
            rangeBeacons(box.beacons, box.completionHandler)
        }
    }

    private static func range(uuids: [String], completionHandler: @escaping RadarBeaconCompletionHandler) {
        let box = RangeRequest(beacons: [], completionHandler: completionHandler)
        Task { @MainActor in
            rangeBeaconUUIDs(uuids, box.completionHandler)
        }
    }

    /// Saves the ranged beacon state and returns `true` when it changed since the last track.
    private static func recordBeaconStateIfChanged(
        _ rangedIds: Set<String>,
        savedIds: [String],
        bridge: RadarSwiftBridgeProtocol
    ) -> Bool {
        guard RadarSyncManager.hasBeaconStateChanged(rangedBeaconIds: rangedIds) else {
            RadarLogger.shared.info("🦅 Skipping track: beacon state unchanged after BLE ranging")
            return false
        }
        bridge.updateLastSentAt()
        RadarSyncManager.saveBeaconState(beaconIds: savedIds)
        return true
    }

    // MARK: - Modified beacons

    /// With modified beacons, the beacons are ranged before the location is sent, and the location
    /// is sent with the ranged beacons.
    private static func sendWithModifiedBeacons(_ pending: PendingSend, options: RadarTrackingOptions) {
        let send = pending.send
        guard options.beacons && searchesBeacons(for: send.source) else {
            track(pending, beacons: nil, response: .always)
            return
        }

        RadarLogger.shared.debug("🦅 Searching for nearby beacons")

        if let syncedBeacons = syncedRegionBeacons(near: send.location) {
            rangeSyncedBeaconsForModifiedBeacons(pending, syncedBeacons: syncedBeacons)
        } else {
            searchAndRangeBeaconsForModifiedBeacons(pending)
        }
    }

    private static func rangeSyncedBeaconsForModifiedBeacons(_ pending: PendingSend, syncedBeacons: [RadarBeacon]) {
        let forceTrack = pending.send.forceTrack
        guard !syncedBeacons.isEmpty else {
            if forceTrack {
                track(pending, beacons: [], response: .always)
            } else {
                pending.host.setSending(false)
            }
            return
        }

        replaceSyncedBeacons(locationManager: pending.host.locationManager, beacons: syncedBeacons)
        range(syncedBeacons) { status, beacons in
            guard status == .success, let beacons else {
                if forceTrack {
                    track(pending, beacons: nil, response: .always)
                } else {
                    pending.host.setSending(false)
                }
                return
            }

            let matchedIds = matchBeaconIds(ranged: beacons, synced: syncedBeacons)
            if forceTrack {
                RadarSyncManager.saveBeaconState(beaconIds: matchedIds)
                track(pending, beacons: beacons, response: .always)
                return
            }

            let rangedIds = Set(matchedIds)
            if recordBeaconStateIfChanged(rangedIds, savedIds: Array(rangedIds), bridge: pending.bridge) {
                track(pending, beacons: beacons, response: .always)
            } else {
                pending.host.setSending(false)
            }
        }
    }

    private static func searchAndRangeBeaconsForModifiedBeacons(_ pending: PendingSend) {
        pending.bridge.searchBeacons(
            near: pending.send.location,
            radius: RadarNearbyBeaconSearch.radius,
            limit: RadarNearbyBeaconSearch.limit
        ) { _, beacons, beaconUUIDs in
            let trackRanged: RadarBeaconCompletionHandler = { status, rangedBeacons in
                track(pending, beacons: status == .success ? rangedBeacons : nil, response: .always)
            }

            if let beaconUUIDs, !beaconUUIDs.isEmpty {
                replaceSyncedBeaconUUIDs(locationManager: pending.host.locationManager, uuids: beaconUUIDs)
                range(uuids: beaconUUIDs, completionHandler: trackRanged)
            } else if let beacons, !beacons.isEmpty {
                replaceSyncedBeacons(locationManager: pending.host.locationManager, beacons: beacons)
                range(beacons, completionHandler: trackRanged)
            } else {
                track(pending, beacons: [], response: .always)
            }
        }
    }

    // MARK: - Synced beacons

    /// Without modified beacons, the location is sent with the beacons it was handled with, and
    /// nearby beacons are registered for region monitoring. In a synced region with events-only
    /// sync, the location is sent only when ranging changes the beacon state.
    private static func sendWithSyncedBeacons(_ pending: PendingSend, options: RadarTrackingOptions) {
        let send = pending.send

        if options.beacons {
            RadarLogger.shared.debug("🦅 Searching for nearby beacons")

            if searchesBeacons(for: send.source) {
                if let syncedBeacons = syncedRegionBeacons(near: send.location) {
                    if !syncedBeacons.isEmpty {
                        replaceSyncedBeacons(locationManager: pending.host.locationManager, beacons: syncedBeacons)

                        if !send.forceTrack {
                            rangeSyncedBeaconsBeforeTracking(pending, syncedBeacons: syncedBeacons)
                            return
                        }
                    }
                } else {
                    replaceSyncedBeaconsFromSearch(pending)
                }
            }
        }

        track(pending, beacons: send.beacons, response: .requiresConfig)
    }

    private static func rangeSyncedBeaconsBeforeTracking(_ pending: PendingSend, syncedBeacons: [RadarBeacon]) {
        range(syncedBeacons) { status, rangedBeacons in
            guard status == .success, let rangedBeacons else {
                pending.host.setSending(false)
                return
            }

            let matchedIds = matchBeaconIds(ranged: rangedBeacons, synced: syncedBeacons)
            if recordBeaconStateIfChanged(Set(matchedIds), savedIds: matchedIds, bridge: pending.bridge) {
                track(pending, beacons: rangedBeacons, response: .requiresConfig)
            } else {
                pending.host.setSending(false)
            }
        }
    }

    /// Registers nearby beacons for region monitoring. The location is sent without waiting for it.
    private static func replaceSyncedBeaconsFromSearch(_ pending: PendingSend) {
        pending.bridge.searchBeacons(
            near: pending.send.location,
            radius: RadarNearbyBeaconSearch.radius,
            limit: RadarNearbyBeaconSearch.limit
        ) { _, beacons, beaconUUIDs in
            if let beaconUUIDs, !beaconUUIDs.isEmpty {
                replaceSyncedBeaconUUIDs(locationManager: pending.host.locationManager, uuids: beaconUUIDs)
            } else if let beacons, !beacons.isEmpty {
                replaceSyncedBeacons(locationManager: pending.host.locationManager, beacons: beacons)
            }
        }
    }

    // MARK: - Tracking

    /// The two send paths apply the track response differently.
    private enum TrackResponseHandling {
        /// Apply the meta and nearby geofences from every response, as the modified-beacon path does.
        case always
        /// Skip a response without a config, and replace nearby geofences only on success.
        case requiresConfig
    }

    private static func track(_ pending: PendingSend, beacons: [RadarBeacon]?, response: TrackResponseHandling) {
        let beaconsBox = BeaconsBox(beacons: beacons)
        getIndoorLocation { indoorLocation in
            let send = pending.send
            pending.bridge.track(
                location: send.location,
                stopped: send.stopped,
                source: send.source,
                replayed: send.replayed,
                beacons: beaconsBox.beacons,
                indoorLocation: indoorLocation
            ) { status, events, user, nearbyGeofences, config in
                pending.host.setSending(false)
                reconcileSyncState(status: status, events: events, user: user)

                switch response {
                case .always:
                    updateTrackingFromMeta(config?.meta)
                    pending.host.replaceSyncedGeofences(nearbyGeofences)
                    if let user {
                        pending.bridge.updateIndoorTracking(geofences: user.geofences)
                    }
                case .requiresConfig:
                    if let user {
                        pending.bridge.updateIndoorTracking(geofences: user.geofences)
                    }
                    guard let config else {
                        return
                    }
                    updateTrackingFromMeta(config.meta)
                    if status == .success {
                        pending.host.replaceSyncedGeofences(nearbyGeofences)
                    }
                }
            }
        }
    }

    /// Commits the sync region state the track request was sent with, or rolls it back if the
    /// request failed.
    private static func reconcileSyncState(status: RadarStatus, events: [RadarEvent]?, user: RadarUser?) {
        guard RadarSettings.sdkConfiguration?.useSyncRegion == true else {
            return
        }

        guard status == .success, let user else {
            RadarSyncManager.rollbackSyncState()
            return
        }

        RadarSyncManager.reconcileSyncState(user: user)
        for event in events ?? [] where event.type == .userDwelledInGeofence {
            if let geofenceId = event.geofence?._id {
                RadarSyncManager.markDwellFired(geofenceId)
            }
        }
    }
}

/// A location to send to the track API, and how to send it.
struct LocationToSend {
    let location: CLLocation
    let stopped: Bool
    let source: RadarLocationSource
    let replayed: Bool
    let beacons: [RadarBeacon]?
    /// Send even when ranging fails or the beacon state hasn't changed.
    let forceTrack: Bool
}

/// The host, bridge, and location for one send, shared by the callbacks that finish it. The host
/// and bridge are Objective-C objects that the send only calls on, so they're `@unchecked Sendable`.
private final class PendingSend: @unchecked Sendable {
    let host: RadarLocationManagerSwiftHost
    let bridge: RadarSwiftBridgeProtocol
    let send: LocationToSend

    init(host: RadarLocationManagerSwiftHost, bridge: RadarSwiftBridgeProtocol, send: LocationToSend) {
        self.host = host
        self.bridge = bridge
        self.send = send
    }
}

private final class RangeRequest: @unchecked Sendable {
    let beacons: [RadarBeacon]
    let completionHandler: RadarBeaconCompletionHandler

    init(beacons: [RadarBeacon], completionHandler: @escaping RadarBeaconCompletionHandler) {
        self.beacons = beacons
        self.completionHandler = completionHandler
    }
}

private final class BeaconsBox: @unchecked Sendable {
    let beacons: [RadarBeacon]?

    init(beacons: [RadarBeacon]?) {
        self.beacons = beacons
    }
}
