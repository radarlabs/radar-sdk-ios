//
//  RadarCircleGeometryTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarCircleGeometryTests")
struct RadarCircleGeometryTests {

    private static func coordinate(latitude: Double, longitude: Double) -> RadarCoordinate {
        RadarCoordinate(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))!
    }

    @Test("Stores the center and radius it was initialized with")
    func storesCenterAndRadius() {
        let center = Self.coordinate(latitude: 40.7, longitude: -73.9)
        let geometry = RadarCircleGeometry(center: center, radius: 100)

        #expect(geometry.center === center)
        #expect(geometry.center.coordinate.latitude == 40.7)
        #expect(geometry.center.coordinate.longitude == -73.9)
        #expect(geometry.radius == 100)
    }

    @Test("Keeps a zero radius rather than substituting a default")
    func keepsZeroRadius() {
        let geometry = RadarCircleGeometry(center: Self.coordinate(latitude: 0, longitude: 0), radius: 0)

        #expect(geometry.radius == 0)
    }

    @Test("Is a RadarGeofenceGeometry so callers can downcast from the base type")
    func isGeofenceGeometrySubclass() {
        let geometry: RadarGeofenceGeometry = RadarCircleGeometry(
            center: Self.coordinate(latitude: 1, longitude: 2), radius: 50)

        let circle = geometry as? RadarCircleGeometry
        #expect(circle != nil)
        #expect(circle?.radius == 50)
        #expect(geometry is RadarPolygonGeometry == false)
    }

    @Test("Keeps the RadarCircleGeometry Objective-C runtime name")
    func preservesObjectiveCRuntimeName() {
        let geometry = RadarCircleGeometry(center: Self.coordinate(latitude: 1, longitude: 2), radius: 10)

        #expect(NSStringFromClass(type(of: geometry)) == "RadarCircleGeometry")
        #expect(geometry.isKind(of: RadarGeofenceGeometry.self))
    }

    @Test("Exposes the initializer and properties to Objective-C under their existing selectors")
    func preservesObjectiveCSelectors() {
        let geometry = RadarCircleGeometry(center: Self.coordinate(latitude: 1, longitude: 2), radius: 10)

        #expect(geometry.responds(to: NSSelectorFromString("initWithCenter:radius:")))
        #expect(geometry.responds(to: NSSelectorFromString("center")))
        #expect(geometry.responds(to: NSSelectorFromString("radius")))
        #expect(geometry.value(forKey: "radius") as? Double == 10)
        #expect(geometry.value(forKey: "center") as? RadarCoordinate === geometry.center)
    }

    @Test("Parses a circle geofence into a RadarCircleGeometry")
    func parsesFromGeofenceObject() throws {
        let geofence = try #require(
            RadarGeofence(
                object: [
                    "_id": "geofence-1",
                    "description": "Store",
                    "tag": "store",
                    "externalId": "store-1",
                    "type": "circle",
                    "geometryRadius": 250,
                    "geometryCenter": ["type": "Point", "coordinates": [-73.9, 40.7]],
                ] as [String: Any]))

        let circle = try #require(geofence.geometry as? RadarCircleGeometry)
        #expect(circle.radius == 250)
        #expect(abs(circle.center.coordinate.latitude - 40.7) < 0.0001)
        #expect(abs(circle.center.coordinate.longitude - (-73.9)) < 0.0001)
    }

    @Test("Serializes back through RadarGeofence.dictionaryValue")
    func serializesThroughGeofenceDictionaryValue() throws {
        let geofence = try #require(
            RadarGeofence(
                object: [
                    "_id": "geofence-1",
                    "description": "Store",
                    "tag": "store",
                    "externalId": "store-1",
                    "type": "circle",
                    "geometryRadius": 250,
                    "geometryCenter": ["type": "Point", "coordinates": [-73.9, 40.7]],
                ] as [String: Any]))

        let dictionary = geofence.dictionaryValue()
        #expect(dictionary["type"] as? String == "Circle")
        #expect(dictionary["geometryRadius"] as? Double == 250)
        let center = try #require(dictionary["geometryCenter"] as? [String: Any])
        #expect(center["type"] as? String == "Point")
    }
}
