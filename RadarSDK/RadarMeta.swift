//
//  RadarMeta.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarMeta)
@objcMembers
internal class RadarMeta: NSObject {

    public var trackingOptions: RadarTrackingOptions?
    public var sdkConfiguration: RadarSdkConfiguration?

    @objc(fromDictionary:)
    public static func fromDictionary(_ dict: [AnyHashable: Any]?) -> RadarMeta {
        let meta = RadarMeta()

        if let trackingOptionsDict = dict?["trackingOptions"] as? [AnyHashable: Any] {
            meta.trackingOptions = RadarTrackingOptions(from: trackingOptionsDict)
        }
        if let sdkConfigurationDict = dict?["sdkConfiguration"] as? [String: Any] {
            meta.sdkConfiguration = RadarSdkConfiguration(dict: sdkConfigurationDict)
        }

        return meta
    }
}
