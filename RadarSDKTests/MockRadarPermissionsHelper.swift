//
//  MockRadarPermissionsHelper.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

@testable import RadarSDK

final class MockRadarPermissionsHelper: RadarPermissionsHelping, @unchecked Sendable {
    private let lock = NSLock()
    private var _mockAuthorizationStatus: CLAuthorizationStatus = .authorizedAlways
    private var _mockRangingAvailable = true

    var mockAuthorizationStatus: CLAuthorizationStatus {
        get { lock.lock(); defer { lock.unlock() }; return _mockAuthorizationStatus }
        set { lock.lock(); defer { lock.unlock() }; _mockAuthorizationStatus = newValue }
    }

    var mockRangingAvailable: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _mockRangingAvailable }
        set { lock.lock(); defer { lock.unlock() }; _mockRangingAvailable = newValue }
    }

    func locationAuthorizationStatus() -> CLAuthorizationStatus { mockAuthorizationStatus }
    func isRangingAvailable() -> Bool { mockRangingAvailable }
}
