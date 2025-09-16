//
//  RadarConfig.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/15/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

internal class RadarConfig {
    var meta: RadarMeta?
    var nonce: String?
    
    init(from dict: [String: Any]?) {
        meta = RadarMeta(from: dict?["meta"] as? [String: Any])
        nonce = dict?["nonce"] as? String
    }
}
