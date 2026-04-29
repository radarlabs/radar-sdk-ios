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

    override func tearDown() {
        RadarSettings.initializeOptions = nil
        super.tearDown()
    }

    // MARK: - trackVerified failover decision

    private func configUrls() -> [String] {
        apiHelperMock.urlHistory.compactMap { $0 as? String }.filter { $0.contains("/v1/config") }
    }

    func test_trackVerified_autoFailoverOff_neverCallsSecondary() {
        let options = RadarInitializeOptions()
        options.trackVerifiedAutoFailover = false
        RadarSettings.initializeOptions = options
        // No `meta` — would have triggered failover if the flag were on.
        apiHelperMock.mockResponse = [:]

        let exp = expectation(description: "trackVerified completes")
        RadarVerificationManager.sharedInstance().trackVerified { _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)

        let urls = configUrls()
        XCTAssertEqual(urls.count, 1, "expected one /v1/config call, got \(urls)")
        XCTAssertTrue(urls[0].hasPrefix(RadarSettings.DefaultVerifiedHost))
    }

    func test_trackVerified_autoFailoverOn_primaryHasMeta_doesNotCallSecondary() {
        let options = RadarInitializeOptions()
        options.trackVerifiedAutoFailover = true
        RadarSettings.initializeOptions = options
        apiHelperMock.mockResponse = ["meta": ["config": [:]]]

        let exp = expectation(description: "trackVerified completes")
        RadarVerificationManager.sharedInstance().trackVerified { _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)

        let urls = configUrls()
        XCTAssertEqual(urls.count, 1, "expected one /v1/config call, got \(urls)")
        XCTAssertTrue(urls[0].hasPrefix(RadarSettings.DefaultVerifiedHost))
    }

    func test_trackVerified_autoFailoverOn_primaryNoMeta_callsSecondary() {
        let options = RadarInitializeOptions()
        options.trackVerifiedAutoFailover = true
        RadarSettings.initializeOptions = options
        apiHelperMock.mockResponse = [:]

        let exp = expectation(description: "trackVerified completes")
        RadarVerificationManager.sharedInstance().trackVerified { _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)

        let urls = configUrls()
        XCTAssertEqual(urls.count, 2, "expected primary then secondary /v1/config calls, got \(urls)")
        XCTAssertTrue(urls[0].hasPrefix(RadarSettings.DefaultVerifiedHost), "first call should hit primary, got \(urls[0])")
        XCTAssertTrue(urls[1].hasPrefix(RadarSettings.defaultVerifiedHostSecondary), "second call should hit secondary, got \(urls[1])")
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
        let secondary = RadarSettings.defaultVerifiedHostSecondary
        RadarAPIClient.sharedInstance().getConfigForUsage(
            "verify",
            verified: true,
            verifiedHostOverride: secondary
        ) { _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertTrue(url.hasPrefix(secondary), "expected secondary verified host, got \(url)")
    }

    func test_getConfig_nonVerified_ignoresOverride() {
        let exp = expectation(description: "getConfig completes")
        let secondary = RadarSettings.defaultVerifiedHostSecondary
        RadarAPIClient.sharedInstance().getConfigForUsage(
            "verify",
            verified: false,
            verifiedHostOverride: secondary
        ) { _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertFalse(url.hasPrefix(secondary), "non-verified request must not use override; got \(url)")
        XCTAssertTrue(url.hasPrefix(RadarSettings.DefaultHost), "expected standard host for non-verified, got \(url)")
    }

    // MARK: - trackWithLocation

    func test_track_verified_withOverride_usesSecondaryHost() {
        let exp = expectation(description: "track completes")
        let secondary = RadarSettings.defaultVerifiedHostSecondary
        let location = CLLocation(latitude: 40.0, longitude: -73.0)
        RadarAPIClient.sharedInstance().track(
            with: location,
            stopped: false,
            foreground: true,
            source: .foregroundLocation,
            replayed: false,
            beacons: nil,
            indoorScan: nil,
            verified: true,
            fraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            reason: nil,
            transactionId: nil,
            verifiedHostOverride: secondary
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertTrue(url.hasPrefix(secondary), "expected secondary verified host on track, got \(url)")
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
            indoorScan: nil,
            verified: true,
            fraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            reason: nil,
            transactionId: nil,
            verifiedHostOverride: nil
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertTrue(url.hasPrefix(RadarSettings.DefaultVerifiedHost), "expected primary verified host on track, got \(url)")
    }

    func test_track_nonVerified_ignoresOverride() {
        let exp = expectation(description: "track completes")
        let secondary = RadarSettings.defaultVerifiedHostSecondary
        let location = CLLocation(latitude: 40.0, longitude: -73.0)
        RadarAPIClient.sharedInstance().track(
            with: location,
            stopped: false,
            foreground: true,
            source: .foregroundLocation,
            replayed: false,
            beacons: nil,
            indoorScan: nil,
            verified: false,
            fraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            reason: nil,
            transactionId: nil,
            verifiedHostOverride: secondary
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertFalse(url.hasPrefix(secondary), "non-verified track must not use override; got \(url)")
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

    // MARK: - Secondary host constant

    func test_defaultVerifiedHostSecondary_isExpected() {
        XCTAssertEqual(RadarSettings.defaultVerifiedHostSecondary, "https://api-verified.radar.com")
    }
}
