//
//  RadarCircleGeometry.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarCircleGeometry)
public final class RadarCircleGeometry: RadarGeofenceGeometry {
    @objc public let center: RadarCoordinate
    @objc public let radius: Double

    /// Keeps the hand-written Objective-C initializer working after the implementation moved to Swift.
    @objc(initWithCenter:radius:) public
    init(center: RadarCoordinate, radius: Double) {
        self.center = center
        self.radius = radius
        super.init()
    }
}
