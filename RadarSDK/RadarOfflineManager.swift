//
//  RadarOfflineManager.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/15/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation


class RadarOfflineManager {
    
    let offlineTime: Date? = nil
    
    func track(params: [String: Any]) -> ([RadarEvent], RadarUser?, [RadarGeofence], RadarConfig?, String?) {
        let events = [RadarEvent]()
        let user: RadarUser? = nil
        let nearbyGeofences: [RadarGeofence] = []
        let config: RadarConfig? = nil
        let token: String? = nil
        
        
        
        let location = CLLocation(latitude: 32.6514, longitude: -161.4333)
        
        let geofences = [RadarGeofence]()
        
        var insideGeofences: [RadarGeofence] = []
        var outsideGeofences: [RadarGeofence] = []
        
        // list for now, maybe a data structure for performance
        for geofence in geofences {
            guard let geometry = geofence.geometry as? RadarCircleGeometry else {
                continue
            }
            let center = geometry.center.coordinate
            let distance = location.distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
            if (distance < geometry.radius) {
                insideGeofences.append(geofence)
            } else {
                outsideGeofences.append(geofence)
            }
        }
        
        // entries are inside - already inside
        
        
        // exits are outside - already outside
        
        
        
        
        
        
        
        return (events, user, nearbyGeofences, config, token);
    }
    
    
    
}
