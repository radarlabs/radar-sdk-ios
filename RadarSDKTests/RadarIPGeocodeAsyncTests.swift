//
//  RadarIPGeocodeAsyncTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/1/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import XCTest

@testable import RadarSDK

final class RadarIPGeocodeAsyncTests: XCTestCase {
    
    private var apiHelperMock: RadarAPIHelperMock!
    
    override func setUp() {
        super.setUp()
        Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")
        
        apiHelperMock = RadarAPIHelperMock()
        RadarAPIClient.sharedInstance().apiHelper = apiHelperMock
    }
    
    // Regression guard for the `3.34.1` "Ambiguous use of ipGeocode()" break
    func test_ipGeocode_async_isUnambiguous_andReturnsThreeTuple() async {
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = RadarTestUtils.jsonDictionary(fromResource: "geocode_ip")
        
        let (status, address, proxy) = await Radar.ipGeocode()
        
        XCTAssertEqual(status, .success)
        XCTAssertNotNil(address)
        XCTAssertTrue(proxy)
    }
}
