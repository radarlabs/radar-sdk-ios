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
public final class RadarChain: NSObject, Codable {
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

    private enum CodingKeys: String, CodingKey {
        case slug
        case name
        case externalId
        case metadata
    }

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

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slug = try container.decode(String.self, forKey: .slug)
        name = try container.decode(String.self, forKey: .name)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)

        if let metadata = try container.decodeIfPresent([String: RadarMetadataValue].self, forKey: .metadata) {
            let foundationMetadata = metadata.reduce(into: [AnyHashable: Any]()) { result, entry in
                result[entry.key] = entry.value.anyValue
            }
            self.metadata = foundationMetadata
        } else {
            self.metadata = nil
        }

        super.init()
    }

    // JSON cannot encode NSDictionary directly, so use the same primitive values as Codable metadata.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(slug, forKey: .slug)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(externalId, forKey: .externalId)

        if let metadata {
            let data = try JSONSerialization.data(withJSONObject: metadata)
            let codableMetadata = try JSONDecoder().decode([String: RadarMetadataValue].self, from: data)
            try container.encode(codableMetadata, forKey: .metadata)
        }
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
