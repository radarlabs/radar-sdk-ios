//
//  RadarPolygonGeometry.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarPolygonGeometry)
@objcMembers
final class RadarPolygonGeometry: RadarGeofenceGeometry {
    // The closed ring of coordinates. Keeps the historical `_coordinates` name declared in the
    // public header so Objective-C and Swift consumers are unaffected.
    // swiftlint:disable:next identifier_name
    let _coordinates: [RadarCoordinate]?
    let center: RadarCoordinate
    let radius: Double

    /// Keeps the hand-written Objective-C initializer working after the implementation moved to Swift.
    @objc(initWithCoordinates:center:radius:)
    init(coordinates: [RadarCoordinate]?, center: RadarCoordinate, radius: Double) {
        self._coordinates = coordinates
        self.center = center
        self.radius = radius
        super.init()
    }
}
