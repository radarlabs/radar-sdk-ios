//
//  RadarJsonUtils.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 4/3/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

enum RadarJsonUtils {
    static func makeJson(_ entries: KeyValuePairs<String, Any?>) -> [String: Any] {
        var dict = [String: Any]()
        for (key, value) in entries {
            if let value {
                dict[key] = value
            }
        }
        return dict
    }
}
