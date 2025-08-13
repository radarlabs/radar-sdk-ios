//
//  RadarInAppMessage.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 8/13/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc @objcMembers
public class RadarInAppMessage : NSObject {
    static public func getMessage() -> String {
        return "Hello, World!"
    }
}
