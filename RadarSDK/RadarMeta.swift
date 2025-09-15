//
//  RadarMeta.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/15/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

internal class RadarMeta {
    let trackingOptions: RadarTrackingOptions?
    let sdkConfiguration: RadarSdkConfiguration?
    
    init(from dict: [String: Any]?) {
        trackingOptions = RadarTrackingOptions(from: dict?["trackingOptions"] as? [String: Any])
        sdkConfiguration = RadarSdkConfiguration(from: dict?["sdkConfiguration"] as? [String : Any])
    }
}
