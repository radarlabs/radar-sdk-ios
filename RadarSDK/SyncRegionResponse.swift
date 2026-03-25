//
//  SyncRegionResponse.swift
//  RadarSDK
//
//  Created by Alan Charles on 3/19/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

struct SyncRegionResponse {
    let geofences: [RadarGeofenceSwift]?
    let places: [RadarPlaceSwift]?
    let beacons: [RadarBeaconSwift]?
    let regionCenter: RadarCoordinateSwift?
    let regionRadius: Double?
}
