//
//  RadarRoutesTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

// A route payload shaped like one mode of the `/route/distance` API response.
private func routeObject(distance: Double) -> [String: Any] {
    [
        "distance": ["value": distance, "text": "\(distance) m"],
        "duration": ["value": distance / 100, "text": "\(distance / 100) min"],
    ]
}

// The `routes` object of the `/route/distance` API response, with every mode present.
private func routesObject() -> [String: Any] {
    [
        "geodesic": ["distance": ["value": 100.0, "text": "100 m"]],
        "foot": routeObject(distance: 1),
        "bike": routeObject(distance: 2),
        "car": routeObject(distance: 3),
        "truck": routeObject(distance: 4),
        "motorbike": routeObject(distance: 5),
    ]
}

@Suite
struct RadarRoutesTests {

    // MARK: - initWithObject:

    @Test
    func parsesEveryMode() throws {
        let routes = try #require(RadarRoutes(object: routesObject()))

        #expect(routes.geodesic?.value == 100)
        #expect(routes.geodesic?.text == "100 m")
        #expect(routes.foot?.distance.value == 1)
        #expect(routes.bike?.distance.value == 2)
        #expect(routes.car?.distance.value == 3)
        #expect(routes.truck?.distance.value == 4)
        #expect(routes.motorbike?.distance.value == 5)
        #expect(routes.motorbike?.duration.text == "0.05 min")
    }

    @Test
    func rejectsNonDictionary() {
        #expect(RadarRoutes(object: "not a dict") == nil)
        #expect(RadarRoutes(object: [routesObject()]) == nil)
        #expect(RadarRoutes(object: NSNull()) == nil)
    }

    @Test
    func emptyDictionaryHasNoRoutes() throws {
        let routes = try #require(RadarRoutes(object: [String: Any]()))

        #expect(routes.geodesic == nil)
        #expect(routes.foot == nil)
        #expect(routes.bike == nil)
        #expect(routes.car == nil)
        #expect(routes.truck == nil)
        #expect(routes.motorbike == nil)
        #expect(routes.dictionaryValue().isEmpty)
    }

    @Test
    func malformedModesAreNil() throws {
        let routes = try #require(
            RadarRoutes(
                object: [
                    "geodesic": ["value": 100.0, "text": "100 m"],
                    "foot": NSNull(),
                    "bike": "fast",
                    "car": ["distance": ["value": 1.0, "text": "1 m"]],
                    "truck": routeObject(distance: 4),
                ]
            )
        )

        // The geodesic distance is nested under `distance`, so a bare distance is ignored.
        #expect(routes.geodesic == nil)
        #expect(routes.foot == nil)
        #expect(routes.bike == nil)
        #expect(routes.car == nil)
        #expect(routes.truck?.distance.value == 4)
        #expect(routes.motorbike == nil)
    }

    @Test
    func nonDictionaryGeodesicIsNil() throws {
        let routes = try #require(RadarRoutes(object: ["geodesic": NSNull()]))
        #expect(routes.geodesic == nil)

        let nullDistance = try #require(RadarRoutes(object: ["geodesic": ["distance": NSNull()]]))
        #expect(nullDistance.geodesic == nil)
    }

    // MARK: - initWithGeodesic:foot:bike:car:truck:motorbike:

    @Test
    func memberwiseInitKeepsValues() throws {
        let geodesic = try #require(RadarRouteDistance(object: ["value": 7.0, "text": "7 m"]))
        let car = try #require(RadarRoute(object: routeObject(distance: 3)))

        let routes = RadarRoutes(geodesic: geodesic, foot: nil, bike: nil, car: car, truck: nil, motorbike: nil)

        #expect(routes.geodesic === geodesic)
        #expect(routes.car === car)
        #expect(routes.foot == nil)
    }

    @Test
    func emptyInitHasNoRoutes() {
        let routes = RadarRoutes()
        #expect(routes.geodesic == nil)
        #expect(routes.car == nil)
        #expect(routes.dictionaryValue().isEmpty)
    }

    // MARK: - dictionaryValue

    @Test
    func dictionaryValueIncludesEveryPresentMode() throws {
        let dict = try #require(RadarRoutes(object: routesObject())).dictionaryValue()

        #expect(Set(dict.keys) == ["geodesic", "foot", "bike", "car", "truck", "motorbike"])
        // The geodesic distance is written flat, not nested under `distance`.
        let geodesic = try #require(dict["geodesic"] as? [AnyHashable: Any])
        #expect(geodesic["value"] as? Double == 100)
        #expect(geodesic["text"] as? String == "100 m")

        let car = try #require(dict["car"] as? [AnyHashable: Any])
        #expect((car["distance"] as? [AnyHashable: Any])?["value"] as? Double == 3)
        #expect((car["duration"] as? [AnyHashable: Any])?["text"] as? String == "0.03 min")
    }

    @Test
    func dictionaryValueOmitsMissingModes() throws {
        let dict = try #require(RadarRoutes(object: ["car": routeObject(distance: 3)])).dictionaryValue()
        #expect(Set(dict.keys) == ["car"])
    }

    // MARK: - Objective-C runtime

    @Test
    func objectiveCRuntimeContract() throws {
        #expect(NSStringFromClass(RadarRoutes.self) == "RadarRoutes")
        let cls: AnyClass = try #require(NSClassFromString("RadarRoutes"))
        #expect(ObjectIdentifier(cls) == ObjectIdentifier(RadarRoutes.self))

        for selector in [
            "initWithObject:", "initWithGeodesic:foot:bike:car:truck:motorbike:", "dictionaryValue",
            "geodesic", "foot", "bike", "car", "truck", "motorbike",
        ] {
            #expect(RadarRoutes.instancesRespond(to: NSSelectorFromString(selector)), "\(selector)")
        }
        #expect(!RadarRoutes.instancesRespond(to: NSSelectorFromString("setCar:")))

        let routes = try #require(RadarRoutes(object: routesObject()))
        #expect((routes.value(forKeyPath: "car.distance.value") as? Double) == 3)
    }
}
