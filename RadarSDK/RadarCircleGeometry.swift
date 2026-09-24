//
//  RadarCircleGeometry.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents the geometry of a circle geofence.
@objc(RadarCircleGeometry)
@objcMembers
public final class RadarCircleGeometry: RadarGeofenceGeometry {
    /// The center of the circle geofence.
    public let center: RadarCoordinate

    /// The radius of the circle geofence in meters.
    public let radius: Double

    // Internal: the SDK builds geometries from API responses (RadarGeofence.m, via +Internal.h).
    @objc(initWithCenter:radius:)
    init(center: RadarCoordinate, radius: Double) {
        self.center = center
        self.radius = radius
        super.init()
    }
}
