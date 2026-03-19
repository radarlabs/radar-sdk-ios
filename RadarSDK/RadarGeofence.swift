//
//  RadarGeofence.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

struct RadarCoordinate: Codable, Sendable, Equatable {
    static func == (lhs: RadarCoordinate, rhs: RadarCoordinate) -> Bool {
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
    public let geometryCenter: RadarCoordinate

    
    public let geometryRadius: Double
}
