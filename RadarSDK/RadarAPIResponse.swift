//
//  RadarAPIResponse.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 10/1/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
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

struct RadarTrackRequest {
    let host: RadarAPIHelper.RadarHost
    let params: [String: Any]
    let location: CLLocation
    let stopped: Bool
    let source: RadarLocationSource
    let options: RadarTrackingOptions
    let locationMetadata: [String: Any]
    let notificationsDelivered: [[String: Sendable]]
}

struct RadarTrackResponse {
    let res: [String: Any]
    // `nil` when the response is missing `events` or `user`. `RadarTrackHandler` treats that as a server error.
    let events: [RadarEvent]?
    let user: RadarUser?
    let nearbyGeofences: [RadarGeofence]?
    let config: RadarConfig?
    let token: RadarVerifiedLocationToken?
    let altitudeAdjustments: [[AnyHashable: Any]]?
    let inAppMessages: [RadarInAppMessage]
    let nearbyBeaconRegions: [[String: Any]]?
}
