//
//  LocationPushService.swift
//  LocationPushExtension
//
//  Created by ShiCheng Lu on 8/28/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import RadarSDK

class LocationPushService: NSObject, CLLocationPushServiceExtension {
    func didReceiveLocationPushPayload(_ payload: [String : Any], completion: @escaping () -> Void) {
        Radar.initialize(withAppGroup: "group.waypoint.data")
        Radar.didReceivePushNotificationPayload(payload) {
            completion()
        }
    }
}
