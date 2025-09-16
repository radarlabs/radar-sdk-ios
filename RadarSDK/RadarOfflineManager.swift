//
//  RadarOfflineManager.swift
//  RadarSDK
//
//  Created by Kenny Hu on 10/16/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

@objc(RadarOfflineManager) @objcMembers
class RadarOfflineManager: NSObject {
    public static func getUserGeofencesFromLocation(_ location: CLLocation) -> [RadarGeofence] {
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
               RadarLogger.shared.log(level:RadarLogLevel.error, message:"error parsing geometry with no circular representation")
               continue
           }
           if (isPointInsideCircle(center: center!.coordinate, radius: radius, point: location)) {
               userGeofences.append(geofence)
               //newGeofenceIds.append(geofence._id)
               RadarLogger.shared.log(level: RadarLogLevel.debug, message: "Radar offline manager detected user inside geofence: " + geofence._id)
           }

       }

       return userGeofences
    }

    public static func updateTrackingOptionsFromOfflineLocation(_ userGeofences: [RadarGeofence], completionHandler: @escaping (RadarConfig?) -> Void) {
        var newGeofenceTags = [String]()
        let sdkConfig = RadarSettings.sdkConfiguration

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
            RadarLogger.shared.log(level: RadarLogLevel.debug, message: "Ramping up from Radar offline manager")
            newTrackingOptions = RadarRemoteTrackingOptions.getTrackingOptions(key: "inGeofence", remoteTrackingOptions: sdkConfig?.remoteTrackingOptions)
        } else {
            // ramp down if needed
            if let onTripOptions = RadarRemoteTrackingOptions.getTrackingOptions(key: "onTrip", remoteTrackingOptions: sdkConfig?.remoteTrackingOptions),
                let _ = Radar.getTripOptions() {
                newTrackingOptions = onTripOptions
                RadarLogger.shared.log(level: RadarLogLevel.debug, message: "Ramping down from Radar offline manager to trip tracking options")
            } else {
                newTrackingOptions = RadarRemoteTrackingOptions.getTrackingOptions(key: "default", remoteTrackingOptions: sdkConfig?.remoteTrackingOptions)
                RadarLogger.shared.log(level: RadarLogLevel.debug, message: "Ramping down from Radar offline manager to default tracking options")
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

    public static func generateEventsFromOfflineLocations(_ location: CLLocation, userGeofences: [RadarGeofence], completionHandler: @escaping ([RadarEvent], RadarUser, CLLocation) -> Void) {
        let user = RadarState.radarUser()
        RadarLogger.shared.log(level: RadarLogLevel.info, message: "Got this user: \(String(describing: user))")
        if (user == nil) {
            RadarLogger.shared.log(level: RadarLogLevel.error, message: "error getting user from offline manager")
            return completionHandler([], user!, location)
        }

        // generate geofence entry and exit events
        // geofence entry
        // we need to check the entire nearby geofences array
        let nearbyGeofences = RadarState.nearbyGeofences()
        let previousUserGeofenceIds = RadarState.geofenceIds()
        var events = [RadarEvent]()
        var newUserGeofenceIds = [String]()
        for userGeofence in userGeofences {
            if (!previousUserGeofenceIds.contains(userGeofence._id)) {
                RadarLogger.shared.log(level: RadarLogLevel.info, message: "Adding geofence entry event for: \(userGeofence._id)")
                // geofence entry
                let eventDict: [String: Any] = [
                    "_id": userGeofence._id,
                    "createdAt": RadarUtils.isoDateFormatter.string(from: Date()),
                    "actualCreatedAt": RadarUtils.isoDateFormatter.string(from: Date()),
                    // figure out the import scope issue later
                    "live": RadarUtils.isLive(),
                    "type": "user.entered_geofence",
                    "geofence": userGeofence.dictionaryValue(),
                    "verification": RadarEventVerification.unverify.rawValue,
                    "confidence": RadarEventConfidence.low.rawValue,
                    "duration": 0,
                    "location": [
                        "coordinates": [location.coordinate.longitude, location.coordinate.latitude],
                    ],
                    "locationAccuracy": location.horizontalAccuracy,
                    "replayed": false,
                    "metadata": ["offline": true]
                ]
                if let event = RadarEvent(object: eventDict) {
                    events.append(event)
                } else {
                    RadarLogger.shared.log(level: RadarLogLevel.error, message: "error parsing event from offline manager")
                }
            }
            newUserGeofenceIds.append(userGeofence._id)
        }
        for previousGeofenceId in previousUserGeofenceIds {
            if (!newUserGeofenceIds.contains(previousGeofenceId)) {
                RadarLogger.shared.log(level: RadarLogLevel.info, message: "Adding geofence exit event for: \(previousGeofenceId)")
                let eventDict: [String: Any] = [
                    "_id": previousGeofenceId,
                    "createdAt": RadarUtils.isoDateFormatter.string(from: Date()),
                    "actualCreatedAt": RadarUtils.isoDateFormatter.string(from: Date()),
                    "live": RadarUtils.isLive(),
                    "type": "user.exited_geofence",
                    // get the geofence from the nearby geofences array
                    "geofence": nearbyGeofences?.first(where: { $0._id == previousGeofenceId })?.dictionaryValue() as Any,
                    "verification": RadarEventVerification.unverify.rawValue,
                    "confidence": RadarEventConfidence.low.rawValue,
                    "duration": 0,
                    "location": [
                        "coordinates": [location.coordinate.longitude, location.coordinate.latitude],
                    ],
                    "locationAccuracy": location.horizontalAccuracy,
                    "replayed": false,
                    "metadata": ["offline": true]
                ]
                // geofence exit
                if let event = RadarEvent(object: eventDict) {
                    events.append(event)
                } else {
                    RadarLogger.shared.log(level: RadarLogLevel.error, message: "error parsing event from offline manager")
                }
            }
        }

        let newUserDict: [String: Any] = [
            "_id": user?._id as Any,
            "userId": user?.userId as Any,
            "deviceId": user?.deviceId as Any,
            "description": user?.__description as Any,
            "metadata": user?.metadata as Any,
            "location": [
                "coordinates": [location.coordinate.longitude, location.coordinate.latitude]
            ],
            "locationAccuracy": location.horizontalAccuracy,
            "activityType": user?.activityType as Any,
            "geofences": userGeofences.map { $0.dictionaryValue() as Any },
            "place": user?.place as Any,
            "beacons": user?.beacons as Any,
            "stopped": RadarState.stopped(),
            "foreground": RadarUtils.foreground(),
            "country": user?.country as Any,
            "state": user?.state as Any,
            "dma": user?.dma as Any,
            "postalCode": user?.postalCode as Any,
            "nearbyPlaceChains": user?.nearbyPlaceChains as Any,
            "segments": user?.segments as Any,
            "topChains": user?.topChains as Any,
            "source": RadarLocationSource.offline,
            "trip": user?.trip as Any,
            "debug": user?.debug as Any,
            "fraud": user?.fraud as Any
        ]

        RadarState.setGeofenceIds(newUserGeofenceIds)

        if let newUser = RadarUser(object: newUserDict) {
            completionHandler(events, newUser, location)
        } else {
            // error out
            RadarLogger.shared.log(level: RadarLogLevel.error, message: "error parsing user from offline manager")
            completionHandler(events, user!, location)
        }
    }

    private static func isPointInsideCircle(center: CLLocationCoordinate2D, radius: Double, point: CLLocation) -> Bool {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        let distance = centerLocation.distance(from: point)

        return distance <= radius
    }
}
