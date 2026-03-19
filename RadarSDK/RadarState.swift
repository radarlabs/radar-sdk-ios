//
//  RadarState.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

class RadarState {
    
    public static var registeredNotifications: [NotificationValue]? {
        get { return RadarUserDefaults.object(forKey: .RegisteredNotifications) as? [NotificationValue] }
        set { RadarUserDefaults.set(newValue, forKey: .RegisteredNotifications) }
    }
}
