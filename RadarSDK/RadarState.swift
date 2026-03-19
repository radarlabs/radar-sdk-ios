//
//  RadarState.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

class RadarState {
    
    public static var registeredNotifications: [NotificationValue]? {
        get {
            if let obj = RadarUserDefaults.object(forKey: .RegisteredNotifications),
               let data = try? JSONSerialization.data(withJSONObject: obj),
               let value = try? JSONDecoder().decode([NotificationValue].self, from: data) {
                return value
            }
            return nil
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let obj = try? JSONSerialization.jsonObject(with: data) {
                RadarUserDefaults.set(obj, forKey: .RegisteredNotifications)
            }
        }
    }
}
