//
//  CLLocation+RadarTests.swift
//  RadarSDKTests
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

import XCTest
import CoreLocation
@testable import RadarSDK

class CLLocation_RadarTests: XCTestCase {

    // "1060 West Addison? That's Wrigley Field!"
    // https://www.imdb.com/title/tt0080455/characters/nm0000004
    let lat: CLLocationDegrees = 41.947746
    let lon: CLLocationDegrees = -87.656036

    func testValidLocationOk() {
        let location = CLLocation(coordinate: .init(latitude: lat, longitude: lon),
                                  altitude: 1.0,
                                  horizontalAccuracy: 1.0,
                                  verticalAccuracy: 1.0,
                                  timestamp: Date())
        XCTAssertTrue(location.isValid)
    }

    func testIsValidForLocationWithInvalidLatitudeReturnsFalse() {
        let location = CLLocation(coordinate: .init(latitude: 0.0, longitude: lon),
                                  altitude: 1.0,
                                  horizontalAccuracy: 1.0,
                                  verticalAccuracy: 1.0,
                                  timestamp: Date())
        XCTAssertFalse(location.isValid)
    }

    func testIsValidForLocationWithLatitudeNearZeroReturnsTrue() {
        let location = CLLocation(coordinate: .init(latitude: 0.00001, longitude: lon),
                                  altitude: 1.0,
                                  horizontalAccuracy: 1.0,
                                  verticalAccuracy: 1.0,
                                  timestamp: Date())
        XCTAssertTrue(location.isValid)
    }

    func testIsValidForLocationWithInvalidLongitudeReturnsFalse() {
        let location = CLLocation(coordinate: .init(latitude: lat, longitude: 0.0),
                                  altitude: 1.0,
                                  horizontalAccuracy: 1.0,
                                  verticalAccuracy: 1.0,
                                  timestamp: Date())
        XCTAssertFalse(location.isValid)
    }

    func testIsValidForLocationWithInvalidHorizontalAccuracyReturnsFalse() {
        let location = CLLocation(coordinate: .init(latitude: lat, longitude: lon),
                                  altitude: 1.0,
                                  horizontalAccuracy: 0.0,
                                  verticalAccuracy: 1.0,
                                  timestamp: Date())
        XCTAssertFalse(location.isValid)
    }

}
