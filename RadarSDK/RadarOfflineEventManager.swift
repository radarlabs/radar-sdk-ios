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
    nonisolated(unsafe) private static var _offlineGeofenceIds: Set<String>? = nil
    nonisolated(unsafe) private static var _offlineBeaconIds: Set<String>? = nil

    private static var offlineGeofenceIds: Set<String>? {
        get { queue.sync { _offlineGeofenceIds } }
        set { queue.sync { _offlineGeofenceIds = newValue } }
    }

    private static var offlineBeaconIds: Set<String>? {
        get { queue.sync { _offlineBeaconIds } }
        set { queue.sync { _offlineBeaconIds = newValue } }
    }

    @objc static func reset() {
        offlineGeofenceIds = nil
        offlineBeaconIds = nil
    }

    // MARK: - Event generation

    @objc static func generateEvents(
        location: CLLocation,
        completionHandler: @escaping ([RadarEvent], RadarUser?, CLLocation) -> Void
    ) {
        let state = RadarSyncManager.syncStore.read() ?? RadarSyncState()

        let effectiveGeofenceIds = offlineGeofenceIds ?? Set(state.lastSyncedGeofenceIds)
        let effectiveBeaconIds = offlineBeaconIds ?? Set(state.lastSyncedBeaconIds)

        let geofenceEntries = RadarSyncManager.getGeofenceEntries(for: location, against: effectiveGeofenceIds)
        let geofenceExits = RadarSyncManager.getGeofenceExits(for: location, against: effectiveGeofenceIds)
        let geofenceDwells = RadarSyncManager.getGeofenceDwells(for: location, against: effectiveGeofenceIds)
        let beaconEntries = RadarSyncManager.getBeaconEntries(for: location, against: effectiveBeaconIds)
        let beaconExits = RadarSyncManager.getBeaconExits(for: location, against: effectiveBeaconIds)

        let now = Date()
        let isoString = RadarUtils.isoDateFormatter.string(from: now)
        let isLive = (RadarSettings.publishableKey ?? "").hasPrefix("prj_live")
        let entryTimestamps = state.geofenceEntryTimestamps

        var events = [RadarEvent]()

        for geofence in geofenceEntries {
            if let event = makeGeofenceEvent(
                type: "user.entered_geofence",
                geofence: geofence,
                location: location,
                isoDate: isoString,
                live: isLive
            ) {
                events.append(event)
                RadarLogger.shared.info("OfflineEventManager: Generated geofence entry for \(geofence.id)")
            }
        }

        for geofence in geofenceExits {
            if let event = makeGeofenceEvent(
                type: "user.exited_geofence",
                geofence: geofence,
                location: location,
                isoDate: isoString,
                live: isLive
            ) {
                events.append(event)
                RadarLogger.shared.info("OfflineEventManager: Generated geofence exit for \(geofence.id)")
            }
        }

        for geofence in geofenceDwells {
            let duration = entryTimestamps[geofence.id].map { now.timeIntervalSince1970 - $0 } ?? 0
            if let event = makeGeofenceEvent(
                type: "user.dwelled_in_geofence",
                geofence: geofence,
                location: location,
                isoDate: isoString,
                live: isLive,
                duration: duration
            ) {
                events.append(event)
                RadarLogger.shared.info("OfflineEventManager: Generated geofence dwell for \(geofence.id)")
            }
        }

        for beacon in beaconEntries {
            if let event = makeBeaconEvent(
                type: "user.entered_beacon",
                beacon: beacon,
                location: location,
                isoDate: isoString,
                live: isLive
            ) {
                events.append(event)
                RadarLogger.shared.info("OfflineEventManager: Generated beacon entry for \(beacon.id)")
            }
        }

        for beacon in beaconExits {
            if let event = makeBeaconEvent(
                type: "user.exited_beacon",
                beacon: beacon,
                location: location,
                isoDate: isoString,
                live: isLive
            ) {
                events.append(event)
                RadarLogger.shared.info("OfflineEventManager: Generated beacon exit for \(beacon.id)")
            }
        }

        RadarSyncManager.recordGeofenceEntryTimestamps(geofenceEntries.map { $0.id })
        RadarSyncManager.clearGeofenceEntryState(geofenceExits.map { $0.id })
        for geofence in geofenceDwells {
            RadarSyncManager.markDwellFired(geofence.id)
        }

        let currentGeofences = RadarSyncManager.getGeofences(for: location)
        let currentBeacons = RadarSyncManager.getBeacons(for: location)
        offlineGeofenceIds = Set(currentGeofences.map { $0.id })
        offlineBeaconIds = Set(currentBeacons.map { $0.id })

        let user = buildSyntheticUser(location: location, geofences: currentGeofences, beacons: currentBeacons)
        completionHandler(events, user, location)
    }

    @objc static func handleTrackFailure(_ location: CLLocation) {
        let sdkConfig = RadarSettings.sdkConfiguration

        if sdkConfig?.offlineEventGenerationEnabled == true {
            generateEvents(location: location) { events, user, loc in
                if !events.isEmpty, let user {
                    RadarSwift.bridge?.didReceiveEvents(events, user: user)
                }
            }
        }
    }

    // MARK: - Tracking options ramp-up/down

    @objc static func updateTrackingOptions(geofenceTags: [String]) -> RadarTrackingOptions? {
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
            return RadarRemoteTrackingOptions.trackingOptions(forKey: "inGeofence", in: remoteOptions)
        } else if let onTripOptions = RadarRemoteTrackingOptions.trackingOptions(forKey: "onTrip", in: remoteOptions),
            Radar.getTripOptions() != nil
        {
            RadarLogger.shared.debug("OfflineEventManager: Using on-trip tracking options")
            return onTripOptions
        } else {
            RadarLogger.shared.debug("OfflineEventManager: Using default tracking options")
            return RadarRemoteTrackingOptions.trackingOptions(forKey: "default", in: remoteOptions)
        }
    }

    @objc static func updateTrackingOptions(for location: CLLocation) -> RadarTrackingOptions? {
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

    private static func geofenceDictionary(from geofence: RadarGeofenceSwift) -> [String: Any] {
        var dict: [String: Any] = [
            "_id": geofence.id,
            "description": geofence.description,
        ]
        if let tag = geofence.tag { dict["tag"] = tag }
        if let externalId = geofence.externalId { dict["externalId"] = externalId }

        switch geofence.geometry {
        case .circle(let center, let radius):
            dict["type"] = "circle"
            dict["geometryCenter"] = ["coordinates": [center.longitude, center.latitude]]
            dict["geometryRadius"] = radius
        case .polygon(_, let center, let radius):
            dict["type"] = "polygon"
            dict["geometryCenter"] = ["coordinates": [center.longitude, center.latitude]]
            dict["geometryRadius"] = radius
        }
        return dict
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

    private static func beaconDictionary(from beacon: RadarBeaconSwift) -> [String: Any] {
        var dict: [String: Any] = [
            "_id": beacon.id,
            "uuid": beacon.uuid,
            "major": beacon.major,
            "minor": beacon.minor,
            "type": "ibeacon",
        ]

        if let desc = beacon.description { dict["description"] = desc }
        if let tag = beacon.tag { dict["tag"] = tag }
        if let externalId = beacon.externalId { dict["externalId"] = externalId }
        if let geometry = beacon.geometry {
            dict["geometry"] = ["coordinates": [geometry.longitude, geometry.latitude]]
        }

        return dict
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
