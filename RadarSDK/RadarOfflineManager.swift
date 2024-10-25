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
    @objc public static func contextualizeLocation(_ location: CLLocation, completionHandler: @escaping (RadarConfig?) -> Void) {
        var newGeofenceIds = [String]()
        var newGeofenceTags = [String]()
        let sdkConfig = RadarSettings.sdkConfiguration()
        let nearbyGeofences = RadarState.nearbyGeofences()
        if (nearbyGeofences == nil) {
            return completionHandler(nil)
        }
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
                newGeofenceIds.append(geofence._id)
                if (geofence.tag != nil) {
                    newGeofenceTags.append(geofence.tag!)
                }
                RadarLogger.sharedInstance().log(level: RadarLogLevel.debug, message: "Radar offline manager detected user inside geofence: " + geofence._id)
            }
        }
        RadarState.setGeofenceIds(newGeofenceIds)
        
        let rampUpGeofenceTagsOptional = getGeofenceTags(sdkConfiguration: sdkConfig)
        var inRampedUpGeofence = false
        if let rampUpGeofenceTags = rampUpGeofenceTagsOptional {
            inRampedUpGeofence = !Set(rampUpGeofenceTags).isDisjoint(with: Set(newGeofenceTags))
        }
        
        var newTrackingOptions: RadarTrackingOptions? = nil
            
        if inRampedUpGeofence {
            // ramp up
            RadarLogger.sharedInstance().log(level: RadarLogLevel.debug, message: "Ramping up from Radar offline manager")
            newTrackingOptions = getAlternativeTrackingOptionsWithKey(sdkConfiguration: sdkConfig, type: "inGeofence")
        } else {
            // ramp down if needed
            if let onTripOptions = getAlternativeTrackingOptionsWithKey(sdkConfiguration: sdkConfig, type: "onTrip"),
                let _ = Radar.getTripOptions() {
                newTrackingOptions = onTripOptions
                RadarLogger.sharedInstance().log(level: RadarLogLevel.debug, message: "Ramping down from Radar offline manager to trip tracking options")
            } else {
                newTrackingOptions = getAlternativeTrackingOptionsWithKey(sdkConfiguration: sdkConfig, type: "default")
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
    
    private static func isPointInsideCircle(center: CLLocationCoordinate2D, radius: Double, point: CLLocation) -> Bool {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        let distance = centerLocation.distance(from: point)
        
        return distance <= radius
    }
    
    private static func getAlternativeTrackingOptionsWithKey(sdkConfiguration: RadarSdkConfiguration?, type: String) -> RadarTrackingOptions? {
        if sdkConfiguration == nil {return nil}
        let alternativeTrackingOptions = sdkConfiguration?.alternativeTrackingOptions
        if (alternativeTrackingOptions == nil){
            return nil
        }
        for alternativeTrackingOptions in alternativeTrackingOptions! {
            if (alternativeTrackingOptions.type == type) {
                return alternativeTrackingOptions.trackingOptions
            }
        }
        return nil
    }
    
    private static func getGeofenceTags(sdkConfiguration: RadarSdkConfiguration?) -> [String]? {
        if sdkConfiguration == nil {return nil}
        let alternativeTrackingOptions = sdkConfiguration?.alternativeTrackingOptions
        if (alternativeTrackingOptions == nil){
            return nil
        }
        for alternativeTrackingOptions in alternativeTrackingOptions! {
            if (alternativeTrackingOptions.type == "inGeofence") {
                return alternativeTrackingOptions.geofenceTags
            }
        }
        return nil
    }
}
