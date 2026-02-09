//
//  Resource.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 2/8/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

extension Otel {
    struct Resource: Codable {
        let attributes: [KeyValue]
        let droppedAttributesCount: Int
        let entityRefs: [EntityRef]
    }
}
