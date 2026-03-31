//
//  RadarGeofence.swift
//  RadarSDK
//
//  Created by Alan Charles on 3/19/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

enum RadarGeofenceGeometrySwift: Codable, Sendable {
    case circle(center: RadarCoordinateSwift, radius: Double)
    case polygon(coordinates: [RadarCoordinateSwift], center: RadarCoordinateSwift, radius: Double)
    
   var center: RadarCoordinateSwift {
        switch self {
        case .circle(let center, _): return center
        case .polygon(_, let center, _): return center
        }
    }
    
   public var radius: Double {
        switch self {
        case .circle(_, let radius): return radius
        case .polygon(_, _, let radius): return radius
        }
    }
}

struct RadarGeofenceSwift: Codable, Sendable {
    let id: String
    let description: String
    let tag: String?
    let externalId: String?
    let geometry: RadarGeofenceGeometrySwift
    let dwellThreshold: Double?
    let geofenceStopDetection: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case description
        case tag
        case externalId
        case type
        case geometryRadius
        case geometryCenter
        case geometry
        case dwellThreshold
        case stopDetection
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        tag = try container.decodeIfPresent(String.self, forKey: .tag)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        dwellThreshold = try container.decodeIfPresent(Double.self, forKey: .dwellThreshold)
        geofenceStopDetection = try container.decodeIfPresent(Bool.self, forKey: .stopDetection)
        
        let type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        let radius = try container.decodeIfPresent(Double.self, forKey: .geometryRadius) ?? 0
        let center = try container.decodeIfPresent(GeoJSONPoint.self, forKey: .geometryCenter)
            .map { RadarCoordinateSwift(latitude: $0.coordinates[1], longitude: $0.coordinates[0]) }
            ?? RadarCoordinateSwift(latitude: 0, longitude: 0)
        
        switch type.lowercased() {
        case "polygon", "isochrone":
            let geoJSON = try container.decodeIfPresent(GeoJSONPolygon.self, forKey: .geometry)
            let coords = geoJSON?.coordinates.first?.map {
                RadarCoordinateSwift(latitude: $0[1], longitude: $0[0])
            } ?? []
            geometry = .polygon(coordinates: coords, center: center, radius: radius)
            default :
            geometry = .circle(center: center, radius: radius)
        }
    }
    
    init(id: String, description: String, tag: String?, externalId: String?,
         geometry: RadarGeofenceGeometrySwift, dwellThreshold: Double?, geofenceStopDetection: Bool?) {
        self.id = id
        self.description = description
        self.tag = tag
        self.externalId = externalId
        self.geometry = geometry
        self.dwellThreshold = dwellThreshold
        self.geofenceStopDetection = geofenceStopDetection
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(tag, forKey: .tag)
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encodeIfPresent(dwellThreshold, forKey: .dwellThreshold)
        try container.encodeIfPresent(geofenceStopDetection, forKey: .stopDetection)
        
        switch geometry {
        case .circle(let center, let radius):
            try container.encode("circle", forKey: .type)
            try container.encode(radius, forKey: .geometryRadius)
            try container.encode(GeoJSONPoint(coordinates: [center.longitude, center.latitude]), forKey: .geometryCenter)
        case .polygon(let coords, let center, let radius):
            try container.encode("polygon", forKey: .type)
            try container.encode(radius, forKey: .geometryRadius)
            try container.encode(GeoJSONPoint(coordinates: [center.longitude, center.latitude]), forKey: .geometryCenter)
            let ring = coords.map { [$0.longitude, $0.latitude] }
            try container.encode(GeoJSONPolygon(coordinates: [ring]), forKey: .geometry)
        }
    }
}

private struct GeoJSONPoint: Codable, Sendable {
    let coordinates: [Double]
}

private struct GeoJSONPolygon: Codable, Sendable {
    let coordinates: [[[Double]]]
}
