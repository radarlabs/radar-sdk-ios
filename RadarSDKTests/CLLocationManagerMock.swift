//
//  CLLocationManagerMock.swift
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

import CoreLocation

/// Delivers `mockLocation` to the delegate on `requestLocation()`.
final class CLLocationManagerMock: CLLocationManager, @unchecked Sendable {
    var mockLocation: CLLocation?

    override var location: CLLocation? { mockLocation }

    // The test host has no background location capability, so ignore writes.
    override var pausesLocationUpdatesAutomatically: Bool {
        get { false }
        set {}
    }

    override func requestLocation() {
        if let mockLocation {
            delegate?.locationManager?(self, didUpdateLocations: [mockLocation])
        }
    }
}
