//
//  RadarMeta.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarMeta) @objcMembers
class RadarMeta: NSObject {
    var trackingOptions: RadarTrackingOptions?
    var sdkConfiguration: RadarSdkConfiguration?

    static func from(dictionary dict: [String: Any]?) -> RadarMeta? {
        let meta = RadarMeta()

        if let dict {
            if let trackingOptionsDict = dict["trackingOptions"] as? [String: Any] {
                meta.trackingOptions = RadarTrackingOptions(from: trackingOptionsDict)
            }
            if let sdkConfigurationDict = dict["sdkConfiguration"] as? [String: Any] {
                meta.sdkConfiguration = RadarSdkConfiguration(dict: sdkConfigurationDict)
            }
        }

        return meta
    }
}
