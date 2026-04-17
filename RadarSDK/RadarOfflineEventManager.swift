//
//  RadarOfflineEventManager.swift
//  RadarSDK
//
//  Created by Alan Charles on 4/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

@objc(RadarOfflineEventManager) @objcMembers
class RadarOfflineEventManager: NSObject {
    

    @nonobjc
    nonisolated(unsafe) static var debugLogger: ((String) -> Void)?
    @objc static func setDebugLogger(_ logger: ((String) -> Void)?) {
        debugLogger = logger
    }
    private static func debugLog(_ message: @autoclosure () -> String) {
        debugLogger?(message())
    }
    
    @objc public static func logDebug(_ message: String) {
        debugLog(message)
    }
    
    private static let queue = DispatchQueue(label: "io.radar.offlineEventManager")
    nonisolated(unsafe)  private static var _offlineGeofenceIds: Set<String>? = nil
    
    private static var offlineGeofenceIds: Set<String>? {
        get { queue.sync { _offlineGeofenceIds } }
        set { queue.sync { _offlineGeofenceIds = newValue } }
    }

    @objc static func reset() {
        offlineGeofenceIds = nil
    }
    
    // MARK: - Event generation
    
    @objc static func generateEvents(
        location: CLLocation,
        completionHandler: @escaping ([RadarEvent], RadarUser?, CLLocation) -> Void
    ) {
        let state = RadarSyncManager.syncStore.read() ?? RadarSyncState()
        let baselineIds = Set(state.lastSyncedGeofenceIds)
        let effectiveIds = offlineGeofenceIds ?? baselineIds
        
        let entries = RadarSyncManager.getGeofenceEntries(for: location, against: effectiveIds)
        let exits = RadarSyncManager.getGeofenceExits(for: location, against: effectiveIds)
        
        let now = Date()
        let isoString = RadarUtils.isoDateFormatter.string(from: now)
        let isLive = (RadarSettings.publishableKey ?? "").hasPrefix("prj_live")
        
        var events = [RadarEvent]()
        
        
        for geofence in entries {
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
        
        for geofence in exits {
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
        
        let currentGeofences = RadarSyncManager.getGeofences(for: location)
        offlineGeofenceIds = Set(currentGeofences.map { $0.id})
        
        debugLog(
            "generateEvents loc=(\(location.coordinate.latitude),\(location.coordinate.longitude)) acc=\(location.horizontalAccuracy) " +
            "baselineIds=\(baselineIds) effectiveIds=\(effectiveIds) " +
            "entries=\(entries.map { $0.id }) exits=\(exits.map { $0.id }) " +
            "newOfflineGeofenceIds=\(Set(currentGeofences.map { $0.id }))"
        )
        let user = buildSyntheticUser(location: location, geofences: currentGeofences)
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
        
        debugLog(
            "updateTrackingOptions tags=\(geofenceTags) rampUpTags=\(rampUpTags ?? []) match=\(inRampedUpGeofences) " +
            "remoteTypes=\(remoteOptions?.map { $0.type } ?? [])"
        )
        if inRampedUpGeofences {
            RadarLogger.shared.debug("OfflineEventManager: Ramping up tracking options")
            return RadarRemoteTrackingOptions.trackingOptions(forKey: "inGeofence", in: remoteOptions)
        } else if let onTripOptions = RadarRemoteTrackingOptions.trackingOptions(forKey: "onTrip", in: remoteOptions),
                  Radar.getTripOptions() != nil {
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
        debugLog(
            "updateTrackingOptions(for:) loc=(\(location.coordinate.latitude),\(location.coordinate.longitude)) acc=\(location.horizontalAccuracy) " +
            "currentGeofenceIds=\(currentGeofences.map { $0.id }) tags=\(tags)"
        )
        return updateTrackingOptions(geofenceTags: tags)
    }
    
    // MARK: - Private helpers
    
    private static func makeGeofenceEvent(
        type: String,
        geofence: RadarGeofenceSwift,
        location: CLLocation,
        isoDate: String,
        live: Bool
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
            "duration": 0,
            "location": [
                "coordinates": [location.coordinate.longitude, location.coordinate.latitude]
            ],
            "locationAccuracy": location.horizontalAccuracy,
            "replayed": false,
            "metadata": ["offline": true]
        ]
        return RadarSwift.bridge?.createEvent(dict: eventDict)
    }
    
    private static func geofenceDictionary(from geofence: RadarGeofenceSwift) -> [String: Any] {
        var dict: [String: Any] = [
            "_id": geofence.id,
            "description": geofence.description
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
    
    private static func buildSyntheticUser(
        location: CLLocation,
        geofences: [RadarGeofenceSwift]
    ) -> RadarUser? {
        let cachedUser = RadarSwift.bridge?.radarUser()
        let geofenceDicts = geofences.map { geofenceDictionary(from: $0) }
        let isStopped = RadarSwift.bridge?.isStopped() ?? false
        let isForeground = RadarSwift.bridge?.isForeground() ?? false
        
        var userDict: [String: Any] = [
            "location": [
                "coordinates": [location.coordinate.longitude, location.coordinate.latitude]
            ],
            "locationAccuracy": location.horizontalAccuracy,
            "geofences": geofenceDicts,
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
