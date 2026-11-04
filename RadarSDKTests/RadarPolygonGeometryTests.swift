//
//  RadarPolygonGeometryTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarPolygonGeometryTests")
struct RadarPolygonGeometryTests {

    private static func coordinate(latitude: Double, longitude: Double) -> RadarCoordinate {
        RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))!
    }

    private static func square() -> [RadarCoordinate] {
        [
            coordinate(latitude: 40.0, longitude: -74.0),
            coordinate(latitude: 40.0, longitude: -73.0),
            coordinate(latitude: 41.0, longitude: -73.0),
            coordinate(latitude: 41.0, longitude: -74.0),
            coordinate(latitude: 40.0, longitude: -74.0),
        ]
    }

    @Test("Stores the coordinates, center, and radius it was initialized with")
    func storesCoordinatesCenterAndRadius() throws {
        let ring = Self.square()
        let center = Self.coordinate(latitude: 40.5, longitude: -73.5)
        let geometry = RadarPolygonGeometry(coordinates: ring, center: center, radius: 1234.5)

        let coordinates = try #require(geometry._coordinates)
        #expect(coordinates.count == 5)
        #expect(coordinates.first === ring.first)
        #expect(coordinates.last === ring.last)
        #expect(geometry.center === center)
        #expect(geometry.radius == 1234.5)
    }

    @Test("Keeps nil coordinates rather than substituting an empty ring")
    func keepsNilCoordinates() {
        let geometry = RadarPolygonGeometry(
            coordinates: nil, center: Self.coordinate(latitude: 0, longitude: 0), radius: 0)

        #expect(geometry._coordinates == nil)
        #expect(geometry.radius == 0)
    }

    @Test("Is a RadarGeofenceGeometry so callers can downcast from the base type")
    func isGeofenceGeometrySubclass() {
        let geometry: RadarGeofenceGeometry = RadarPolygonGeometry(
            coordinates: Self.square(), center: Self.coordinate(latitude: 1, longitude: 2), radius: 50)

        let polygon = geometry as? RadarPolygonGeometry
        #expect(polygon != nil)
        #expect(polygon?.radius == 50)
        #expect(geometry is RadarCircleGeometry == false)
    }

    @Test("Keeps the RadarPolygonGeometry Objective-C runtime name")
    func preservesObjectiveCRuntimeName() {
        let geometry = RadarPolygonGeometry(
            coordinates: Self.square(), center: Self.coordinate(latitude: 1, longitude: 2), radius: 10)

        #expect(NSStringFromClass(type(of: geometry)) == "RadarPolygonGeometry")
        #expect(geometry.isKind(of: RadarGeofenceGeometry.self))
    }

    @Test("Exposes the initializer and properties to Objective-C under their existing selectors")
    func preservesObjectiveCSelectors() throws {
        let ring = Self.square()
        let geometry = RadarPolygonGeometry(
            coordinates: ring, center: Self.coordinate(latitude: 1, longitude: 2), radius: 10)

        #expect(geometry.responds(to: NSSelectorFromString("initWithCoordinates:center:radius:")))
        #expect(geometry.responds(to: NSSelectorFromString("_coordinates")))
        #expect(geometry.responds(to: NSSelectorFromString("center")))
        #expect(geometry.responds(to: NSSelectorFromString("radius")))
        #expect(geometry.value(forKey: "radius") as? Double == 10)
        #expect(geometry.value(forKey: "center") as? RadarCoordinate === geometry.center)

        let coordinates = try #require(geometry.value(forKey: "_coordinates") as? [RadarCoordinate])
        #expect(coordinates.count == ring.count)
    }

    @Test("Parses a polygon geofence into a RadarPolygonGeometry")
    func parsesFromGeofenceObject() throws {
        let geofence = try #require(
            RadarGeofence(
                object: [
                    "_id": "geofence-1",
                    "description": "Neighborhood",
                    "tag": "neighborhood",
                    "externalId": "neighborhood-1",
                    "type": "polygon",
                    "geometryRadius": 500,
                    "geometryCenter": ["type": "Point", "coordinates": [-73.5, 40.5]],
                    "geometry": [
                        "type": "Polygon",
                        "coordinates": [
                            [[-74.0, 40.0], [-73.0, 40.0], [-73.0, 41.0], [-74.0, 41.0], [-74.0, 40.0]]
                        ],
                    ],
                ] as [String: Any]))

        let polygon = try #require(geofence.geometry as? RadarPolygonGeometry)
        #expect(polygon.radius == 500)
        #expect(abs(polygon.center.coordinate.latitude - 40.5) < 0.0001)
        #expect(abs(polygon.center.coordinate.longitude - (-73.5)) < 0.0001)

        let coordinates = try #require(polygon._coordinates)
        #expect(coordinates.count == 5)
        #expect(abs(coordinates[0].coordinate.latitude - 40.0) < 0.0001)
        #expect(abs(coordinates[0].coordinate.longitude - (-74.0)) < 0.0001)
        #expect(abs(coordinates[2].coordinate.latitude - 41.0) < 0.0001)
        #expect(abs(coordinates[2].coordinate.longitude - (-73.0)) < 0.0001)
    }

    @Test("Serializes back through RadarGeofence.dictionaryValue")
    func serializesThroughGeofenceDictionaryValue() throws {
        let geofence = try #require(
            RadarGeofence(
                object: [
                    "_id": "geofence-1",
                    "description": "Neighborhood",
                    "tag": "neighborhood",
                    "externalId": "neighborhood-1",
                    "type": "polygon",
                    "geometryRadius": 500,
                    "geometryCenter": ["type": "Point", "coordinates": [-73.5, 40.5]],
                    "geometry": [
                        "type": "Polygon",
                        "coordinates": [
                            [[-74.0, 40.0], [-73.0, 40.0], [-73.0, 41.0], [-74.0, 41.0], [-74.0, 40.0]]
                        ],
                    ],
                ] as [String: Any]))

        let dictionary = geofence.dictionaryValue()
        #expect(dictionary["type"] as? String == "Polygon")
        #expect(dictionary["geometryRadius"] as? Double == 500)

        let center = try #require(dictionary["geometryCenter"] as? [String: Any])
        #expect(center["type"] as? String == "Point")

        let coordinates = try #require(dictionary["coordinates"] as? [[[NSNumber]]])
        #expect(coordinates.count == 1)
        #expect(coordinates[0].count == 5)
        #expect(abs(coordinates[0][0][0].doubleValue - (-74.0)) < 0.0001)
        #expect(abs(coordinates[0][0][1].doubleValue - 40.0) < 0.0001)

        let geometry = try #require(dictionary["geometry"] as? [String: Any])
        #expect(geometry["type"] as? String == "Polygon")
        #expect((geometry["coordinates"] as? [[[NSNumber]]])?.count == 1)
    }
}
