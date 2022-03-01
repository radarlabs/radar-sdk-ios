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
        let location = CLLocation(latitude: lat, longitude: lon)
        XCTAssertTrue(location.isValid)
    }

}
