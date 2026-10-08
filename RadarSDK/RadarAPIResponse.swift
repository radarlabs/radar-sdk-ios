//
//  RadarAPIResponse.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 10/1/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

struct SearchBeaconResponse: Codable {
    let meta: Meta
    struct Meta: Codable {
        let code: Int
        let settings: Settings
        struct Settings: Codable {
            let beacons: Beacons
            struct Beacons: Codable {
                let uuids: [String]
                let uids: [String]
            }
        }
    }
    let beacons: [RadarBeaconSwift]
}


struct RadarResponse<T: Codable>: Codable {
    let meta: Meta
    struct Meta: Codable {
        let code: Int
    }
    let data: T
}
