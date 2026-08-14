//
//  RadarSegment.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

struct RadarSegmentSwift: Codable, Sendable, Equatable {
    let description: String
    let externalId: String

    enum CodingKeys: String, CodingKey {
        case description
        case externalId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Both are required: the ObjC parser returns nil unless it finds two strings.
        description = try container.decode(String.self, forKey: .description)
        externalId = try container.decode(String.self, forKey: .externalId)
    }

    init(description: String, externalId: String) {
        self.description = description
        self.externalId = externalId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .description)
        try container.encode(externalId, forKey: .externalId)
    }
}
