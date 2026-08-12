//
//  RadarConfig.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarConfig) @objcMembers
class RadarConfig: NSObject {
    var meta: RadarMeta?
    var nonce: String?

    static func from(dictionary dict: [String: Any]?) -> RadarConfig? {
        let config = RadarConfig()

        if let dict {
            if let metaDict = dict["meta"] as? [String: Any] {
                config.meta = RadarMeta.from(dictionary: metaDict)
            }
            if let nonce = dict["nonce"] as? String {
                config.nonce = nonce
            }
        }

        return config
    }
}
