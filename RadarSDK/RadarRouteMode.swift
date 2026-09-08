//
//  RadarRouteMode.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarRouteModeUtils)
final class RadarRouteModeUtils: NSObject {

    /// Keeps the hand-written Objective-C selector working after the implementation moved to Swift.
    ///
    /// Mirrors the original `switch`, which compared the whole value rather than testing bits, so a
    /// combined mask such as `foot | car` still returns `"unknown"`.
    @objc(stringForMode:)
    static func stringForMode(_ mode: RadarRouteMode) -> String {
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
