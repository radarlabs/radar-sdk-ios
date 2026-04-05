//
//  RadarPlace.swift
//  RadarSDK
//
//  Created by Alan Charles on 3/19/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

struct RadarPlaceSwift: Codable, Sendable {
    let id: String
    let name: String
    let categories: [String]
    let location: RadarCoordinateSwift
    let group: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case categories
        case location
        case group
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        categories = try container.decodeIfPresent([String].self, forKey: .categories) ?? []
        group = try container.decodeIfPresent(String.self, forKey: .group)
        
        let geoJSON = try container.decode(GeoJSONPoint.self, forKey: .location)
        location = RadarCoordinateSwift(latitude: geoJSON.coordinates[1], longitude: geoJSON.coordinates[0])
    }
    
    init(id: String, name: String, categories: [String], location: RadarCoordinateSwift, group: String?) {
        self.id = id
        self.name = name
        self.categories = categories
        self.location = location
        self.group = group
    }
    
   func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(categories, forKey: .categories)
        try container.encodeIfPresent(group, forKey: .group)
        try container.encode(
            GeoJSONPoint(coordinates: [location.longitude, location.latitude]),
            forKey: .location
        )
    }
}

private struct GeoJSONPoint: Codable, Sendable {
    let coordinates: [Double]
}
