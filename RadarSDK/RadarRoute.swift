//
//  RadarRoute.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

struct RadarRouteValue: Codable, Sendable {
    struct Distance: Codable {
        let value: Double
        let text: String
    }

    struct Duration: Codable {
        let value: Double
        let text: String
    }

    struct Geometry: Codable {
        let coordinates: [RadarCoordinate]
    }

    let distance: Distance
    let duration: Duration
    let geometry: Geometry?
}

// used by empty initializers like [[RadarRoute alloc] init] or [RadarRoute new]
private let emptyRoute = RadarRouteValue(
    distance: RadarRouteValue.Distance(value: 0, text: ""),
    duration: RadarRouteValue.Duration(value: 0, text: ""),
    geometry: nil
)

// MARK: - ObjC classes, backed by RadarRoute struct

@objc(RadarRouteDistance)
public class RadarRouteDistance: NSObject {
    @objc public var value: Double { route.distance.value }
    @objc public var text: String { route.distance.text }

    @objc public func dictionaryValue() -> [String: Any] {
        return RadarUtils.dictionary(from: route.distance) ?? [:]
    }

    let route: RadarRouteValue
    init(route: RadarRouteValue) {
        self.route = route
    }

    @objc
    internal convenience init?(object: Any) {
        guard let dict = object as? [String: Any] else {
            return nil
        }
        guard let value = dict["value"] as? Double,
            let text = dict["text"] as? String
        else {
            return nil
        }
        self.init(
            route: RadarRouteValue(
                distance: RadarRouteValue.Distance(value: value, text: text),
                duration: RadarRouteValue.Duration(value: 0, text: ""),
                geometry: RadarRouteValue.Geometry(coordinates: []))
        )
    }

    @objc public override init() {
        self.route = emptyRoute
    }
}

@objc(RadarRouteDuration)
public class RadarRouteDuration: NSObject {
    @objc public var value: Double { route.duration.value }
    @objc public var text: String { route.duration.text }

    @objc public func dictionaryValue() -> [String: Any] {
        return RadarUtils.dictionary(from: route.duration) ?? [:]
    }

    let route: RadarRouteValue
    init(route: RadarRouteValue) {
        self.route = route
    }

    @objc public override init() {
        self.route = emptyRoute
    }
}

@objc(RadarRouteGeometry)
public class RadarRouteGeometry: NSObject {
    @objc public var coordinates: [RadarCoordinate]? { route.geometry?.coordinates }

    @objc public func dictionaryValue() -> [String: Any] {
        return [
            "type": "LineString",
            "coordinates": (coordinates ?? []).map { [$0.coordinate.longitude, $0.coordinate.latitude] },
        ]
    }

    let route: RadarRouteValue
    init?(route: RadarRouteValue) {
        guard route.geometry != nil else {
            return nil
        }
        self.route = route
    }

    @objc public override init() {
        self.route = emptyRoute
    }
}

@objc @implementation extension RadarRoute {
    private final var route = emptyRoute
    private final var hasGeometry = false

    var distance = RadarRouteDistance()
    var duration = RadarRouteDuration()
    var geometry = RadarRouteGeometry()

    override init() {
        super.init()
        distance = RadarRouteDistance(route: emptyRoute)
        duration = RadarRouteDuration(route: emptyRoute)
    }

    func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [
            "distance": distance.dictionaryValue(),
            "duration": duration.dictionaryValue(),
        ]
        if hasGeometry {
            dictionary["geometry"] = geometry.dictionaryValue()
        }
        return dictionary
    }
}

extension RadarRoute {
    convenience init(route: RadarRouteValue) {
        self.init()
        self.route = route
        hasGeometry = route.geometry != nil
        distance = RadarRouteDistance(route: route)
        duration = RadarRouteDuration(route: route)
        geometry = RadarRouteGeometry(route: route) ?? RadarRouteGeometry()
    }

    @objc(initWithObject:)
    convenience init?(object: Any) {
        guard let dictionary = object as? [String: Any] else {
            return nil
        }

        let jsonString = RadarUtils.dictionaryToJson(dictionary)
        let decoder = JSONDecoder()
        decoder.userInfo[RadarCoordinate.codingStrategy] = RadarCoordinate.CodingStrategy.lngLatArray

        guard let data = jsonString.data(using: .utf8),
            let route = try? decoder.decode(RadarRouteValue.self, from: data)
        else {
            return nil
        }
        self.init(route: route)
    }
}
