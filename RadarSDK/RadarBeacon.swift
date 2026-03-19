//
//  RadarBeacon.swift
//  RadarSDK
//
//  Created by Alan Charles on 3/19/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

public struct RadarBeaconSwift: Codable, Sendable {
    public let id: String
    public let description: String?
    public let tag: String?
    public let externalId: String?
    public let uuid: String
    public let major: String
    public let minor: String
    public let geometry: RadarCoordinateSwift?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case description
        case tag
        case externalId
        case uuid
        case major
        case minor
        case geometry
    }
    
   public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        tag = try container.decodeIfPresent(String.self, forKey: .tag)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        uuid = try container.decode(String.self, forKey: .uuid)
        major = try container.decode(String.self, forKey: .major)
        minor = try container.decode(String.self, forKey: .minor)
        
        if let geoJSON = try container.decodeIfPresent(GeoJSONPoint.self, forKey: .geometry) {
            geometry = RadarCoordinateSwift(latitude: geoJSON.coordinates[1], longitude: geoJSON.coordinates[0])
        } else {
            geometry = nil
        }
    }
    
   public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(tag, forKey: .tag)
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(major, forKey: .major)
        try container.encode(minor, forKey: .minor)
        if let geometry = geometry {
            try container.encode(
                GeoJSONPoint(coordinates: [geometry.longitude, geometry.latitude]),
                forKey: .geometry
            )
        }
    }
}

private struct GeoJSONPoint: Codable, Sendable {
    let coordinates: [Double]
}
