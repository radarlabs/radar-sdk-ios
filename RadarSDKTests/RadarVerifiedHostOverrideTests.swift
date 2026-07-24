//
//  RadarVerifiedHostOverrideTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import XCTest

@testable import RadarSDK

final class RadarVerifiedHostOverrideTests: XCTestCase {

    private var apiHelperMock: RadarAPIHelperMock!

    override func setUp() {
        super.setUp()
        Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")

        apiHelperMock = RadarAPIHelperMock()
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = ["meta": ["config": [:]]]
        RadarAPIClient.sharedInstance().apiHelper = apiHelperMock
    }

    // MARK: - getConfigForUsage

    func test_getConfig_verified_noOverride_usesPrimaryHost() {
        let exp = expectation(description: "getConfig completes")
        RadarAPIClient.sharedInstance().getConfigForUsage("verify", verified: true) { _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertTrue(url.hasPrefix(RadarSettings.DefaultVerifiedHost), "expected primary verified host, got \(url)")
    }

    func test_getConfig_verified_withOverride_usesSecondaryHost() {
        let exp = expectation(description: "getConfig completes")
        RadarAPIClient.sharedInstance().getConfigForUsage(
            "verify",
            verified: true,
            useSecondaryVerifiedHost: true
        ) { _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertTrue(url.hasPrefix(RadarSettings.defaultVerifiedHostSecondary), "expected secondary verified host, got \(url)")
    }

    func test_getConfig_nonVerified_ignoresOverride() {
        let exp = expectation(description: "getConfig completes")
        RadarAPIClient.sharedInstance().getConfigForUsage(
            "verify",
            verified: false,
            useSecondaryVerifiedHost: true
        ) { _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertFalse(url.hasPrefix(RadarSettings.defaultVerifiedHostSecondary), "non-verified request must not use secondary; got \(url)")
        XCTAssertTrue(url.hasPrefix(RadarSettings.DefaultHost), "expected standard host for non-verified, got \(url)")
    }

    // MARK: - trackWithLocation

    func test_track_verified_withOverride_usesSecondaryHost() {
        let exp = expectation(description: "track completes")
        let location = CLLocation(latitude: 40.0, longitude: -73.0)
        RadarAPIClient.sharedInstance().track(
            with: location,
            stopped: false,
            foreground: true,
            source: .foregroundLocation,
            replayed: false,
            beacons: nil,
            indoorLocation: nil,
            verified: true,
            fraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            reason: nil,
            transactionId: nil,
            useSecondaryVerifiedHost: true
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertTrue(url.hasPrefix(RadarSettings.defaultVerifiedHostSecondary), "expected secondary verified host on track, got \(url)")
        XCTAssertTrue(url.contains("/v1/track"), "expected /v1/track path, got \(url)")
    }

    func test_track_verified_noOverride_usesPrimaryHost() {
        let exp = expectation(description: "track completes")
        let location = CLLocation(latitude: 40.0, longitude: -73.0)
        RadarAPIClient.sharedInstance().track(
            with: location,
            stopped: false,
            foreground: true,
            source: .foregroundLocation,
            replayed: false,
            beacons: nil,
            indoorLocation: nil,
            verified: true,
            fraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            reason: nil,
            transactionId: nil,
            useSecondaryVerifiedHost: false
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertTrue(url.hasPrefix(RadarSettings.DefaultVerifiedHost), "expected primary verified host on track, got \(url)")
    }

    func test_track_nonVerified_ignoresOverride() {
        let exp = expectation(description: "track completes")
        let location = CLLocation(latitude: 40.0, longitude: -73.0)
        RadarAPIClient.sharedInstance().track(
            with: location,
            stopped: false,
            foreground: true,
            source: .foregroundLocation,
            replayed: false,
            beacons: nil,
            indoorLocation: nil,
            verified: false,
            fraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            reason: nil,
            transactionId: nil,
            useSecondaryVerifiedHost: true
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertFalse(url.hasPrefix(RadarSettings.defaultVerifiedHostSecondary), "non-verified track must not use secondary; got \(url)")
        XCTAssertTrue(url.hasPrefix(RadarSettings.DefaultHost), "expected standard host for non-verified track, got \(url)")
    }

    // MARK: - RadarInitializeOptions roundtrip

    func test_initializeOptions_trackVerifiedAutoFailover_defaultsFalse() {
        let options = RadarInitializeOptions()
        XCTAssertFalse(options.trackVerifiedAutoFailover)
    }

    func test_initializeOptions_trackVerifiedAutoFailover_roundtripsThroughDictionary() {
        let options = RadarInitializeOptions()
        options.trackVerifiedAutoFailover = true

        let dict = options.dictionaryValue()
        XCTAssertEqual(dict["trackVerifiedAutoFailover"] as? NSNumber, NSNumber(value: true))

        let restored = RadarInitializeOptions(dict: dict)
        XCTAssertTrue(restored.trackVerifiedAutoFailover)
    }

    func test_initializeOptions_networkTimeoutInterval_defaultsToTen() {
        let options = RadarInitializeOptions()
        XCTAssertEqual(options.networkTimeoutInterval, 10, accuracy: 0.001)
    }

    func test_initializeOptions_networkTimeoutInterval_roundtripsThroughDictionary() {
        let options = RadarInitializeOptions()
        options.networkTimeoutInterval = 45

        let dict = options.dictionaryValue()
        let value = dict["networkTimeoutInterval"] as? NSNumber
        XCTAssertEqual(value?.doubleValue ?? 0, 45, accuracy: 0.001)

        let restored = RadarInitializeOptions(dict: dict)
        XCTAssertEqual(restored.networkTimeoutInterval, 45, accuracy: 0.001)
    }

    // MARK: - Secondary host constant

    func test_defaultVerifiedHostSecondary_isExpected() {
        XCTAssertEqual(RadarSettings.defaultVerifiedHostSecondary, "https://api-verified.radar.com")
    }
}
