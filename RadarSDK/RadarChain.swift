//
//  RadarChain.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation

struct RadarChainSwift: Codable, Sendable {
    let slug: String
    let name: String
    let externalId: String?
    let metadata: [String: RadarMetadataValue]?

    enum CodingKeys: String, CodingKey {
        case slug
        case name
        case externalId
        case metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slug = try container.decode(String.self, forKey: .slug)
        name = try container.decode(String.self, forKey: .name)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        metadata = try container.decodeIfPresent([String: RadarMetadataValue].self, forKey: .metadata)
    }

    init(slug: String, name: String, externalId: String? = nil, metadata: [String: RadarMetadataValue]? = nil) {
        self.slug = slug
        self.name = name
        self.externalId = externalId
        self.metadata = metadata
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(slug, forKey: .slug)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
}

@objc(RadarChain)
@objcMembers
final class RadarChain: NSObject {
    let slug: String
    let name: String
    let externalId: String?
    let metadata: NSDictionary?

    /// Keeps the hand-written Objective-C initializer working after the implementation moved to Swift.
    @objc(initWithSlug:name:externalId:metadata:)
    init(slug: String, name: String, externalId: String?, metadata: NSDictionary?) {
        self.slug = slug
        self.name = name
        self.externalId = externalId
        self.metadata = metadata
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
        self.metadata = dictionary["metadata"] as? NSDictionary
        super.init()
    }

    @objc(arrayForChains:)
    static func arrayForChains(_ chains: [RadarChain]?) -> [[String: Any]]? {
        chains?.map { $0.dictionaryValue() }
    }

    func dictionaryValue() -> [String: Any] {
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
