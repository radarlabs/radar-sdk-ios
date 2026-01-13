//
//  GeoJSON.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

// Not true GeoJSON since there is no circles
enum GeoJSON: Codable {
    case point(coordinates: [Double])
    case polygon(coordinates: [[[Double]]])
    case circle(coordinates: [Double], radius: Double)
    
    enum CodingKeys: String, CodingKey {
        case type
        case coordinates
        case radius
    }

    private enum GeometryType: String, Codable {
        case Point
        case Polygon
        case Circle
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GeometryType.self, forKey: .type)

        switch type {
        case .Point:
            let coords = try container.decode([Double].self, forKey: .coordinates)
            guard coords.count == 2 || coords.count == 3 else {
                throw DecodingError.dataCorruptedError(
                    forKey: .coordinates,
                    in: container,
                    debugDescription: "Invalid number of values for a coordinate"
                )
            }
            self = .point(coordinates: coords)

        case .Polygon:
            let coords = try container.decode([[[Double]]].self, forKey: .coordinates)
            self = .polygon(coordinates: coords)
            
        case .Circle:
            let coords = try container.decode([Double].self, forKey: .coordinates)
            let radius = try container.decode(Double.self, forKey: .radius)
            self = .circle(coordinates: coords, radius: radius)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .point(let coordinates):
            try container.encode(GeometryType.Point, forKey: .type)
            try container.encode(coordinates, forKey: .coordinates)

        case .polygon(let coordinates):
            try container.encode(GeometryType.Polygon, forKey: .type)
            try container.encode(coordinates, forKey: .coordinates)
            
        case .circle(let coords, let radius):
            try container.encode(GeometryType.Circle, forKey: .type)
            try container.encode(coords, forKey: .coordinates)
            try container.encode(radius, forKey: .radius)
        }
    }
}
