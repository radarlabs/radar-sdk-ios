//
//  MockRadarPermissionsHelper.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation

@testable import RadarSDK

@MainActor
final class MockRadarPermissionsHelper: RadarPermissionsHelping {
    var mockAuthorizationStatus: CLAuthorizationStatus = .authorizedAlways
    var mockRangingAvailable: Bool = true

    func locationAuthorizationStatus() -> CLAuthorizationStatus {
        mockAuthorizationStatus
    }

    func isRangingAvailable() -> Bool {
        mockRangingAvailable
    }
}
