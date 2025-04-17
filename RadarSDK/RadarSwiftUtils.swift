//
//  RadarSwiftUtils.swift
//  RadarSDK
//
//  Created by Kenny Hu on 4/17/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import ActivityKit

@objc(RadarSwiftUtils) class RadarSwiftUtils: NSObject {
    @objc public static func areActivitiesEnabled() -> Bool{
        if #available(iOS 16.2, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        } else {
            return false
        }
    }
}
