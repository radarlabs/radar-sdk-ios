//
//  File.swift
//  RadarSDK
//
//  Created by Kenny Hu on 10/16/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

@objc(RadarOfflineManager) class RadarOfflineManager: NSObject {

private static func getUserGeofencesFromLocation(location: CLLocation) -> [RadarGeofence] {
    //var newGeofenceIds = [String]()
    let nearbyGeofences = RadarState.nearbyGeofences()
    if (nearbyGeofences == nil) {
        return []
    }
    var userGeofences = [RadarGeofence]()
    for geofence in nearbyGeofences! {
        var center: RadarCoordinate?
        var radius: Double = 100

        if let geometry = geofence.geometry as? RadarCircleGeometry {
            center = geometry.center
            radius = geometry.radius
        } else if let geometry = geofence.geometry as? RadarPolygonGeometry {
            center = geometry.center
            radius = geometry.radius
        } else {
            // log error
            RadarLogger.sharedInstance().log(level:RadarLogLevel.error, message:"error parsing geometry with no circular representation")
            continue
        }
        if (isPointInsideCircle(center: center!.coordinate, radius: radius, point: location)) {
            userGeofences.append(geofence)
            //newGeofenceIds.append(geofence._id)
            RadarLogger.sharedInstance().log(level: RadarLogLevel.debug, message: "Radar offline manager detected user inside geofence: " + geofence._id)
        }
        
    }
    // we should wait for comparison before setting the geofence ids
    //RadarState.setGeofenceIds(newGeofenceIds)
    return userGeofences
}

    @objc public static func updateTrackingOptionsFromOfflineLocation(_ userGeofences: [RadarGeofence], completionHandler: @escaping (RadarConfig?) -> Void) {
        
        var newGeofenceTags = [String]()
        let sdkConfig = RadarSettings.sdkConfiguration()

        if (userGeofences.count == 0) {
            return completionHandler(nil)
        }
        for userGeofence in userGeofences {
            
            if (userGeofence.tag != nil) {
                newGeofenceTags.append(userGeofence.tag!)
            }
        }
        let rampUpGeofenceTagsOptional = RadarRemoteTrackingOptions.getGeofenceTags(key: "inGeofence", remoteTrackingOptions: sdkConfig?.remoteTrackingOptions)
        var inRampedUpGeofence = false
        if let rampUpGeofenceTags = rampUpGeofenceTagsOptional {
            inRampedUpGeofence = !Set(rampUpGeofenceTags).isDisjoint(with: Set(newGeofenceTags))
        }
        
        var newTrackingOptions: RadarTrackingOptions? = nil
            
        if inRampedUpGeofence {
            // ramp up
            RadarLogger.sharedInstance().log(level: RadarLogLevel.debug, message: "Ramping up from Radar offline manager")
            newTrackingOptions = RadarRemoteTrackingOptions.getTrackingOptions(key: "inGeofence", remoteTrackingOptions: sdkConfig?.remoteTrackingOptions)
        } else {
            // ramp down if needed
            if let onTripOptions = RadarRemoteTrackingOptions.getTrackingOptions(key: "onTrip", remoteTrackingOptions: sdkConfig?.remoteTrackingOptions),
                let _ = Radar.getTripOptions() {
                newTrackingOptions = onTripOptions
                RadarLogger.sharedInstance().log(level: RadarLogLevel.debug, message: "Ramping down from Radar offline manager to trip tracking options")
            } else {
                newTrackingOptions = RadarRemoteTrackingOptions.getTrackingOptions(key: "default", remoteTrackingOptions: sdkConfig?.remoteTrackingOptions)
                RadarLogger.sharedInstance().log(level: RadarLogLevel.debug, message: "Ramping down from Radar offline manager to default tracking options")
            }
        }
        if (newTrackingOptions != nil) {
            let metaDict: [String: Any] = ["trackingOptions": newTrackingOptions?.dictionaryValue() as Any]
            let configDict: [String: Any] = ["meta": metaDict]
            if let radarConfig = RadarConfig.fromDictionary(configDict) {
                    return completionHandler(radarConfig)
            }
        }
        return completionHandler(nil)
    }

    @objc public static func generateEventsFromOfflineLocations(_ location: CLLocation, userGeofences: [RadarGeofence], completionHandler: @escaping ([RadarEvent], RadarUser, CLLocation) -> Void) {
        let user = RadarState.radarUser()
        RadarLogger.sharedInstance().log(level: RadarLogLevel.Info, message: "Got this user: \(user)")
        if (user == nil) {
            RadarLogger.sharedInstance().log(level: RadarLogLevel.error, message: "error getting user from offline manager")
            return completionHandler([], user!, location)
        }
        
        
        // generate geofence entry and exit events 
        // geofence entry
        // we need to check the entire nearby geofences array
        let nearbyGeofences = RadarState.nearbyGeofences()
        let userGeofenceIds = RadarState.geofenceIds()
        var events = [RadarEvent]()
        for userGeofence in userGeofences {
            if (!userGeofenceIds.contains(userGeofence._id)) {
                RadarLogger.sharedInstance().log(level: RadarLogLevel.Info, message: "Adding geofence entry event for: \(userGeofence._id)")
                // geofence entry
                let eventDict: [String: Any] = [
                    "_id": userGeofence._id,
                    "createdAt": Date(),
                    "actualCreatedAt": Date(),
                    // figure out the import scope issue later
                    "live": RadarUtils.isLive(),
                    "type": "user.entered_geofence",
                    "geofence": userGeofence.dictionaryValue(),
                    "verification": RadarEventVerification.unverify.rawValue,
                    "confidence": RadarEventConfidence.low.rawValue,
                    "duration": 0,
                    "location": [
                        "coordinates": [location.coordinate.longitude, location.coordinate.latitude],
                        "accuracy": location.horizontalAccuracy
                    ],
                    "replayed": false,
                    "metadata": ["offline": true]
                ]
                if let event = RadarEvent(object: eventDict) {
                    events.append(event)
                }   
            }
        }
        for previousGeofenceId in userGeofenceIds {
            if (!userGeofenceIds.contains(previousGeofenceId)) {
                RadarLogger.sharedInstance().log(level: RadarLogLevel.Info, message: "Adding geofence exit event for: \(previousGeofenceId)")
                let eventDict: [String: Any] = [
                    "_id": previousGeofenceId,
                    "createdAt": Date(),
                    "actualCreatedAt": Date(),
                    "live": RadarUtils.isLive(),
                    "type": "user.exited_geofence",
                    // get the geofence from the nearby geofences array
                    "geofence": nearbyGeofences?.first(where: { $0._id == previousGeofenceId })?.dictionaryValue(),
                    "verification": RadarEventVerification.unverify.rawValue,
                    "confidence": RadarEventConfidence.low.rawValue,
                    "duration": 0,
                    "location": [
                        "coordinates": [location.coordinate.longitude, location.coordinate.latitude],
                        "accuracy": location.horizontalAccuracy
                    ],
                    "replayed": false,
                    "metadata": ["offline": true]
                ]
                // geofence exit
                if let event = RadarEvent(object: eventDict) {
                    events.append(event)
                }
            }
        }

        let newUserDict: [String: Any] = [
            "_id": user?._id,
            "userId": user?.userId,
            "deviceId": user?.deviceId,
            "description": user?.__description,
            "metadata": user?.metadata,
            "location": [
                "coordinates": [location.coordinate.longitude, location.coordinate.latitude],
                "accuracy": location.horizontalAccuracy
            ],
            "activityType": user?.activityType,
            "geofences": userGeofences,
            "place": user?.place,
            "beacons": user?.beacons,
            "stopped": RadarState.stopped(),
            "foreground": RadarUtils.foreground(),
            "country": user?.country,
            "state": user?.state,
            "dma": user?.dma,
            "postalCode": user?.postalCode,
            "nearbyPlaceChains": user?.nearbyPlaceChains,
            "segments": user?.segments,
            "topChains": user?.topChains,
            "source": RadarLocationSource.offline,
            "trip": user?.trip,
            "debug": user?.debug,
            "fraud": user?.fraud
        ]
        
        if let newUser = RadarUser(object: newUserDict) {
            completionHandler(events, newUser, location)
        } else {
            // error out
            RadarLogger.sharedInstance().log(level: RadarLogLevel.error, message: "error parsing user from offline manager")
            completionHandler(events, user!, location)
        }
    }
    
    private static func isPointInsideCircle(center: CLLocationCoordinate2D, radius: Double, point: CLLocation) -> Bool {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        let distance = centerLocation.distance(from: point)
        
        return distance <= radius
    }
      
}
