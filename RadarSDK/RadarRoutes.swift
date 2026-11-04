//
//  RadarRoutes.swift
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents routes from an origin to a destination.
///
/// - SeeAlso: https://radar.com/documentation/api#distance
@objc(RadarRoutes)
@objcMembers
public final class RadarRoutes: NSObject {
    /// The geodesic distance between the origin and destination.
    public let geodesic: RadarRouteDistance?

    /// The route by foot between the origin and destination. May be `nil` if mode not specified or route unavailable.
    public let foot: RadarRoute?

    /// The route by bike between the origin and destination. May be `nil` if mode not specified or route unavailable.
    public let bike: RadarRoute?

    /// The route by car between the origin and destination. May be `nil` if mode not specified or route unavailable.
    public let car: RadarRoute?

    /// The route by truck between the origin and destination. May be `nil` if mode not specified or route unavailable.
    public let truck: RadarRoute?

    /// The route by motorbike between the origin and destination. May be `nil` if mode not specified or route unavailable.
    public let motorbike: RadarRoute?

    override convenience init() {
        self.init(geodesic: nil, foot: nil, bike: nil, car: nil, truck: nil, motorbike: nil)
    }

    // Declared for Objective-C in RadarRoutes+Internal.h.
    @objc(initWithGeodesic:foot:bike:car:truck:motorbike:)
    init(
        geodesic: RadarRouteDistance?,
        foot: RadarRoute?,
        bike: RadarRoute?,
        car: RadarRoute?,
        truck: RadarRoute?,
        motorbike: RadarRoute?
    ) {
        self.geodesic = geodesic
        self.foot = foot
        self.bike = bike
        self.car = car
        self.truck = truck
        self.motorbike = motorbike
        super.init()
    }

    // Keeps the Objective-C parser declared in RadarRoutes+Internal.h working. Only a
    // non-dictionary object fails; a missing or malformed mode leaves that route `nil`.
    @objc(initWithObject:)
    convenience init?(object: Any) {
        guard let dict = object as? NSDictionary else {
            return nil
        }

        func route(_ key: String) -> RadarRoute? {
            dict[key].flatMap { RadarRoute(object: $0) }
        }

        let geodesic = (dict["geodesic"] as? NSDictionary)?["distance"].flatMap {
            RadarRouteDistance(object: $0)
        }

        self.init(
            geodesic: geodesic,
            foot: route("foot"),
            bike: route("bike"),
            car: route("car"),
            truck: route("truck"),
            motorbike: route("motorbike")
        )
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        dict["geodesic"] = geodesic?.dictionaryValue()
        dict["foot"] = foot?.dictionaryValue()
        dict["bike"] = bike?.dictionaryValue()
        dict["car"] = car?.dictionaryValue()
        dict["truck"] = truck?.dictionaryValue()
        dict["motorbike"] = motorbike?.dictionaryValue()
        return dict
    }
}
