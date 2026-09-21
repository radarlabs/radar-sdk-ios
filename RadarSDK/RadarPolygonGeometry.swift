//
//  RadarPolygonGeometry.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc @implementation extension RadarPolygonGeometry {
    // The closed ring of coordinates. Keeps the historical `_coordinates` name declared in the
    // public header so Objective-C and Swift consumers are unaffected.
    // swiftlint:disable:next identifier_name
    var _coordinates: [RadarCoordinate]?
    var center: RadarCoordinate = RadarCoordinate()
    var radius: Double = 0

    override init() {
        super.init()
    }
}

extension RadarPolygonGeometry {
    /// Keeps the SDK-only constructor available without adding it to the public header.
    @objc(initWithCoordinates:center:radius:)
    convenience init(coordinates: [RadarCoordinate]?, center: RadarCoordinate, radius: Double) {
        self.init()
        self._coordinates = coordinates
        self.center = center
        self.radius = radius
    }
}
