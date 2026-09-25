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

// Backs the empty placeholder values the SDK creates internally.
private let emptyRoute = RadarRouteValue(
    distance: RadarRouteValue.Distance(value: 0, text: ""),
    duration: RadarRouteValue.Duration(value: 0, text: ""),
    geometry: nil
)

// MARK: - Public classes, backed by RadarRouteValue

/// Represents the distance of a route.
@objc(RadarRouteDistance)
@objcMembers
public final class RadarRouteDistance: NSObject {
    /// The distance in feet (for imperial units) or meters (for metric units).
    public var value: Double { route.distance.value }
    /// A display string for the distance.
    public var text: String { route.distance.text }

    public func dictionaryValue() -> [AnyHashable: Any] {
        return RadarUtils.dictionary(from: route.distance) ?? [:]
    }

    let route: RadarRouteValue
    init(route: RadarRouteValue) {
        self.route = route
    }

    @objc(initWithObject:)
    convenience init?(object: Any) {
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

    override init() {
        self.route = emptyRoute
    }
}

/// Represents the duration of a route.
@objc(RadarRouteDuration)
@objcMembers
public final class RadarRouteDuration: NSObject {
    /// The duration in minutes.
    public var value: Double { route.duration.value }
    /// A display string for the duration.
    public var text: String { route.duration.text }

    public func dictionaryValue() -> [AnyHashable: Any] {
        return RadarUtils.dictionary(from: route.duration) ?? [:]
    }

    let route: RadarRouteValue
    init(route: RadarRouteValue) {
        self.route = route
    }

    override init() {
        self.route = emptyRoute
    }
}

/// Represents the geometry of a route.
@objc(RadarRouteGeometry)
@objcMembers
public final class RadarRouteGeometry: NSObject {
    /// The geometry of the route.
    public var coordinates: [RadarCoordinate]? { route.geometry?.coordinates }

    public func dictionaryValue() -> [AnyHashable: Any] {
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

    override init() {
        self.route = emptyRoute
    }
}

/// Represents a route between an origin and a destination.
///
/// - SeeAlso: https://radar.com/documentation/api#routing
@objc(RadarRoute)
@objcMembers
public final class RadarRoute: NSObject {
    /// The distance of the route.
    public let distance: RadarRouteDistance
    /// The duration of the route.
    public let duration: RadarRouteDuration
    /// The geometry of the route.
    public let geometry: RadarRouteGeometry
    // `geometry` is nonnull for Objective-C, so a route without one carries an empty geometry
    // and omits it from `dictionaryValue`.
    private let hasGeometry: Bool

    init(route: RadarRouteValue) {
        distance = RadarRouteDistance(route: route)
        duration = RadarRouteDuration(route: route)
        geometry = RadarRouteGeometry(route: route) ?? RadarRouteGeometry()
        hasGeometry = route.geometry != nil
        super.init()
    }

    // Internal, so it isn't public API, but still an override, so an Objective-C `-init`
    // produces an empty route instead of trapping.
    override convenience init() {
        self.init(route: emptyRoute)
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

    public func dictionaryValue() -> [AnyHashable: Any] {
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
