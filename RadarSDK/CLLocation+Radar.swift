//
//  CLLocation+Radar.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation

private let degreeEpsilon = 0.00000001

extension CLLocation {
    @objc var isValid: Bool {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let latitudeValid = abs(lat - 0.0) >= degreeEpsilon && lat > -90.0 && lat < 90.0
        let longitudeValid = abs(lon - 0.0) >= degreeEpsilon && lon > -180.0 && lon < 180.0
        let horizontalAccuracyValid = horizontalAccuracy > 0
        return latitudeValid && longitudeValid && horizontalAccuracyValid
    }
}
