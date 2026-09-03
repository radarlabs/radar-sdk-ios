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
