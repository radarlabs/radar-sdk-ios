//
//  RadarOfflineEventManager.swift
//  RadarSDK
//
//  Created by Alan Charles on 4/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

@objc(RadarOfflineEventManager) @objcMembers
class RadarOfflineEventManager: NSObject {

    private static let queue = DispatchQueue(label: "io.radar.offlineEventManager")
    nonisolated(unsafe) private static var _offlineGeofenceIds: Set<String>?
    nonisolated(unsafe) private static var _offlineBeaconIds: Set<String>?

    private static var offlineGeofenceIds: Set<String>? {
        get { queue.sync { _offlineGeofenceIds } }
        set { queue.sync { _offlineGeofenceIds = newValue } }
    }

    private static var offlineBeaconIds: Set<String>? {
        get { queue.sync { _offlineBeaconIds } }
        set { queue.sync { _offlineBeaconIds = newValue } }
    }

    static func reset() {
        offlineGeofenceIds = nil
        offlineBeaconIds = nil
    }

    // MARK: - Event generation

    static func generateEvents(
        location: CLLocation,
        completionHandler: @escaping ([RadarEvent], RadarUser?, CLLocation) -> Void
    ) {
        let state = RadarSyncManager.syncStore.read() ?? RadarSyncState()
        let beaconsEnabled = RadarSettings.trackingOptions?.beacons ?? false

        let effectiveGeofenceIds = offlineGeofenceIds ?? Set(state.lastSyncedGeofenceIds)
        let effectiveBeaconIds = offlineBeaconIds ?? Set(state.lastSyncedBeaconIds)

        let geofenceEntries = RadarSyncManager.getGeofenceEntries(for: location, against: effectiveGeofenceIds)
        let geofenceExits = RadarSyncManager.getGeofenceExits(for: location, against: effectiveGeofenceIds)
        let geofenceDwells = RadarSyncManager.getGeofenceDwells(for: location, against: effectiveGeofenceIds)

        let beaconEntries =
            beaconsEnabled
            ? RadarSyncManager.getBeaconEntries(for: location, against: effectiveBeaconIds)
            : []
        let beaconExits =
            beaconsEnabled
            ? RadarSyncManager.getBeaconExits(for: location, against: effectiveBeaconIds)
            : []

        let now = Date()
        let isoString = RadarUtils.isoDateFormatter.string(from: now)
        let isLive = (RadarSettings.publishableKey ?? "").hasPrefix("prj_live")

        let dwellDurations = state.geofenceEntryTimestamps.mapValues { now.timeIntervalSince1970 - $0 }

        var events = buildGeofenceEvents(
            entries: geofenceEntries, exits: geofenceExits,
            location: location, isoDate: isoString, live: isLive
        )
        events += buildDwellEvents(
            dwells: geofenceDwells, dwellDurations: dwellDurations,
            location: location, isoDate: isoString, live: isLive
        )

        events.append(
            contentsOf: buildBeaconEvents(
                entries: beaconEntries, exits: beaconExits,
                location: location, isoDate: isoString, live: isLive
            ))

        RadarSyncManager.recordGeofenceEntryTimestamps(geofenceEntries.map { $0.id })
        RadarSyncManager.clearGeofenceEntryState(geofenceExits.map { $0.id })
        for geofence in geofenceDwells {
            RadarSyncManager.markDwellFired(geofence.id)
        }

        let currentGeofences = RadarSyncManager.getGeofences(for: location)
        let currentBeacons = beaconsEnabled ? RadarSyncManager.getBeacons(for: location) : []
        offlineGeofenceIds = Set(currentGeofences.map { $0.id })

        if beaconsEnabled {
            offlineBeaconIds = Set(currentBeacons.map { $0.id })
        }

        let user = buildSyntheticUser(location: location, geofences: currentGeofences, beacons: currentBeacons)
        completionHandler(events, user, location)
    }

    static func handleTrackFailure(_ location: CLLocation) {
        let sdkConfig = RadarSettings.sdkConfiguration

        if sdkConfig?.offlineEventGenerationEnabled == true {
            generateEvents(location: location) { events, user, _ in
                if !events.isEmpty, let user {
                    RadarSwift.bridge?.didReceiveEvents(events, user: user)
                }
            }
        }
    }

    private static func buildGeofenceEvents(
        entries: [RadarGeofenceSwift],
        exits: [RadarGeofenceSwift],
        location: CLLocation,
        isoDate: String,
        live: Bool
    ) -> [RadarEvent] {
        var events = [RadarEvent]()
        for geofence in entries {
            guard let event = makeGeofenceEvent(type: "user.entered_geofence", geofence: geofence, location: location, isoDate: isoDate, live: live) else { continue }
            events.append(event)
            RadarLogger.shared.info("OfflineEventManager: Generated geofence entry for \(geofence.id)")
        }
        for geofence in exits {
            guard let event = makeGeofenceEvent(type: "user.exited_geofence", geofence: geofence, location: location, isoDate: isoDate, live: live) else { continue }
            events.append(event)
            RadarLogger.shared.info("OfflineEventManager: Generated geofence exit for \(geofence.id)")
        }
        return events
    }

    private static func buildDwellEvents(
        dwells: [RadarGeofenceSwift],
        dwellDurations: [String: TimeInterval],
        location: CLLocation,
        isoDate: String,
        live: Bool
    ) -> [RadarEvent] {
        var events = [RadarEvent]()
        for geofence in dwells {
            let duration = dwellDurations[geofence.id] ?? 0
            guard let event = makeGeofenceEvent(type: "user.dwelled_in_geofence", geofence: geofence, location: location, isoDate: isoDate, live: live, duration: duration) else { continue }
            events.append(event)
            RadarLogger.shared.info("OfflineEventManager: Generated geofence dwell for \(geofence.id)")
        }
        return events
    }

    private static func buildBeaconEvents(
        entries: [RadarBeaconSwift],
        exits: [RadarBeaconSwift],
        location: CLLocation,
        isoDate: String,
        live: Bool
    ) -> [RadarEvent] {
        var events = [RadarEvent]()
        for beacon in entries {
            guard let event = makeBeaconEvent(type: "user.entered_beacon", beacon: beacon, location: location, isoDate: isoDate, live: live) else { continue }
            events.append(event)
            RadarLogger.shared.info("OfflineEventManager: Generated beacon entry for \(beacon.id)")
        }
        for beacon in exits {
            guard let event = makeBeaconEvent(type: "user.exited_beacon", beacon: beacon, location: location, isoDate: isoDate, live: live) else { continue }
            events.append(event)
            RadarLogger.shared.info("OfflineEventManager: Generated beacon exit for \(beacon.id)")
        }
        return events
    }

    // MARK: - Tracking options ramp-up/down

    static func updateTrackingOptions(geofenceTags: [String]) -> RadarTrackingOptions? {
        let sdkConfig = RadarSettings.sdkConfiguration
        let remoteOptions = sdkConfig?.remoteTrackingOptions

        let rampUpTags = RadarRemoteTrackingOptions.geofenceTags(forKey: "inGeofence", in: remoteOptions)
        let inRampedUpGeofences: Bool
        if let rampUpTags {
            inRampedUpGeofences = !Set(rampUpTags).isDisjoint(with: Set(geofenceTags))
        } else {
            inRampedUpGeofences = false
        }

        if inRampedUpGeofences {
            RadarLogger.shared.debug("OfflineEventManager: Ramping up tracking options")
            let options = RadarRemoteTrackingOptions.trackingOptions(forKey: "inGeofence", in: remoteOptions)
            options?.type = .inGeofence
            return options
        } else if let onTripOptions = RadarRemoteTrackingOptions.trackingOptions(forKey: "onTrip", in: remoteOptions),
            Radar.getTripOptions() != nil
        {
            RadarLogger.shared.debug("OfflineEventManager: Using on-trip tracking options")
            onTripOptions.type = .onTrip
            return onTripOptions
        } else {
            RadarLogger.shared.debug("OfflineEventManager: Using default tracking options")
            let options = RadarRemoteTrackingOptions.trackingOptions(forKey: "default", in: remoteOptions)
            options?.type = .default
            return options
        }
    }

    static func updateTrackingOptions(for location: CLLocation) -> RadarTrackingOptions? {
        let currentGeofences = RadarSyncManager.getGeofences(for: location)
        let tags = currentGeofences.compactMap { $0.tag }

        return updateTrackingOptions(geofenceTags: tags)
    }

    // MARK: - Private helpers

    private static func makeGeofenceEvent(
        type: String,
        geofence: RadarGeofenceSwift,
        location: CLLocation,
        isoDate: String,
        live: Bool,
        duration: TimeInterval = 0
    ) -> RadarEvent? {
        let eventDict: [String: Any] = [
            "_id": "\(geofence.id)_offline_\(UUID().uuidString)",
            "createdAt": isoDate,
            "actualCreatedAt": isoDate,
            "live": live,
            "type": type,
            "geofence": geofenceDictionary(from: geofence),
            "verification": RadarEventVerification.unverify.rawValue,
            "confidence": RadarEventConfidence.low.rawValue,
            "duration": duration,
            "location": [
                "coordinates": [location.coordinate.longitude, location.coordinate.latitude]
            ],
            "locationAccuracy": location.horizontalAccuracy,
            "replayed": false,
            "metadata": ["offline": true],
        ]
        return RadarSwift.bridge?.createEvent(dict: eventDict)
    }

    private static func makeBeaconEvent(
        type: String,
        beacon: RadarBeaconSwift,
        location: CLLocation,
        isoDate: String,
        live: Bool
    ) -> RadarEvent? {
        let eventDict: [String: Any] = [
            "_id": "\(beacon.id)_offline_\(UUID().uuidString)",
            "createdAt": isoDate,
            "actualCreatedAt": isoDate,
            "live": live,
            "type": type,
            "beacon": beaconDictionary(from: beacon),
            "verification": RadarEventVerification.unverify.rawValue,
            "confidence": RadarEventConfidence.low.rawValue,
            "duration": 0,
            "location": [
                "coordinates": [location.coordinate.longitude, location.coordinate.latitude]
            ],
            "locationAccuracy": location.horizontalAccuracy,
            "replayed": false,
            "metadata": ["offline": true],
        ]

        return RadarSwift.bridge?.createEvent(dict: eventDict)
    }

    private static func buildSyntheticUser(
        location: CLLocation,
        geofences: [RadarGeofenceSwift],
        beacons: [RadarBeaconSwift]
    ) -> RadarUser? {
        let cachedUser = RadarSwift.bridge?.radarUser()
        let geofenceDicts = geofences.map { geofenceDictionary(from: $0) }
        let beaconDicts = beacons.map { beaconDictionary(from: $0) }
        let isStopped = RadarSwift.bridge?.isStopped() ?? false
        let isForeground = RadarSwift.bridge?.isForeground() ?? false

        var userDict: [String: Any] = [
            "location": [
                "coordinates": [location.coordinate.longitude, location.coordinate.latitude]
            ],
            "locationAccuracy": location.horizontalAccuracy,
            "geofences": geofenceDicts,
            "beacons": beaconDicts,
            "stopped": isStopped,
            "foreground": isForeground,
        ]

        if let id = cachedUser?._id { userDict["_id"] = id }
        if let userId = cachedUser?.userId { userDict["userId"] = userId }
        if let deviceId = cachedUser?.deviceId { userDict["deviceId"] = deviceId }
        if let desc = cachedUser?.__description { userDict["description"] = desc }
        if let metadata = cachedUser?.metadata { userDict["metadata"] = metadata }

        return RadarUser(object: userDict)
    }
}

// MARK: - Model serialization

extension RadarOfflineEventManager {

    fileprivate static func dictionary<T: Encodable>(from value: T) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(value),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            RadarLogger.shared.error("OfflineEventManager: Failed to encode \(T.self) to dictionary")
            return [:]
        }
        return dict
    }

    fileprivate static func geofenceDictionary(from geofence: RadarGeofenceSwift) -> [String: Any] {
        dictionary(from: geofence)
    }

    fileprivate static func beaconDictionary(from beacon: RadarBeaconSwift) -> [String: Any] {
        dictionary(from: beacon)
    }
}
