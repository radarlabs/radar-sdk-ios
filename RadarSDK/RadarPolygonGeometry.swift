//
//  RadarPolygonGeometry.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents the geometry of polygon geofence.
@objc(RadarPolygonGeometry)
@objcMembers
public final class RadarPolygonGeometry: RadarGeofenceGeometry {
    // The closed ring of coordinates. Keeps the historical `_coordinates` name declared in the
    // public header so Objective-C and Swift consumers are unaffected.
    /// The geometry of the polygon geofence. A closed ring of coordinates.
    public let _coordinates: [RadarCoordinate]?  // swiftlint:disable:this identifier_name

    /// The calculated centroid of the polygon geofence.
    public let center: RadarCoordinate

    /// The calculated radius of the polygon geofence in meters.
    public let radius: Double

    // Internal: the SDK builds geometries from API responses (RadarGeofence.m, via +Internal.h).
    @objc(initWithCoordinates:center:radius:)
    init(coordinates: [RadarCoordinate]?, center: RadarCoordinate, radius: Double) {
        self._coordinates = coordinates
        self.center = center
        self.radius = radius
        super.init()
    }
}
