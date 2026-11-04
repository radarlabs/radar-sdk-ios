//
//  RadarGeofenceGeometryTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarGeofenceGeometryTests")
struct RadarGeofenceGeometryTests {

    private static func coordinate(latitude: Double, longitude: Double) -> RadarCoordinate {
        RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))!
    }

    @Test("Keeps the RadarGeofenceGeometry Objective-C runtime name")
    func preservesObjectiveCRuntimeName() {
        let geometry = RadarGeofenceGeometry()

        #expect(NSStringFromClass(type(of: geometry)) == "RadarGeofenceGeometry")
        #expect(NSClassFromString("RadarGeofenceGeometry") === RadarGeofenceGeometry.self)
        #expect(geometry.isKind(of: NSObject.self))
    }

    @Test("Is the Objective-C superclass of the circle and polygon geometries")
    func isSuperclassOfConcreteGeometries() {
        #expect(class_getSuperclass(RadarCircleGeometry.self) === RadarGeofenceGeometry.self)
        #expect(class_getSuperclass(RadarPolygonGeometry.self) === RadarGeofenceGeometry.self)
        #expect(class_getSuperclass(RadarGeofenceGeometry.self) === NSObject.self)
    }

    @Test("Builds an empty geometry from Objective-C -init")
    func objectiveCInitDoesNotTrap() throws {
        let cls = try #require(NSClassFromString("RadarGeofenceGeometry") as? NSObject.Type)
        let geometry = cls.init()

        #expect(geometry is RadarGeofenceGeometry)
    }

    @Test("Backs RadarGeofence.geometry with the concrete subclass for each geofence type")
    func geofenceGeometryIsConcreteSubclass() throws {
        let circle = try #require(
            RadarGeofence(
                object: [
                    "_id": "geofence-1",
                    "description": "Circle",
                    "type": "circle",
                    "geometryRadius": 100,
                    "geometryCenter": ["type": "Point", "coordinates": [-73.9, 40.7]],
                ] as [String: Any]))
        let polygon = try #require(
            RadarGeofence(
                object: [
                    "_id": "geofence-2",
                    "description": "Polygon",
                    "type": "polygon",
                    "geometryRadius": 100,
                    "geometryCenter": ["type": "Point", "coordinates": [-73.9, 40.7]],
                    "geometry": [
                        "type": "Polygon",
                        "coordinates": [[[-73.9, 40.7], [-73.8, 40.7], [-73.8, 40.8], [-73.9, 40.7]]],
                    ],
                ] as [String: Any]))

        let circleGeometry: RadarGeofenceGeometry = circle.geometry
        let polygonGeometry: RadarGeofenceGeometry = polygon.geometry
        #expect(circleGeometry is RadarCircleGeometry)
        #expect(polygonGeometry is RadarPolygonGeometry)
    }

    @Test("Accepts any geometry subclass where the SDK takes the base type")
    func geofenceAcceptsBaseType() throws {
        let center = Self.coordinate(latitude: 1, longitude: 2)
        let geometry: RadarGeofenceGeometry = RadarCircleGeometry(center: center, radius: 10)
        let geofence = try #require(
            RadarGeofence(
                id: "geofence-1", description: "Store", tag: nil, externalId: nil, metadata: nil,
                operatingHours: nil, geometry: geometry, dwellThreshold: nil, geofenceStopDetection: nil,
                activeIndoorModelId: nil))

        #expect(geofence.geometry === geometry)
    }
}
