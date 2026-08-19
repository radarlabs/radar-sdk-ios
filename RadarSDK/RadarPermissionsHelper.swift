//
//  RadarPermissionsHelperSwift.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

protocol RadarPermissionsHelping: Sendable {
    func locationAuthorizationStatus() -> CLAuthorizationStatus
    func isRangingAvailable() -> Bool
}

final class RadarPermissionsHelperSwift: RadarPermissionsHelping {
    func locationAuthorizationStatus() -> CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }

    func isRangingAvailable() -> Bool {
        CLLocationManager.isRangingAvailable()
    }

    // TODO: finish migrating permissions helper
}
