//
//  RadarSite.swift
//  Example
//
//  Created by ShiCheng Lu on 10/30/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//
import Foundation
import RadarSDK

enum GeoJSONGeometry: Codable {
    case point([Double])
    case polygon([[[Double]]])

    private enum CodingKeys: CodingKey {
        case type
        case coordinates
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .point(let coords):
            try container.encode("Point", forKey: .type)
            try container.encode(coords, forKey: .coordinates)
        case .polygon(let coords):
            try container.encode("Polygon", forKey: .type)
            try container.encode(coords, forKey: .coordinates)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "Point":
            let coords = try container.decode([Double].self, forKey: .coordinates)
            self = .point(coords)
        case "Polygon":
            let coords = try container.decode([[[Double]]].self, forKey: .coordinates)
            self = .polygon(coords)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown GeoJSON type \(type)")
        }
    }
}

@objc protocol GeoJSON {
    var type: String { get }
}

@objc public class GeoJSONPoint: NSObject, GeoJSON, Codable {
    let coordinates: [Double]
    var type: String = "Point"
}

@objc public class GeoJSONPolygon: NSObject, GeoJSON, Codable {
    let coordinates: [[[Double]]]
    var type: String = "Polygon"
}

@objc public class RadarFloorplanCalibration: NSObject, Codable {
    let imageSize: [String: Int]
}

@objc public class RadarFloorplan: NSObject, Codable {
    let path: String
    let mimeType: String
    let geometry: GeoJSONPolygon
    let calibration: RadarFloorplanCalibration
}

@objc public class RadarSite: NSObject, Codable {
    let id: String
    let createdAt: Date
    let updatedAt: Date
    let project: String
    let live: Bool
    let _description: String
    let geometry: GeoJSONPoint
    //let geofences: [RadarGeofence]
    //let beacons: [RadarBeacon]
    let floorplan: RadarFloorplan
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case createdAt
        case updatedAt
        case project
        case live
        case _description = "description"
        case geometry
        case floorplan
    }
}

struct RadarSiteResponse: Codable {
    let site: RadarSite
}
