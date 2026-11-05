//
//  RadarAddressPlace.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// A place on the grounds of an enriched address.
@objc(RadarAddressPlace)
@objcMembers
public final class RadarAddressPlace: NSObject, Sendable {
    /// The name of the place.
    public let name: String

    /// The categories of the place.
    public let categories: [String]

    init?(object: Any) {
        guard let dictionary = object as? NSDictionary,
            let name = dictionary["name"] as? String
        else {
            return nil
        }

        self.name = name
        categories = (dictionary["categories"] as? NSArray)?.compactMap { $0 as? String } ?? []

        super.init()
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        [
            "name": name,
            "categories": categories,
        ]
    }
}
