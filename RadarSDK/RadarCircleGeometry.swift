//
//  RadarCircleGeometry.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarCircleGeometry)
@objcMembers
public final class RadarCircleGeometry: RadarGeofenceGeometry {
    public let center: RadarCoordinate
    public let radius: Double

    /// Keeps the hand-written Objective-C initializer working after the implementation moved to Swift.
    @objc(initWithCenter:radius:)
    public init(center: RadarCoordinate, radius: Double) {
        self.center = center
        self.radius = radius
        super.init()
    }
}
