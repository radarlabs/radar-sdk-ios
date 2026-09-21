//
//  RadarCircleGeometry.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc @implementation extension RadarCircleGeometry {
    var center: RadarCoordinate = RadarCoordinate()
    var radius: Double = 0

    override init() {
        super.init()
    }
}

extension RadarCircleGeometry {
    /// Keeps the SDK-only constructor available without adding it to the public header.
    @objc(initWithCenter:radius:)
    convenience init(center: RadarCoordinate, radius: Double) {
        self.init()
        self.center = center
        self.radius = radius
    }
}
