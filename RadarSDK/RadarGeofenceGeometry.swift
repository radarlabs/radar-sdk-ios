//
//  RadarGeofenceGeometry.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

// Not final: RadarCircleGeometry and RadarPolygonGeometry subclass it.
/// Represents the geometry of a geofence.
@objc(RadarGeofenceGeometry)
@objcMembers
public class RadarGeofenceGeometry: NSObject {
    // Internal: the SDK only returns the concrete subclasses.
    override init() {
        super.init()
    }
}
