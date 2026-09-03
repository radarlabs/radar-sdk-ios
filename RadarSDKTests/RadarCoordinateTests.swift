//
//  RadarCoordinateTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarCoordinateTests")
struct RadarCoordinateTests {

    private static let latitude = 40.78382
    private static let longitude = -73.97536

    private static func geoJSON(longitude: Double, latitude: Double) -> [String: Any] {
        ["type": "Point", "coordinates": [longitude, latitude]]
    }

    private func makeDecoder(_ strategy: RadarCoordinateSwift.CodingStrategy?) -> JSONDecoder {
        let decoder = JSONDecoder()
        if let strategy {
            decoder.userInfo[RadarCoordinateSwift.codingStrategy] = strategy
        }
        return decoder
    }

    private func makeEncoder(_ strategy: RadarCoordinateSwift.CodingStrategy?) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        if let strategy {
            encoder.userInfo[RadarCoordinateSwift.codingStrategy] = strategy
        }
        return encoder
    }

    private func decode(
        _ json: String,
        strategy: RadarCoordinateSwift.CodingStrategy? = nil
    ) throws -> RadarCoordinateSwift {
        try makeDecoder(strategy).decode(RadarCoordinateSwift.self, from: Data(json.utf8))
    }

    private func encode(
        _ coordinate: RadarCoordinateSwift,
        strategy: RadarCoordinateSwift.CodingStrategy? = nil
    ) throws -> String? {
        String(data: try makeEncoder(strategy).encode(coordinate), encoding: .utf8)
    }

    // MARK: - LatLngDictionary coding strategy

    @Test("decodes a lat/lng dictionary when no strategy is set")
    func decodesDictionaryByDefault() throws {
        let coordinate = try decode(#"{"latitude": 40.78382, "longitude": -73.97536}"#)

        #expect(coordinate.latitude == Self.latitude)
        #expect(coordinate.longitude == Self.longitude)
    }

    @Test("decodes a lat/lng dictionary with the LatLngDictionary strategy")
    func decodesDictionaryStrategy() throws {
        let coordinate = try decode(
            #"{"latitude": 40.78382, "longitude": -73.97536}"#, strategy: .latLngDictionary)

        #expect(coordinate == RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude))
    }

    @Test("encodes a lat/lng dictionary when no strategy is set")
    func encodesDictionaryByDefault() throws {
        let json = try encode(RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude))

        #expect(json == #"{"latitude":40.78382,"longitude":-73.97536}"#)
    }

    @Test("encodes a lat/lng dictionary with the LatLngDictionary strategy")
    func encodesDictionaryStrategy() throws {
        let json = try encode(
            RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude),
            strategy: .latLngDictionary)

        #expect(json == #"{"latitude":40.78382,"longitude":-73.97536}"#)
    }

    @Test("missing latitude fails to decode as a dictionary")
    func missingLatitudeThrows() {
        #expect(throws: (any Error).self) {
            try decode(#"{"longitude": -73.97536}"#, strategy: .latLngDictionary)
        }
    }

    @Test("an array fails to decode with the dictionary strategy")
    func arrayFailsWithDictionaryStrategy() {
        #expect(throws: (any Error).self) {
            try decode("[-73.97536, 40.78382]", strategy: .latLngDictionary)
        }
    }

    // MARK: - LngLatArray coding strategy

    @Test("decodes a [lng, lat] array with the LngLatArray strategy")
    func decodesArrayStrategy() throws {
        let coordinate = try decode("[-73.97536, 40.78382]", strategy: .lngLatArray)

        #expect(coordinate.latitude == Self.latitude)
        #expect(coordinate.longitude == Self.longitude)
    }

    @Test("encodes a [lng, lat] array with the LngLatArray strategy")
    func encodesArrayStrategy() throws {
        let json = try encode(
            RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude),
            strategy: .lngLatArray)

        #expect(json == "[-73.97536,40.78382]")
    }

    @Test("a short array fails to decode with the array strategy")
    func shortArrayThrows() {
        #expect(throws: (any Error).self) {
            try decode("[-73.97536]", strategy: .lngLatArray)
        }
    }

    @Test("a dictionary fails to decode with the array strategy")
    func dictionaryFailsWithArrayStrategy() {
        #expect(throws: (any Error).self) {
            try decode(#"{"latitude": 40.78382, "longitude": -73.97536}"#, strategy: .lngLatArray)
        }
    }

    // MARK: - Strategy round trips

    @Test("round trips through each strategy")
    func roundTrips() throws {
        let coordinate = RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude)

        for strategy in [RadarCoordinateSwift.CodingStrategy.latLngDictionary, .lngLatArray] {
            let json = try #require(try encode(coordinate, strategy: strategy))
            #expect(try decode(json, strategy: strategy) == coordinate)
        }
    }

    private struct Geometry: Codable, Equatable {
        let coordinates: [RadarCoordinateSwift]
    }

    @Test("the strategy applies to nested coordinates")
    func strategyAppliesToNestedCoordinates() throws {
        let geometry = Geometry(coordinates: [
            RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude),
            RadarCoordinateSwift(latitude: 0, longitude: 0),
        ])

        let data = try makeEncoder(.lngLatArray).encode(geometry)
        #expect(
            String(data: data, encoding: .utf8) == #"{"coordinates":[[-73.97536,40.78382],[0,0]]}"#)

        let decoded = try makeDecoder(.lngLatArray).decode(Geometry.self, from: data)
        #expect(decoded == geometry)
    }

    // MARK: - Objective-C surface

    @Test("the Swift class is exported to the Objective-C runtime as RadarCoordinate")
    func exportedUnderObjectiveCName() throws {
        #expect(NSStringFromClass(RadarCoordinateSwift.self) == "RadarCoordinate")

        let objc = RadarCoordinate(
            coordinate: CLLocationCoordinate2D(latitude: Self.latitude, longitude: Self.longitude))!
        let swift = try #require(objc as Any as? RadarCoordinateSwift)

        #expect(swift == RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude))
        #expect(objc.coordinate.latitude == Self.latitude)
        #expect(objc.coordinate.longitude == Self.longitude)
    }

    @Test("initWithCoordinate: and the coordinate property are reachable from Objective-C")
    func objcInitWithCoordinate() throws {
        let coordinate = try #require(
            RadarCoordinate(
                coordinate: CLLocationCoordinate2D(latitude: Self.latitude, longitude: Self.longitude)))

        #expect(coordinate.coordinate.latitude == Self.latitude)
        #expect(coordinate.coordinate.longitude == Self.longitude)
    }

    @Test("[[RadarCoordinate alloc] init] returns a zeroed coordinate")
    func objcAllocInit() throws {
        let coordinate = RadarCoordinate()

        #expect(coordinate.coordinate.latitude == 0)
        #expect(coordinate.coordinate.longitude == 0)
        #expect(try #require(coordinate as Any as? RadarCoordinateSwift) == RadarCoordinateSwift())
    }

    @Test("[RadarCoordinate new] returns a zeroed coordinate")
    func objcNew() throws {
        // `+new` has no Swift spelling, so go through the Objective-C runtime. It is a
        // +1 returning selector, hence `takeRetainedValue()`.
        let coordinate = try #require(
            (RadarCoordinate.self as AnyObject).perform(NSSelectorFromString("new"))?
                .takeRetainedValue() as? RadarCoordinate)

        #expect(coordinate.coordinate.latitude == 0)
        #expect(coordinate.coordinate.longitude == 0)
        #expect(try #require(coordinate as Any as? RadarCoordinateSwift) == RadarCoordinateSwift())
    }

    @Test("the coordinate property mirrors the stored latitude and longitude")
    func coordinateProperty() {
        let coordinate = RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude)

        #expect(coordinate.coordinate.latitude == Self.latitude)
        #expect(coordinate.coordinate.longitude == Self.longitude)
        #expect(coordinate.clLocationCoordinate2D.latitude == Self.latitude)
        #expect(coordinate.clLocation.coordinate.longitude == Self.longitude)
    }

    @Test("dictionaryValue is a GeoJSON point")
    func dictionaryValue() throws {
        let dictionary = RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude)
            .dictionaryValue()

        #expect(dictionary["type"] as? String == "Point")
        #expect(try #require(dictionary["coordinates"] as? [Double]) == [Self.longitude, Self.latitude])
    }

    @Test("dictionaryValue is reachable from Objective-C")
    func objcDictionaryValue() throws {
        let coordinate = try #require(
            RadarCoordinate(
                coordinate: CLLocationCoordinate2D(latitude: Self.latitude, longitude: Self.longitude)))
        let dictionary = coordinate.dictionaryValue()

        #expect(dictionary["type"] as? String == "Point")
        #expect(try #require(dictionary["coordinates"] as? [Double]) == [Self.longitude, Self.latitude])
    }

    // MARK: - initWithObject: (internal)

    @Test("initWithObject: parses a GeoJSON point")
    func initWithObject() throws {
        let coordinate = try #require(
            RadarCoordinateSwift(
                object: Self.geoJSON(longitude: Self.longitude, latitude: Self.latitude)))

        #expect(coordinate == RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude))
    }

    @Test("initWithObject: round trips dictionaryValue")
    func initWithObjectRoundTripsDictionaryValue() throws {
        let coordinate = RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude)

        #expect(RadarCoordinateSwift(object: coordinate.dictionaryValue()) == coordinate)
    }

    @Test("initWithObject: returns nil for malformed input")
    func initWithObjectReturnsNil() {
        #expect(RadarCoordinateSwift(object: nil) == nil)
        #expect(RadarCoordinateSwift(object: "not a dictionary") == nil)
        #expect(RadarCoordinateSwift(object: ["type": "Point"]) == nil)
        #expect(RadarCoordinateSwift(object: ["coordinates": "not an array"]) == nil)
        #expect(RadarCoordinateSwift(object: ["coordinates": [Self.longitude]]) == nil)
        #expect(RadarCoordinateSwift(object: ["coordinates": [Self.longitude, Self.latitude, 0.0]]) == nil)
        #expect(RadarCoordinateSwift(object: ["coordinates": ["-73.97536", "40.78382"]]) == nil)
    }

    @Test("initWithObject: is reachable from Objective-C")
    func objcInitWithObject() throws {
        let coordinate = try #require(
            RadarCoordinate(object: Self.geoJSON(longitude: Self.longitude, latitude: Self.latitude)))

        #expect(coordinate.coordinate.latitude == Self.latitude)
        #expect(coordinate.coordinate.longitude == Self.longitude)
        #expect(RadarCoordinate(object: "not a dictionary") == nil)
    }

    // MARK: - coordinatesFromObject: (internal)

    @Test("coordinatesFromObject parses an array of GeoJSON points")
    func coordinatesFromObject() throws {
        let objects: [Any] = [
            Self.geoJSON(longitude: Self.longitude, latitude: Self.latitude),
            Self.geoJSON(longitude: 0, latitude: 1),
        ]

        let coordinates = try #require(RadarCoordinateSwift.coordinatesFrom(object: objects))

        #expect(
            coordinates == [
                RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude),
                RadarCoordinateSwift(latitude: 1, longitude: 0),
            ])
    }

    @Test("coordinatesFromObject returns an empty array for an empty array")
    func coordinatesFromEmptyArray() throws {
        #expect(try #require(RadarCoordinateSwift.coordinatesFrom(object: [Any]())).isEmpty)
    }

    @Test("coordinatesFromObject skips entries it cannot parse")
    func coordinatesFromObjectSkipsMalformedEntries() throws {
        let objects: [Any] = [
            Self.geoJSON(longitude: Self.longitude, latitude: Self.latitude),
            "not a coordinate",
            ["coordinates": [Self.longitude]],
        ]

        let coordinates = try #require(RadarCoordinateSwift.coordinatesFrom(object: objects))

        #expect(
            coordinates == [RadarCoordinateSwift(latitude: Self.latitude, longitude: Self.longitude)])
    }

    @Test("coordinatesFromObject returns nil for a non-array")
    func coordinatesFromNonArray() {
        #expect(RadarCoordinateSwift.coordinatesFrom(object: "not an array") == nil)
        #expect(
            RadarCoordinateSwift.coordinatesFrom(
                object: Self.geoJSON(longitude: Self.longitude, latitude: Self.latitude)) == nil)
    }

    @Test("coordinatesFromObject is reachable from Objective-C")
    func objcCoordinatesFromObject() throws {
        let objects: [Any] = [Self.geoJSON(longitude: Self.longitude, latitude: Self.latitude)]

        let coordinates = try #require(RadarCoordinate.coordinates(from: objects))

        #expect(coordinates.count == 1)
        #expect(coordinates[0].coordinate.latitude == Self.latitude)
        #expect(coordinates[0].coordinate.longitude == Self.longitude)
        #expect(RadarCoordinate.coordinates(from: "not an array") == nil)
    }
}
