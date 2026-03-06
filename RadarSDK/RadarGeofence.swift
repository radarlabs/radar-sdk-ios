//
//  RadarGeofence.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/2/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

// partial RadarGeofence in swift, currently only used by RadarSite
@objc class RadarGeofence: NSObject, Codable  {
    let id: String
    let geometry: GeoJSON
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case geometry
        case metadata
    }
}
