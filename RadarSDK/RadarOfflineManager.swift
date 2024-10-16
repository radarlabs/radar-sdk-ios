//
//  File.swift
//  RadarSDK
//
//  Created by Kenny Hu on 10/16/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import RadarSDK

@objc(RadarOfflineManager) class RadarOfflineManager: NSObject {
    @objc public static func contextualizeLocation(_ location: CLLocation, completionHandler: @escaping (RadarConfig?) -> Void) {
        var newGeofenceIds = [String]()
        var newGeofenceTags = [String]()
        // get all the nearby geofences
        let nearbyGeofences = RadarState.nearbyGeofences()
        if (nearbyGeofences == nil) {
            return completionHandler(nil)
        }
        // for each of the nearby geofences, check if the location is inside the geofence
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
                // something went wrong with the geofence geometry
                continue
            }
            if (isPointInsideCircle(center: center!.coordinate, radius: radius, point: location)) {
                newGeofenceIds.append(geofence._id)
                if (geofence.tag != nil) {
                    newGeofenceTags.append(geofence.tag!)
                }
            }    
        }
        RadarState.setGeofenceIds(newGeofenceIds)
        // if there are no rampup geofence tags, we never had ramped up so we do not need to ramp down (reason a little more about this)
        let rampUpGeofenceTagsOptional = RadarSettings.sdkConfiguration()?.inGeofenceTrackingOptionsTags
        if let rampUpGeofenceTags = rampUpGeofenceTagsOptional {

            let inRampedUpGeofence = !Set(rampUpGeofenceTags).isDisjoint(with: Set(newGeofenceTags))
            let sdkConfig = RadarSettings.sdkConfiguration()
            var newTrackingOptions: RadarTrackingOptions? = nil
            
            if inRampedUpGeofence {
                // ramp up
                newTrackingOptions = sdkConfig?.inGeofenceTrackingOptions
            } else {
                let to = Radar.getTripOptions()
                // ramp down if needed
                if let onTripOptions = sdkConfig?.onTripTrackingOptions,
                   let _ = Radar.getTripOptions() {
                    newTrackingOptions = onTripOptions
                } else {
                    newTrackingOptions = sdkConfig?.defaultTrackingOptions
                }
            }
            if (newTrackingOptions != nil) {
                let metaDict: [String: Any] = ["trackingOptions": newTrackingOptions?.dictionaryValue() as Any]
                let configDict: [String: Any] = ["meta": metaDict]
                if let radarConfig = RadarConfig.fromDictionary(configDict) {
                        completionHandler(radarConfig)
                }
            }
        }
        return completionHandler(nil)
    }
    
    private static func isPointInsideCircle(center: CLLocationCoordinate2D, radius: Double, point: CLLocation) -> Bool {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        let distance = centerLocation.distance(from: point)
        
        return distance <= radius
    }
}
