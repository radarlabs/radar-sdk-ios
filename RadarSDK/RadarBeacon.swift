//
//  RadarBeacon.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

// RadarBeacon in swift, currently only used by RadarSite
@objc class RadarBeacon: NSObject, Codable  {
    let id: String
    let uuid: String
    let minor: Int
    let major: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case uuid
        case major
        case minor
    }
}
