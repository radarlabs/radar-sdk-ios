//
//  RadarSwiftBridge.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc
public protocol RadarSwiftBridge {
    func RadarEvents(from object: Any) -> [RadarEvent]?
    func RadarGeofences(from object: Any) -> [RadarGeofence]?
}

@objc @objcMembers
public class RadarSwiftBridgeHolder: NSObject {
    nonisolated(unsafe) public static var shared: RadarSwiftBridge?
}
