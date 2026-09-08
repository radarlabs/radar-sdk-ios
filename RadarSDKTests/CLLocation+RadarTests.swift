//
//  CLLocation+RadarTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing

@testable import RadarSDK

// "1060 West Addison? That's Wrigley Field!"
// https://www.imdb.com/title/tt0080455/characters/nm0000004
private let lat = 41.947746
private let lon = -87.656036

@Suite
struct CLLocationRadarTests {

    func assertValidLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, horizontalAccuracy: CLLocationDegrees, shouldBeValid: Bool) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coordinate, altitude: 1.0, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: 1.0, timestamp: Date())
        #expect(location.isValid == shouldBeValid)
    }

    @Test
    func validLocationOk() {
        assertValidLocation(latitude: lat, longitude: lon, horizontalAccuracy: 1.0, shouldBeValid: true)
    }

    @Test
    func isValidForLocationWithInvalidLatitudeReturnsFalse() {
        assertValidLocation(latitude: 0.0, longitude: lon, horizontalAccuracy: 1.0, shouldBeValid: false)
    }

    @Test
    func isValidForLocationWithLatitudeNearZeroReturnsTrue() {
        assertValidLocation(latitude: 0.000001, longitude: lon, horizontalAccuracy: 1.0, shouldBeValid: true)
    }

    @Test
    func isValidForLocationWithLatitudeWithinFloatEpsilonOfZeroReturnsFalse() {
        assertValidLocation(latitude: 0.000000009, longitude: lon, horizontalAccuracy: 1.0, shouldBeValid: false)
    }

    @Test
    func isValidForLocationWithInvalidLongitudeReturnsFalse() {
        assertValidLocation(latitude: lat, longitude: 0.0, horizontalAccuracy: 1.0, shouldBeValid: false)
    }

    @Test
    func isValidForLocationWithInvalidHorizontalAccuracyReturnsFalse() {
        assertValidLocation(latitude: lat, longitude: lon, horizontalAccuracy: 0.0, shouldBeValid: false)
    }
}
