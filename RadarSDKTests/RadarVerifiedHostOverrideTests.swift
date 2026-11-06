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

    /// Backstop for waits in the verified-track tests. Every callback these tests wait for
    /// arrives within milliseconds; the margin only absorbs a loaded CI simulator.
    static let callbackTimeout: TimeInterval = 15

    private var apiHelperMock: RadarAPIHelperMock!
    private var restoreState: (() -> Void)?
    // Tasks started by `trackForEncryptionTest`, cancelled in `tearDown` so a task a test
    // left running can't send a track through a later test's API helper.
    var pendingTrackTasks: [Task<Void, Never>] = []
    // Helpers from `makeMainQueueHelper`, invalidated in `tearDown`.
    private var mainQueueHelpers: [MainQueueAPIHelperMock] = []

    override func setUp() {
        super.setUp()
        let client = RadarAPIClient.sharedInstance()
        let delegateHolder = RadarDelegateHolder.sharedInstance()
        let replayBuffer = RadarReplayBuffer.sharedInstance
        let originalAPIHelper = client.apiHelper
        let originalKey = RadarSettings.publishableKey
        let originalDelegate = delegateHolder.delegate
        let originalReplays = replayBuffer.mutableReplayBuffer
        let originalAnonymous = RadarSettings.anonymousTrackingEnabled
        restoreState = {
            client.apiHelper = originalAPIHelper
            RadarSettings.publishableKey = originalKey
            delegateHolder.delegate = originalDelegate
            replayBuffer.mutableReplayBuffer = originalReplays
            RadarSettings.anonymousTrackingEnabled = originalAnonymous
            TrackRetryProtocol.state.reset(failures: [])
        }
        // Configure authentication without starting asynchronous SDK initialization.
        RadarSettings.publishableKey = "prj_test_pk_radar_sdk_ios"

        // Start from a clean slate rather than whatever earlier tests (in this class or
        // others, such as ones that call `Radar.initialize`) left in the shared singletons.
        delegateHolder.delegate = nil
        replayBuffer.mutableReplayBuffer = []
        replayBuffer.cancelBatchTimer()
        RadarSettings.anonymousTrackingEnabled = false
        TrackRetryProtocol.state.reset(failures: [])

        apiHelperMock = RadarAPIHelperMock()
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = ["meta": ["config": [:]]]
        client.apiHelper = apiHelperMock
    }

    override func tearDown() {
        for task in pendingTrackTasks {
            task.cancel()
        }
        pendingTrackTasks = []
        for helper in mainQueueHelpers {
            helper.invalidate()
        }
        mainQueueHelpers = []
        restoreState?()
        apiHelperMock = nil
        restoreState = nil
        super.tearDown()
    }

    /// A `MainQueueAPIHelperMock` that stops delivering callbacks when this test ends, so a
    /// response still in flight can't reach a later test's expectations or delegate.
    func makeMainQueueHelper() -> MainQueueAPIHelperMock {
        let helper = MainQueueAPIHelperMock()
        mainQueueHelpers.append(helper)
        return helper
    }

    // MARK: - getConfigForUsage

    func test_getConfig_verified_noOverride_usesPrimaryHost() {
        let exp = expectation(description: "getConfig completes")
        RadarAPIClient.sharedInstance().getConfigForUsage("verify", verified: true) { _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.callbackTimeout)

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
        wait(for: [exp], timeout: Self.callbackTimeout)

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
        wait(for: [exp], timeout: Self.callbackTimeout)

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
            preparedFraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            expectedAddress: nil,
            reason: nil,
            transactionId: nil,
            revealRiskId: nil,
            useSecondaryVerifiedHost: true
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.callbackTimeout)

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
            preparedFraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            expectedAddress: nil,
            reason: nil,
            transactionId: nil,
            revealRiskId: nil,
            useSecondaryVerifiedHost: false
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.callbackTimeout)

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
            preparedFraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            expectedAddress: nil,
            reason: nil,
            transactionId: nil,
            revealRiskId: nil,
            useSecondaryVerifiedHost: true
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.callbackTimeout)

        let url = apiHelperMock.lastUrl ?? ""
        XCTAssertFalse(url.hasPrefix(RadarSettings.defaultVerifiedHostSecondary), "non-verified track must not use secondary; got \(url)")
        XCTAssertTrue(url.hasPrefix(RadarSettings.DefaultHost), "expected standard host for non-verified track, got \(url)")
    }

    // MARK: - RadarInitializeOptions roundtrip

    func test_initializeOptions_trackVerifiedAutoFailover_defaultsTrue() {
        let options = RadarInitializeOptions()
        XCTAssertTrue(options.trackVerifiedAutoFailover)
    }

    func test_initializeOptions_trackVerifiedAutoFailover_roundtripsThroughDictionary() {
        let options = RadarInitializeOptions()
        options.trackVerifiedAutoFailover = false

        let dict = options.dictionaryValue()
        XCTAssertEqual(dict["trackVerifiedAutoFailover"] as? NSNumber, NSNumber(value: false))

        let restored = RadarInitializeOptions(dict: dict)
        XCTAssertFalse(restored.trackVerifiedAutoFailover)
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
