//
//  RadarGeofence.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Sync Region Types

enum RadarGeofenceGeometrySwift: Codable, Sendable {
    case circle(center: RadarCoordinateSwift, radius: Double)
    case polygon(coordinates: [RadarCoordinateSwift], center: RadarCoordinateSwift, radius: Double)

    var center: RadarCoordinateSwift {
        switch self {
        case .circle(let center, _): return center
        case .polygon(_, let center, _): return center
        }
    }

    var radius: Double {
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

// MARK: - ObjC Bridge Types

struct RadarCoordinateCodable: Codable, Sendable, Equatable {
    static func == (lhs: RadarCoordinateCodable, rhs: RadarCoordinateCodable) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    let coordinate: CLLocationCoordinate2D

    private enum CodingKeys: String, CodingKey {
        case coordinates
    }

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let pair = try container.decode([Double].self, forKey: .coordinates)
        guard pair.count == 2 else {
            throw DecodingError.dataCorruptedError(forKey: .coordinates,
                                                   in: container,
                                                   debugDescription: "Expected [longitude, latitude]")
        }
        self.coordinate = CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode([coordinate.longitude, coordinate.latitude], forKey: .coordinates)
    }
}

enum RadarMetadataValue: Codable, Sendable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(Double.self) {
            self = .double(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported metadata value type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        }
    }

    func string() -> String? {
        if case let .string(value) = self {
            return value
        } else {
            return nil
        }
    }
}

/// This is a geofence from the raw dictionary conversion of RadarGeofence in ObjC.
struct RadarGeofence_Swift: Codable, Sendable, Equatable {

    /// The Radar ID of the geofence.
    public let _id: String

    /// The description of the geofence. Not to be confused with the `NSObject` `description` property.
    public let description: String?

    /// The tag of the geofence.
    public let tag: String?

    /// The external ID of the geofence.
    public let externalId: String?

    /// The optional set of custom key-value pairs for the geofence.
    public let metadata: [String: RadarMetadataValue]?

    /// The geometry of the geofence, which can be cast to either `RadarCircleGeometry` or `RadarPolygonGeometry`.
    public let geometryCenter: RadarCoordinateCodable


    public let geometryRadius: Double
}
