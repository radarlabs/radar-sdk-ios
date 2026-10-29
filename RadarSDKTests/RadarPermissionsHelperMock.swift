//
//  RadarPermissionsHelperMock.swift
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

import CoreLocation

@testable import RadarSDK

/// Reports `mockLocationAuthorizationStatus` instead of the device's authorization status.
final class RadarPermissionsHelperMock: RadarPermissionsHelper {
    var mockLocationAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    override func locationAuthorizationStatus() -> CLAuthorizationStatus {
        mockLocationAuthorizationStatus
    }
}
