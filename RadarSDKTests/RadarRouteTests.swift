//
//  RadarRouteTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

// swiftlint:disable file_length

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

// A route payload shaped like the `/route` API response.
private func routeObject() -> [String: Any] {
    [
        "distance": ["value": 1234.5, "text": "1234.5 m"],
        "duration": ["value": 6.5, "text": "6.5 min"],
        "geometry": [
            "type": "LineString",
            "coordinates": [[-87.656036, 41.947746], [-87.657, 41.948]],
        ],
    ]
}

private func makeRoute(withGeometry: Bool = true) -> RadarRoute {
    RadarRoute(
        distance: RadarRoute.Distance(value: 1234.5, text: "1234.5 m"),
        duration: RadarRoute.Duration(value: 6.5, text: "6.5 min"),
        geometry: withGeometry
            ? RadarRoute.Geometry(coordinates: [
                RadarCoordinateSwift(latitude: 41.947746, longitude: -87.656036),
                RadarCoordinateSwift(latitude: 41.948, longitude: -87.657),
            ])
            : nil
    )
}

private func lngLatDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.userInfo[RadarCoordinateSwift.codingStrategy] = RadarCoordinateSwift.CodingStrategy.lngLatArray
    return decoder
}

@Suite
struct RadarRouteTests {  // swiftlint:disable:this type_body_length

    // MARK: - Public API declared in RadarRoute.h
    @Test
    func propertyAccessMirrorsBackingStruct() {
        let objc = RadarRouteObjc(route: makeRoute())

        #expect(objc.distance.value == 1234.5)
        #expect(objc.distance.text == "1234.5 m")
        #expect(objc.duration.value == 6.5)
        #expect(objc.duration.text == "6.5 min")
        // `RadarCoordinateSwift` is `@objc(RadarCoordinate)`: same runtime class, so the cast
        // in `coordinates` succeeds and the array is not silently empty.
        #expect(objc.geometry?.coordinates.count == 2)
        #expect(objc.geometry?.coordinates.first?.coordinate.latitude == 41.947746)
        #expect(objc.geometry?.coordinates.first?.coordinate.longitude == -87.656036)
        #expect(objc.geometry?.coordinates.last?.coordinate.longitude == -87.657)
    }

    @Test
    func geometryIsNilWhenRouteHasNoGeometry() {
        let objc = RadarRouteObjc(route: makeRoute(withGeometry: false))
        #expect(objc.geometry == nil)
        #expect(objc.distance.value == 1234.5)
        #expect(objc.duration.value == 6.5)
    }

    @Test
    func geometryWrapperRequiresGeometry() {
        #expect(RadarRouteGeometry(route: makeRoute()) != nil)
        #expect(RadarRouteGeometry(route: makeRoute(withGeometry: false)) == nil)
    }

    // MARK: - Dictionary -> RadarRoute
    @Test
    func parsesFullPayload() throws {
        let route = try #require(RadarRouteObjc(object: routeObject()))

        #expect(route.distance.value == 1234.5)
        #expect(route.distance.text == "1234.5 m")
        #expect(route.duration.value == 6.5)
        #expect(route.duration.text == "6.5 min")
        #expect(route.geometry?.coordinates.count == 2)
        // GeoJSON is [longitude, latitude] and keeps full Double precision
        #expect(route.geometry?.coordinates.first?.coordinate.longitude == -87.656036)
        #expect(route.geometry?.coordinates.first?.coordinate.latitude == 41.947746)
    }

    @Test
    func rejectsNonDictionary() {
        #expect(RadarRouteObjc(object: "not a dict") == nil)
        #expect(RadarRouteObjc(object: [1, 2]) == nil)
        #expect(RadarRouteObjc(object: NSNull()) == nil)
    }

    @Test
    func requiresDistanceAndDuration() {
        var missingDuration = routeObject()
        missingDuration["duration"] = nil
        #expect(RadarRouteObjc(object: missingDuration) == nil)

        var missingDistance = routeObject()
        missingDistance["distance"] = nil
        #expect(RadarRouteObjc(object: missingDistance) == nil)
    }

    @Test
    func allowsMissingGeometry() throws {
        var object = routeObject()
        object["geometry"] = nil

        let route = try #require(RadarRouteObjc(object: object))
        #expect(route.geometry == nil)
        #expect(route.distance.value == 1234.5)
    }

    // `Distance`/`Duration` require both keys, so unlike the ObjC original — which defaulted a
    // missing `value` to 0 and only required `text` — an incomplete distance fails the route.
    @Test
    func requiresBothDistanceFields() {
        var noValue = routeObject()
        noValue["distance"] = ["text": "1234.5 m"]
        #expect(RadarRouteObjc(object: noValue) == nil)

        var noText = routeObject()
        noText["distance"] = ["value": 1234.5]
        #expect(RadarRouteObjc(object: noText) == nil)
    }

    @Test
    func rejectsMalformedCoordinates() {
        var shortPair = routeObject()
        shortPair["geometry"] = ["type": "LineString", "coordinates": [[1.0]]]
        #expect(RadarRouteObjc(object: shortPair) == nil)

        var notNumbers = routeObject()
        notNumbers["geometry"] = ["type": "LineString", "coordinates": [["a", "b"]]]
        #expect(RadarRouteObjc(object: notNumbers) == nil)
    }

    @Test
    func distanceFromDictionaryRequiresValueAndText() throws {
        let distance = try #require(RadarRouteDistance(object: ["value": 100.0, "text": "100 m"]))
        #expect(distance.value == 100)
        #expect(distance.text == "100 m")

        #expect(RadarRouteDistance(object: ["value": 100.0]) == nil)
        #expect(RadarRouteDistance(object: ["text": "100 m"]) == nil)
        #expect(RadarRouteDistance(object: ["value": "100", "text": "100 m"]) == nil)
        #expect(RadarRouteDistance(object: "not a dict") == nil)
    }

    // `RadarRoutes.m` is still ObjC and builds every one of its routes through
    // `-initWithObject:`, reached here via the test bridging header.
    @Test
    func radarRoutesParsesSwiftBackedRoutes() throws {
        let routes = try #require(
            RadarRoutes(
                object: [
                    "geodesic": ["distance": ["value": 100.0, "text": "100 m"]],
                    "car": routeObject(),
                    "foot": routeObject(),
                ]
            )
        )

        #expect(routes.geodesic?.value == 100)
        #expect(routes.geodesic?.text == "100 m")
        #expect(routes.car?.distance.value == 1234.5)
        #expect(routes.car?.duration.text == "6.5 min")
        #expect(routes.car?.geometry.coordinates?.count == 2)
        #expect(routes.foot != nil)
        #expect(routes.bike == nil)
        #expect(routes.truck == nil)
        #expect(routes.motorbike == nil)
    }

    @Test
    func radarRoutesRejectsNonDictionaryAndSkipsMalformedRoutes() throws {
        #expect(RadarRoutes(object: "not a dict") == nil)

        let routes = try #require(
            RadarRoutes(object: ["car": ["distance": ["value": 1.0, "text": "1 m"]]])
        )
        #expect(routes.car == nil)
        #expect(routes.geodesic == nil)
    }

    // MARK: - RadarRoute -> dictionary
    @Test
    func routeDictionaryValue() throws {
        let dict = RadarRouteObjc(route: makeRoute()).dictionaryValue()
        #expect(dict.count == 3)

        let distance = try #require(dict["distance"] as? [String: Any])
        #expect(distance["value"] as? Double == 1234.5)
        #expect(distance["text"] as? String == "1234.5 m")

        let duration = try #require(dict["duration"] as? [String: Any])
        #expect(duration["value"] as? Double == 6.5)
        #expect(duration["text"] as? String == "6.5 min")

        let geometry = try #require(dict["geometry"] as? [String: Any])
        #expect(geometry["type"] as? String == "LineString")
        #expect(geometry["coordinates"] as? [[Double]] == [[-87.656036, 41.947746], [-87.657, 41.948]])
    }

    @Test
    func routeDictionaryValueOmitsGeometryWhenNil() {
        let dict = RadarRouteObjc(route: makeRoute(withGeometry: false)).dictionaryValue()
        #expect(dict["geometry"] == nil)
        #expect(dict["distance"] != nil)
        #expect(dict["duration"] != nil)
        #expect(dict.count == 2)
    }

    @Test
    func distanceDictionaryValue() {
        let dict = RadarRouteDistance(route: makeRoute()).dictionaryValue()
        #expect(dict["value"] as? Double == 1234.5)
        #expect(dict["text"] as? String == "1234.5 m")
        #expect(dict.count == 2)
    }

    @Test
    func durationDictionaryValue() {
        let dict = RadarRouteDuration(route: makeRoute()).dictionaryValue()
        #expect(dict["value"] as? Double == 6.5)
        #expect(dict["text"] as? String == "6.5 min")
        #expect(dict.count == 2)
    }

    @Test
    func geometryDictionaryValue() throws {
        let geometry = try #require(RadarRouteGeometry(route: makeRoute()))
        let dict = geometry.dictionaryValue()

        #expect(dict["type"] as? String == "LineString")
        // GeoJSON order is [longitude, latitude]
        #expect(dict["coordinates"] as? [[Double]] == [[-87.656036, 41.947746], [-87.657, 41.948]])
        #expect(dict.count == 2)
    }

    @Test
    func emptyInitDictionaryValues() {
        let route = RadarRouteObjc().dictionaryValue()
        #expect((route["distance"] as? [String: Any])?["value"] as? Double == 0)
        #expect((route["distance"] as? [String: Any])?["text"] as? String == "")
        #expect(route["geometry"] == nil)

        #expect(RadarRouteDistance().dictionaryValue()["value"] as? Double == 0)
        #expect(RadarRouteDuration().dictionaryValue()["text"] as? String == "")
        #expect(RadarRouteGeometry().dictionaryValue()["coordinates"] as? [[Double]] == [])
    }

    @Test
    func dictionaryRoundTripPreservesValues() throws {
        let original = try #require(RadarRouteObjc(object: routeObject()))
        let reparsed = try #require(RadarRouteObjc(object: original.dictionaryValue()))

        #expect(reparsed.distance.value == original.distance.value)
        #expect(reparsed.distance.text == original.distance.text)
        #expect(reparsed.duration.value == original.duration.value)
        #expect(reparsed.duration.text == original.duration.text)
        #expect(reparsed.geometry?.coordinates == original.geometry?.coordinates)
    }

    @Test
    func dictionaryRoundTripWithoutGeometry() throws {
        let original = RadarRouteObjc(route: makeRoute(withGeometry: false))
        let reparsed = try #require(RadarRouteObjc(object: original.dictionaryValue()))

        #expect(reparsed.geometry == nil)
        #expect(reparsed.distance.value == 1234.5)
        #expect(reparsed.duration.text == "6.5 min")
    }

    // `dictionaryValue()` is hand-built, so it matches the wire format. `RadarUtils`
    // encodes the struct with a bare JSONEncoder, which uses the default coordinate
    // strategy and so emits { latitude, longitude } objects and no "type".
    @Test
    func radarUtilsEncodingDiffersFromDictionaryValue() throws {
        let dict = try #require(RadarUtils.dictionary(from: makeRoute()))
        let geometry = try #require(dict["geometry"] as? [String: Any])

        #expect(geometry["type"] == nil)
        let coordinates = try #require(geometry["coordinates"] as? [[String: Any]])
        #expect(coordinates.first?["latitude"] as? Double == 41.947746)
        #expect(coordinates.first?["longitude"] as? Double == -87.656036)
    }

    // MARK: - Property access the way ObjC callers do it
    // The `@objc` properties are reached here through KVC, which dispatches on the ObjC runtime
    // exactly like `route.geometry.coordinates` in an ObjC caller — no Swift typing involved.
    @Test
    func objcPropertyChainOnParsedRoute() throws {
        let route = try #require(RadarRouteObjc(object: routeObject()))

        #expect(route.value(forKeyPath: "distance.value") as? Double == 1234.5)
        #expect(route.value(forKeyPath: "distance.text") as? String == "1234.5 m")
        #expect(route.value(forKeyPath: "duration.value") as? Double == 6.5)
        #expect(route.value(forKeyPath: "duration.text") as? String == "6.5 min")

        let coordinates = try #require(route.value(forKeyPath: "geometry.coordinates") as? [RadarCoordinate])
        #expect(coordinates.count == 2)
        #expect(coordinates.first?.coordinate.longitude == -87.656036)
    }

    // `[[RadarRoute alloc] init].geometry.coordinates`: `init()` leaves `geometry` nil, so the
    // chain yields nil rather than an empty array. Messaging nil is safe in ObjC, so a caller
    // gets nil/0 instead of a crash — but `RadarRoute.h` annotates `geometry` nonnull, so that
    // caller has no reason to nil-check.
    @Test
    func objcPropertyChainOnEmptyInit() {
        let route = RadarRouteObjc()

        #expect(route.value(forKeyPath: "distance.value") as? Double == 0)
        #expect(route.value(forKeyPath: "distance.text") as? String == "")
        #expect(route.value(forKey: "geometry") == nil)
        #expect(route.value(forKeyPath: "geometry.coordinates") == nil)
    }

    // `RadarRoutes` is still ObjC, so `routes.car` is typed by `RadarRoute.h` rather than by
    // Swift — this is a compiled ObjC property chain, not KVC.
    @Test
    func headerTypedPropertyChainThroughRadarRoutes() throws {
        let routes = try #require(RadarRoutes(object: ["car": routeObject()]))
        let car = try #require(routes.car)

        #expect(car.distance.value == 1234.5)
        #expect(car.duration.text == "6.5 min")
        #expect(car.geometry.coordinates?.count == 2)
        #expect(car.geometry.coordinates?.first?.coordinate.latitude == 41.947746)
        #expect(car.dictionaryValue()["geometry"] != nil)
    }

    // MARK: - `[[RadarRoute alloc] init]` / `[RadarRoute new]`
    @Test
    func emptyInitProducesZeroValues() {
        let route = RadarRouteObjc()
        #expect(route.distance.value == 0)
        #expect(route.distance.text == "")
        #expect(route.duration.value == 0)
        #expect(route.duration.text == "")
        #expect(route.geometry == nil)
    }

    @Test
    func emptyInitOnComponents() {
        #expect(RadarRouteDistance().value == 0)
        #expect(RadarRouteDistance().text == "")
        #expect(RadarRouteDuration().value == 0)
        #expect(RadarRouteDuration().text == "")
        // `init()` bypasses the failable `init?(route:)`, so this one exists with no geometry
        #expect(RadarRouteGeometry().coordinates.isEmpty)
    }

    // `[[cls alloc] init]` and `[cls new]` as an ObjC caller of the header writes them.
    // Without `override init()` these hit the failable initializers only and `new` traps,
    // so drive both through the runtime rather than through Swift.
    @Test
    func objcAllocInitAndNewSucceed() throws {
        for name in ["RadarRoute", "RadarRouteDistance", "RadarRouteDuration", "RadarRouteGeometry"] {
            let cls = try #require(NSClassFromString(name) as? NSObject.Type, "\(name) not registered")

            let allocated = try #require(
                (cls as AnyObject).perform(NSSelectorFromString("alloc"))?.takeUnretainedValue()
            )
            let initialized = allocated.perform(NSSelectorFromString("init"))?.takeRetainedValue()
            #expect(initialized != nil, "[[\(name) alloc] init] returned nil")
            #expect(type(of: initialized!) == cls, "[[\(name) alloc] init] wrong class")

            let created = (cls as AnyObject).perform(NSSelectorFromString("new"))?.takeRetainedValue()
            #expect(created != nil, "[\(name) new] returned nil")
            #expect(type(of: created!) == cls, "[\(name) new] wrong class")
        }
    }

    @Test
    func objcRuntimeNamesResolveToSwiftClasses() {
        #expect(NSClassFromString("RadarRoute") == RadarRouteObjc.self)
        #expect(NSClassFromString("RadarRouteDistance") == RadarRouteDistance.self)
        #expect(NSClassFromString("RadarRouteDuration") == RadarRouteDuration.self)
        #expect(NSClassFromString("RadarRouteGeometry") == RadarRouteGeometry.self)
    }

    // Every selector the public headers promise. A missing one is an unrecognized-selector
    // crash at runtime, not a compile error, since ObjC callers only see the header.
    @Test
    func objcHeaderContractIsImplemented() throws {
        let expected: [String: [String]] = [
            "RadarRoute": ["initWithObject:", "distance", "duration", "geometry", "dictionaryValue"],
            "RadarRouteDistance": ["initWithObject:", "value", "text", "dictionaryValue"],
            "RadarRouteDuration": ["value", "text", "dictionaryValue"],
            "RadarRouteGeometry": ["coordinates", "dictionaryValue"],
        ]
        for (name, selectors) in expected {
            let cls = try #require(NSClassFromString(name) as? NSObject.Type, "\(name) not registered")
            for selector in selectors {
                #expect(
                    cls.instancesRespond(to: NSSelectorFromString(selector)),
                    "-[\(name) \(selector)] is declared in the public header but not implemented"
                )
            }
        }
    }

    // MARK: - Codable
    @Test
    func decodesFromWireFormatWithLngLatStrategy() throws {
        let data = try JSONSerialization.data(withJSONObject: routeObject())
        let route = try lngLatDecoder().decode(RadarRoute.self, from: data)

        #expect(route.distance.value == 1234.5)
        #expect(route.duration.text == "6.5 min")
        #expect(route.geometry?.coordinates.count == 2)
        #expect(route.geometry?.coordinates.first?.longitude == -87.656036)
        #expect(route.geometry?.coordinates.first?.latitude == 41.947746)
    }

    // Without the strategy in userInfo, coordinates are expected as { latitude, longitude }
    // objects, so a GeoJSON payload fails to decode.
    @Test
    func decodeWithDefaultStrategyRejectsLngLatArrays() throws {
        let data = try JSONSerialization.data(withJSONObject: routeObject())
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(RadarRoute.self, from: data)
        }
    }

    @Test
    func roundTripsWhenBothSidesUseTheSameStrategy() throws {
        let encoder = JSONEncoder()
        encoder.userInfo[RadarCoordinateSwift.codingStrategy] = RadarCoordinateSwift.CodingStrategy.lngLatArray

        let original = makeRoute()
        let decoded = try lngLatDecoder().decode(RadarRoute.self, from: encoder.encode(original))

        #expect(decoded.distance.value == original.distance.value)
        #expect(decoded.duration.text == original.duration.text)
        #expect(decoded.geometry?.coordinates == original.geometry?.coordinates)
    }

    @Test
    func encodeOmitsNilGeometry() throws {
        let dict = try #require(RadarUtils.dictionary(from: makeRoute(withGeometry: false)))
        #expect(dict["geometry"] == nil)
        #expect(dict.count == 2)
    }
}
