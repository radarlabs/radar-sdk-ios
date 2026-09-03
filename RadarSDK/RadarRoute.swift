//
//  RadarRoute.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

public struct RadarRoute: Codable, Sendable {
    struct Distance: Codable {
        let value: Double
        let text: String
    }

    struct Duration: Codable {
        let value: Double
        let text: String
    }

    struct Geometry: Codable {
        let coordinates: [RadarCoordinateSwift]
    }

    let distance: Distance
    let duration: Duration
    // Nullable to match the ObjC original, which returned a route with nil geometry when the
    // payload had no `geometry` key. Synthesized encoding omits the key when nil.
    let geometry: Geometry?
}

// used by empty initializers like [[RadarRoute alloc] init] or [RadarRoute new]
let emptyRoute = RadarRoute(distance: RadarRoute.Distance(value: 0, text: ""), duration: RadarRoute.Duration(value: 0, text: ""), geometry: nil)

// MARK: - ObjC classes, backed by RadarRoute struct

@objc(RadarRouteDistance)
class RadarRouteDistance: NSObject {
    @objc public var value: Double { route.distance.value }
    @objc public var text: String { route.distance.text }

    @objc public func dictionaryValue() -> [String: Any] {
        return RadarUtils.dictionary(from: route.distance) ?? [:]
    }

    let route: RadarRoute
    init(route: RadarRoute) {
        self.route = route
    }

    @objc
    internal convenience init?(object: Any) {
        guard let dict = object as? [String: Any] else {
            return nil
        }
        guard let value = dict["value"] as? Double,
              let text = dict["text"] as? String else {
            return nil
        }
        self.init(route: RadarRoute(
            distance: RadarRoute.Distance(value: value, text: text),
            duration: RadarRoute.Duration(value: 0, text: ""),
            geometry: RadarRoute.Geometry(coordinates: []))
        )
    }

    @objc public override init() {
        self.route = emptyRoute
    }
}

@objc(RadarRouteDuration)
class RadarRouteDuration: NSObject {
    @objc public var value: Double { route.duration.value }
    @objc public var text: String { route.duration.text }

    @objc public func dictionaryValue() -> [String: Any] {
        return RadarUtils.dictionary(from: route.duration) ?? [:]
    }

    let route: RadarRoute
    init(route: RadarRoute) {
        self.route = route
    }

    @objc public override init() {
        self.route = emptyRoute
    }
}

@objc(RadarRouteGeometry)
class RadarRouteGeometry: NSObject {
    @objc public var coordinates: [RadarCoordinate] { route.geometry?.coordinates as? [RadarCoordinate] ?? [] }

    @objc public func dictionaryValue() -> [String: Any] {
        return [
            "type": "LineString",
            "coordinates": coordinates.map { [$0.coordinate.longitude, $0.coordinate.latitude] }
        ]
    }

    let route: RadarRoute
    init?(route: RadarRoute) {
        guard route.geometry != nil else {
            return nil
        }
        self.route = route
    }

    @objc public override init() {
        self.route = emptyRoute
    }
}

@objc(RadarRoute)
class RadarRouteObjc: NSObject {
    let route: RadarRoute

    @objc public let distance: RadarRouteDistance
    @objc public let duration: RadarRouteDuration
    @objc public let geometry: RadarRouteGeometry?

    init(route: RadarRoute) {
        self.route = route
        self.distance = RadarRouteDistance(route: route)
        self.duration = RadarRouteDuration(route: route)
        self.geometry = RadarRouteGeometry(route: route)
    }

    @objc
    internal convenience init?(object: Any) {
        guard let dict = object as? [String: Any] else {
            return nil
        }

        let jsonString = RadarUtils.dictionaryToJson(dict)

        let decoder = JSONDecoder()
        decoder.userInfo[RadarCoordinateSwift.codingStrategy] = RadarCoordinateSwift.CodingStrategy.lngLatArray

        guard let data = jsonString.data(using: .utf8),
              let route = try? decoder.decode(RadarRoute.self, from: data) else {
            return nil
        }
        self.init(route: route)
    }

    @objc public override init() {
        self.route = emptyRoute
        self.distance = RadarRouteDistance(route: emptyRoute)
        self.duration = RadarRouteDuration(route: emptyRoute)
        self.geometry = RadarRouteGeometry(route: emptyRoute)
    }

    @objc public func dictionaryValue() -> [String: Any] {
        var dict = [
            "distance": distance.dictionaryValue(),
            "duration": duration.dictionaryValue(),
        ]
        if let geometry {
            dict["geometry"] = geometry.dictionaryValue()
        }
        return dict
    }
}
