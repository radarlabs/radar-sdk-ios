//
//  RadarGeofence.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

/// Represents a geofence.
///
/// See [Geofences Documentation](https://radar.com/documentation/geofences)
public class RadarGeofence: NSObject, Codable, @unchecked Sendable {

    /// The Radar ID of the geofence.
    public let _id: String

    /// The description of the geofence. Not to be confused with the `NSObject` `description` property.
    public let __description: String

    /// The tag of the geofence.
    public let tag: String?

    /// The external ID of the geofence.
    public let externalId: String?

    /// The optional set of custom key-value pairs for the geofence.
    public let metadata: [String: Any]?

    /// The geometry of the geofence, which can be cast to either `RadarCircleGeometry` or `RadarPolygonGeometry`.
    public let geometry: RadarGeofenceGeometry

    /// The optional operating hours for the geofence.
    public let operatingHours: RadarOperatingHours?

    // MARK: - Internal Initializers

    init(id: String, description: String, tag: String?, externalId: String?, metadata: [String: Any]?, operatingHours: RadarOperatingHours?, geometry: RadarGeofenceGeometry) {
        self._id = id
        self.__description = description
        self.tag = tag
        self.externalId = externalId
        self.metadata = metadata
        self.operatingHours = operatingHours
        self.geometry = geometry
    }

    // MARK: - Class Methods

    class func geofencesFromObject(_ object: Any) -> [RadarGeofence]? {
        guard let arr = object as? [Any] else { return nil }
        var geofences: [RadarGeofence] = []
        for item in arr {
            guard let geofence = RadarGeofence(object: item) else { return nil }
            geofences.append(geofence)
        }
        return geofences
    }

    public class func arrayForGeofences(_ geofences: [RadarGeofence]?) -> [[String: Any]]? {
        guard let geofences = geofences else { return nil }
        return geofences.map { $0.dictionaryValue() }
    }

    // MARK: - Dictionary Serialization

    @objc public func dictionaryValue() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case description
        case tag
        case externalId
        case metadata
        case type
        case geometryRadius
        case geometryCenter
        case geometry
        case operatingHours
    }

    private struct CodableCoordinate: Codable, Sendable {
        let type: String?
        let coordinates: [Double]
    }

    private struct CodablePolygonGeometry: Codable, Sendable {
        let coordinates: [[[Double]]]
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self._id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        self.__description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.tag = try container.decodeIfPresent(String.self, forKey: .tag)
        self.externalId = try container.decodeIfPresent(String.self, forKey: .externalId)

        if let metadataJSON = try container.decodeIfPresent([String: JSONCodableValue].self, forKey: .metadata) {
            self.metadata = metadataJSON.mapValues(\.anyValue)
        } else {
            self.metadata = nil
        }

        if let hoursDict = try container.decodeIfPresent([String: [[String]]].self, forKey: .operatingHours) {
            self.operatingHours = RadarOperatingHours(dictionary: hoursDict as [AnyHashable: Any])
        } else {
            self.operatingHours = nil
        }

        let type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        let radius = try container.decodeIfPresent(Double.self, forKey: .geometryRadius) ?? 0
        let centerCoord = try container.decodeIfPresent(CodableCoordinate.self, forKey: .geometryCenter)

        let center: RadarCoordinate
        if let coords = centerCoord?.coordinates, coords.count == 2 {
            center = RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0]))
        } else {
            center = RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        }

        switch type.lowercased() {
        case "circle":
            self.geometry = RadarCircleGeometry(center: center, radius: radius)
        case "polygon", "isochrone":
            if let geo = try container.decodeIfPresent(CodablePolygonGeometry.self, forKey: .geometry),
               let ring = geo.coordinates.first {
                let coords = ring.map { pair -> RadarCoordinate in
                    RadarCoordinate(coordinate: CLLocationCoordinate2D(
                        latitude: pair.count > 1 ? pair[1] : 0,
                        longitude: pair.count > 0 ? pair[0] : 0
                    ))
                }
                self.geometry = RadarPolygonGeometry(coordinates: coords, center: center, radius: radius)
            } else {
                self.geometry = RadarPolygonGeometry(coordinates: [], center: center, radius: radius)
            }
        default:
            self.geometry = RadarGeofenceGeometry()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(_id, forKey: .id)
        try container.encode(__description, forKey: .description)
        try container.encodeIfPresent(tag, forKey: .tag)
        try container.encodeIfPresent(externalId, forKey: .externalId)

        if let metadata = metadata {
            try container.encode(metadata.mapValues { JSONCodableValue.from($0) }, forKey: .metadata)
        }

        if let operatingHours = operatingHours {
            try container.encode(operatingHours.hours, forKey: .operatingHours)
        }

        if let circle = geometry as? RadarCircleGeometry {
            try container.encode("circle", forKey: .type)
            try container.encode(circle.radius, forKey: .geometryRadius)
            try container.encode(
                CodableCoordinate(type: "Point", coordinates: [circle.center.coordinate.longitude, circle.center.coordinate.latitude]),
                forKey: .geometryCenter
            )
        } else if let polygon = geometry as? RadarPolygonGeometry {
            try container.encode("polygon", forKey: .type)
            try container.encode(polygon.radius, forKey: .geometryRadius)
            try container.encode(
                CodableCoordinate(type: "Point", coordinates: [polygon.center.coordinate.longitude, polygon.center.coordinate.latitude]),
                forKey: .geometryCenter
            )
            if let coords = polygon._coordinates {
                let coordArrays = coords.map { [$0.coordinate.longitude, $0.coordinate.latitude] }
                try container.encode(CodablePolygonGeometry(coordinates: [coordArrays]), forKey: .geometry)
            }
        }
    }

    // MARK: - Private Helpers

    private static func parsePolygonCoordinates(from dict: [String: Any]) -> [RadarCoordinate]? {
        guard let geometryObj = dict["geometry"] as? [String: Any],
              let coordinatesArr = geometryObj["coordinates"] as? [Any],
              coordinatesArr.count == 1,
              let polygonArr = coordinatesArr[0] as? [[Any]] else {
            return nil
        }

        var coordinates: [RadarCoordinate] = []
        for polygonCoords in polygonArr {
            guard polygonCoords.count == 2,
                  let longitude = (polygonCoords[0] as? NSNumber)?.floatValue,
                  let latitude = (polygonCoords[1] as? NSNumber)?.floatValue else {
                return nil
            }
            coordinates.append(RadarCoordinate(coordinate: CLLocationCoordinate2D(
                latitude: CLLocationDegrees(latitude),
                longitude: CLLocationDegrees(longitude)
            )))
        }
        return coordinates
    }

}

// MARK: - JSON Codable Helper

private enum JSONCodableValue: Codable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONCodableValue])
    case object([String: JSONCodableValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONCodableValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONCodableValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        }
    }

    var anyValue: Any {
        switch self {
        case .null: return NSNull()
        case .bool(let v): return v
        case .int(let v): return v
        case .double(let v): return v
        case .string(let v): return v
        case .array(let v): return v.map(\.anyValue)
        case .object(let v): return v.mapValues(\.anyValue)
        }
    }

    static func from(_ value: Any) -> JSONCodableValue {
        switch value {
        case is NSNull: return .null
        case let v as Bool: return .bool(v)
        case let v as Int: return .int(v)
        case let v as Double: return .double(v)
        case let v as String: return .string(v)
        case let v as [Any]: return .array(v.map(from))
        case let v as [String: Any]: return .object(v.mapValues(from))
        default: return .null
        }
    }
}
