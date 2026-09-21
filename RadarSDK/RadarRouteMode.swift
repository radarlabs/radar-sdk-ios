//
//  RadarRouteMode.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc @implementation extension RadarRouteModeUtils {
    override init() {
        super.init()
    }
    class func stringForMode(_ mode: RadarRouteMode) -> String {
        switch mode {
        case .foot:
            return "foot"
        case .bike:
            return "bike"
        case .car:
            return "car"
        case .truck:
            return "truck"
        case .motorbike:
            return "motorbike"
        default:
            return "unknown"
        }
    }
}
