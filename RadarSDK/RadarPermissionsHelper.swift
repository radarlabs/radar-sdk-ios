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
    // Reads the status `locationManager:didChangeAuthorizationStatus:` caches, instead of
    // `CLLocationManager.authorizationStatus()`, a synchronous call into Core Location that can block
    // the main thread. Core Location reports the status when the manager is created on every launch and
    // whenever it changes. Until it has reported one, the cache is `.notDetermined`, so ask directly.
    func locationAuthorizationStatus() -> CLAuthorizationStatus {
        let cachedStatus = RadarState.shared.locationAuthorizationStatus
        return cachedStatus != .notDetermined ? cachedStatus : CLLocationManager.authorizationStatus()
    }

    func isRangingAvailable() -> Bool {
        CLLocationManager.isRangingAvailable()
    }

    // TODO: finish migrating permissions helper
}
