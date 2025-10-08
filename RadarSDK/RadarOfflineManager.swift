//
//  RadarOfflineManager.swift
//  RadarSDK
//
//  Created by Kenny Hu on 10/16/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

// Utility to generate an ObjectId with the ObjectId specification
// counter will only be accessed within counterQueue, initialize counter with a random value
nonisolated(unsafe) var counter = UInt32.random(in: 0...0xFFFFFF)
// 5 bytes of random/machine identifier, randomly initialize 5 bytes
let machineId = {
    var random5 = [UInt8](repeating: 0, count: 5)
    _ = SecRandomCopyBytes(kSecRandomDefault, random5.count, &random5)
    return random5
}()
let counterQueue = DispatchQueue(label: "ObjectId_generator")

func newObjectId() -> String {
    // 4 bytes: timestamp
    let timestamp = UInt32(Date().timeIntervalSince1970)
    let tsBE = timestamp.bigEndian
    var data = Data()
    data.append( withUnsafeBytes(of: tsBE) { Data($0) } )

    // 5 bytes: random/machine identifier
    data.append(contentsOf: machineId)

    // 3 bytes: counter (incremented each time)
    let count: UInt32 = counterQueue.sync {
        counter = (counter + 1) & 0xFFFFFF
        return counter
    }
    let counterBytes: [UInt8] = [
        UInt8((count >> 16) & 0xFF),
        UInt8((count >> 8) & 0xFF),
        UInt8(count & 0xFF)
    ]
    data.append(contentsOf: counterBytes)

    // convert data to a 24‐character hex string
    return data.map { String(format: "%02x", $0) }.joined()
}

@available(iOS 13.0, *)
@objc(RadarOfflineManager) @objcMembers
class RadarOfflineManager: NSObject, @unchecked Sendable { // unchecked Sendable, all params are/must be modified in DispatchQueue.global(qos: .default)
    var geofences = [RadarGeofence]()
    var defaultTrackingOptions: RadarTrackingOptions?
    var onTripTrackingOptions: RadarTrackingOptions?
    var inGeofenceTrackingOptions: RadarTrackingOptions?
    var inGeofenceTrackingTags = [String]()
    var lastSyncTime = Date(timeIntervalSince1970: 0)
    
    override init() {
        guard let bridge = RadarSwiftBridgeHolder.shared else {
            return
        }
        do {
            let offlineDataPath = RadarFileStorage.path(for: "offlineData.json").path
            guard let offlineData = try RadarFileStorage.readJSON(at: offlineDataPath) as? [String: Any] else {
                return
            }
            guard let geofenceJSON = offlineData["geofences"] as? [[String: Any]] else {
                return
            }
            // load local offline data from file
            geofences = bridge.RadarGeofences(from: geofenceJSON) ?? [];
            if let options = offlineData["defaultTrackingOptions"] as? [String: Any] {
                defaultTrackingOptions = RadarTrackingOptions(from: options)
            }
            if let options = offlineData["onTripTrackingOptions"] as? [String: Any] {
                onTripTrackingOptions = RadarTrackingOptions(from: options)
            }
            if let options = offlineData["inGeofenceTrackingOptions"] as? [String: Any] {
                inGeofenceTrackingOptions = RadarTrackingOptions(from: options)
                inGeofenceTrackingTags = options["tags"] as? [String] ?? []
            }
            if let lastSyncTimeString = offlineData["lastSyncTime"] as? String {
                lastSyncTime = RadarUtils.isoDateFormatter.date(from: lastSyncTimeString) ?? Date(timeIntervalSince1970: 0)
            }
        } catch {
            print("Unable to load local json")
        }
    }
    
    internal func getOfflineDataRequest() -> [String: Any] {
        return [
            "location": [
                "latitude": RadarState.lastLocation().coordinate.latitude,
                "longitude": RadarState.lastLocation().coordinate.longitude,
            ],
            "geofenceIds": geofences.map(\._id),
            "lastSyncTime": RadarUtils.isoDateFormatter.string(for: lastSyncTime) ?? "",
        ]
    }
    
    internal func updateOfflineData(result: RadarAPIClient.OfflineData, time: Date) {
        // only modify the values in global default dispatch queue for concurrency
        DispatchQueue.global(qos: .default).sync {
            do {
                let offlineDataPath = RadarFileStorage.path(for: "offlineData.json").path
                geofences.removeAll(where: { result.removeGeofences.contains($0._id) })
                geofences.append(contentsOf: result.newGeofences)
                
                defaultTrackingOptions = result.defaultTrackingOptions
                onTripTrackingOptions = result.onTripTrackingOptions
                inGeofenceTrackingOptions = result.inGeofenceTrackingOptions
                inGeofenceTrackingTags = result.inGeofenceTrackingTags
                
                let newData: [String: Any] = [
                    "geofences": geofences.map{ $0.dictionaryValue() },
                    "defaultTrackingOptions": defaultTrackingOptions?.dictionaryValue() ?? "",
                    "onTripTrackingOptions": onTripTrackingOptions?.dictionaryValue() ?? "",
                    "inGeofenceTrackingOptions": inGeofenceTrackingOptions?.dictionaryValue() ?? "",
                    "inGeofenceTrackingTags": inGeofenceTrackingTags,
                    "lastSyncTime": RadarUtils.isoDateFormatter.string(from: time),
                ]
                
                try RadarFileStorage.createDirectory()
                try RadarFileStorage.writeJSON(at: offlineDataPath, with: newData)
                
                print("Completed sync")
            } catch {
                print("Unable to sync data \(error.localizedDescription)")
                RadarLogger.shared.warning("Unable to sync offline data")
            }
        }
        
    }
    
    func createGeofenceEvent(geofence: RadarGeofence, location: CLLocation, type: String) -> [String: Any] {
        let now = RadarUtils.isoDateFormatter.string(from: Date())
        return [
            "_id": newObjectId(), // ???
            "createdAt": now,
            "actualCreatedAt": now,
            // figure out the import scope issue later ???
            "live": RadarUtils.live,
            "type": type,
            "geofence": geofence.dictionaryValue(),
            "verification": RadarEventVerification.unverify.rawValue,
            "confidence": RadarEventConfidence.low.rawValue, // ??? maybe use accuracy?
            "duration": 0,
            "location": [
                "coordinates": [location.coordinate.longitude, location.coordinate.latitude],
            ],
            "locationAccuracy": location.horizontalAccuracy,
            "replayed": false,
            "metadata": ["offline": true]
        ]
    }

    public func track(_ params: [String: Any]) -> [String: Any]? {
//        guard let bridge = RadarSwiftBridgeHolder.shared else {
//            return nil
//        }
        
        print("Tracked offline")
        
        guard let latitude = params["latitude"] as? Double, let longitude = params["longitude"] as? Double else {
            return nil
        }
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        guard let user = RadarState.radarUser() else {
            // no user associated, we can't perform any tracks offline
            return nil
        }
        
        // Events
        // calculate geofences within and generate events
        var events = [Any]()
        let userGeofences = user.geofences ?? []
        var newUserGeofences = [RadarGeofence]()
        for geofence in geofences {
            guard let inside = RadarOfflineManager.withinGeofence(geofence: geofence, point: location) else {
                continue
            }
            if (inside) {
                if (!userGeofences.contains(geofence)) {
                    // new geofence that the user is now inside, entry event
                    events.append(createGeofenceEvent(geofence: geofence, location: location, type: "user.entered_geofence"))
                }
                newUserGeofences.append(geofence)
            } else { // outside
                if (userGeofences.contains(geofence)) {
                    // user was inside this geofence before, exit event
                    events.append(createGeofenceEvent(geofence: geofence, location: location, type: "user.exited_geofence"))
                }
            }
        }
        
        // User
        // set user fields
        var newUser: [AnyHashable: Any] = user.dictionaryValue() // the json value for the updated user
        newUser["geofences"] = newUserGeofences.map{ $0.dictionaryValue }
        newUser["location"] = [
            "coordinates": [location.coordinate.longitude, location.coordinate.latitude ]
        ]
        
        // RTO
        // find which remote tracking options should be applied
        var trackingOptions: RadarTrackingOptions? = nil
        if (inGeofenceTrackingOptions != nil &&
            newUserGeofences.contains(where: { ($0.tag != nil) && inGeofenceTrackingTags.contains($0.tag!) })) {
            trackingOptions = inGeofenceTrackingOptions
        } else if (onTripTrackingOptions != nil &&
                   user.trip != nil) {
            trackingOptions = onTripTrackingOptions
        } else if (defaultTrackingOptions != nil) {
            trackingOptions = defaultTrackingOptions
        }
        
        let response: [String: Any] = [
            "user": newUser,
            "events": events,
            "meta": [
                "trackingOptions": trackingOptions?.dictionaryValue(),
                "sdkConfiguration": RadarSettings.sdkConfiguration?.dictionaryValue(),
            ]
        ]
        print(response)
        return response
    }
    
    // check if the point is within the geofence, for V1 we only consider circular geometry
    private static func withinGeofence(geofence: RadarGeofence, point: CLLocation) -> Bool? {
        var center: RadarCoordinate?
        var radius: Double = 100

        if let geometry = geofence.geometry as? RadarCircleGeometry {
            center = geometry.center
            radius = geometry.radius
        } else if let geometry = geofence.geometry as? RadarPolygonGeometry {
            center = geometry.center
            radius = geometry.radius
        }
        guard let center else { return nil }
        
        // within circle
        let centerLocation = CLLocation(latitude: center.coordinate.latitude, longitude: center.coordinate.longitude)
        
        return centerLocation.distance(from: point) <= radius
    }
}
