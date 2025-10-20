//
//  RadarState.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 10/17/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

class RadarState {
    static var registeredNotifications: [[String: Any]] {
        get {
            UserDefaults.standard.array(forKey: "radar-registeredNotifications") as? [[String: Any]] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "radar-registeredNotifications")
        }
    }
}
