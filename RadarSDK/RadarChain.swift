//
//  RadarChain.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarChain)
@objcMembers
public final class RadarChain: NSObject, Codable {
    public let slug: String
    public let name: String
    public let externalId: String?
    public let metadata: [AnyHashable: Any]?

    private enum CodingKeys: String, CodingKey {
        case slug
        case name
        case externalId
        case metadata
    }

    public override init() {
        slug = ""
        name = ""
        externalId = nil
        metadata = nil
        super.init()
    }

    /// Keeps the hand-written Objective-C initializer working after the implementation moved to Swift.
    @objc(initWithSlug:name:externalId:metadata:)
    init(slug: String, name: String, externalId: String?, metadata: NSDictionary?) {
        self.slug = slug
        self.name = name
        self.externalId = externalId
        self.metadata = metadata as? [AnyHashable: Any]
        super.init()
    }

    /// Keeps the hand-written Objective-C parser working for existing SDK callers.
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

    /// JSON cannot encode NSDictionary directly, so use the same primitive values as Codable metadata.
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
    public static func array(for chains: [RadarChain]?) -> [[String: Any]]? {
        chains?.map { $0.dictionaryValue() }
    }

    public func dictionaryValue() -> [String: Any] {
        var dictionary: [String: Any] = [
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
