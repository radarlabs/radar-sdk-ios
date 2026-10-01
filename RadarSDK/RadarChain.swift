//
//  RadarChain.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents the chain of a place.
///
/// - SeeAlso: https://radar.com/documentation/places
@objc(RadarChain)
@objcMembers
public final class RadarChain: NSObject {
    /// The unique ID of the chain. For a full list of chains, see https://radar.com/documentation/places/chains.
    ///
    /// - SeeAlso: https://radar.com/documentation/places/chains
    public let slug: String

    /// The name of the chain. For a full list of chains, see https://radar.com/documentation/places/chains.
    ///
    /// - SeeAlso: https://radar.com/documentation/places/chains
    public let name: String

    /// The external ID of the chain.
    public let externalId: String?

    /// The optional set of custom key-value pairs for the chain.
    public let metadata: [AnyHashable: Any]?

    override init() {
        slug = ""
        name = ""
        externalId = nil
        metadata = nil
        super.init()
    }

    // Keeps the Objective-C initializer declared in RadarChain+Internal.h working.
    @objc(initWithSlug:name:externalId:metadata:)
    init(slug: String, name: String, externalId: String?, metadata: NSDictionary?) {
        self.slug = slug
        self.name = name
        self.externalId = externalId
        self.metadata = metadata as? [AnyHashable: Any]
        super.init()
    }

    // Keeps the hand-written Objective-C parser working for existing SDK callers.
    @objc(initWithObject:)
    init?(object: Any) {
        guard let dictionary = object as? NSDictionary,
            let slug = dictionary["slug"] as? String,
            let name = dictionary["name"] as? String
        else {
            return nil
        }

        self.slug = slug
        self.name = name
        self.externalId = dictionary["externalId"] as? String
        self.metadata = dictionary["metadata"] as? [AnyHashable: Any]
        super.init()
    }

    @objc(arrayForChains:)
    public static func array(for chains: [RadarChain]?) -> [[AnyHashable: Any]]? {
        chains?.map { $0.dictionaryValue() }
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [
            "slug": slug,
            "name": name,
        ]
        if let externalId {
            dictionary["externalId"] = externalId
        }
        if let metadata {
            dictionary["metadata"] = metadata
        }
        return dictionary
    }
}
