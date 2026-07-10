//
//  RadarState.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

class RadarState {
    public var registeredNotifications: [NotificationValue]? {
        get {
            if let obj = RadarUserDefaults.object(forKey: .RegisteredNotifications),
                JSONSerialization.isValidJSONObject(obj),
                let data = try? JSONSerialization.data(withJSONObject: obj),
                let value = try? JSONDecoder().decode([NotificationValue].self, from: data)
            {
                return value
            }
            return nil
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
                let obj = try? JSONSerialization.jsonObject(with: data)
            {
                RadarUserDefaults.set(obj, forKey: .RegisteredNotifications)
            }
        }
    }

    public var lastHeadingData: [String: Double]? {
        get {
            guard let dict = RadarUserDefaults.dictionary(forKey: .LastHeadingData) else {
                return nil
            }
            return dict.compactMapValues { ($0 as? NSNumber)?.doubleValue }
        }
        set {
            RadarUserDefaults.set(newValue, forKey: .LastHeadingData)
        }
    }
}
