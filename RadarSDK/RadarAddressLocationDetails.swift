//
//  RadarAddressLocationDetails.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// What address enrichment knows about a location.
@objc(RadarAddressLocationDetails)
@objcMembers
public final class RadarAddressLocationDetails: NSObject {
    /// How the location is used, or `unknown`.
    public let usage: String

    /// The dwelling type, `n/a` for usages that have none, or `unknown`.
    public let dwelling: String

    /// The grounds of the location.
    public let grounds: [String]

    /// The places on the grounds of the location.
    public let places: [RadarAddressPlace]

    // The server fills every field, so these defaults only stand in for a malformed response.
    @objc(initWithObject:)
    init(object: Any?) {
        let dictionary = object as? NSDictionary ?? NSDictionary()

        usage = dictionary["usage"] as? String ?? "unknown"
        dwelling = dictionary["dwelling"] as? String ?? "unknown"
        grounds = (dictionary["grounds"] as? NSArray)?.compactMap { $0 as? String } ?? []
        places = (dictionary["places"] as? NSArray)?.compactMap { RadarAddressPlace(object: $0) } ?? []

        super.init()
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        [
            "usage": usage,
            "dwelling": dwelling,
            "grounds": grounds,
            "places": places.map { $0.dictionaryValue() },
        ]
    }
}
