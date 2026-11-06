//
//  RadarTraceSamplingAPIClientTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import XCTest

@testable import RadarSDK

/// Covers the `RadarAPIClient` call sites that pass the server's sampling decision to the shared trace manager.
/// Each test uses its own session, since the shared manager keeps a session's first decision.
final class RadarTraceSamplingAPIClientTests: XCTestCase {

    private var apiHelperMock: RadarAPIHelperMock!
    private var restoreState: (() -> Void)?
    private var sessionId = ""

    override func setUp() {
        super.setUp()
        let originalAPIHelper = RadarAPIClient.sharedInstance().apiHelper
        let originalKey = RadarSettings.publishableKey
        let originalSession = RadarUserDefaults.double(forKey: .sessionId)
        let originalAnonymous = RadarSettings.anonymousTrackingEnabled
        restoreState = {
            RadarAPIClient.sharedInstance().apiHelper = originalAPIHelper
            RadarSettings.publishableKey = originalKey
            RadarUserDefaults.set(originalSession, forKey: .sessionId)
            RadarSettings.anonymousTrackingEnabled = originalAnonymous
        }
        RadarSettings.publishableKey = "prj_test_pk_radar_sdk_ios"
        RadarSettings.anonymousTrackingEnabled = false

        let session = Double(Int.random(in: 1_000_000_000...1_999_999_999))
        RadarUserDefaults.set(session, forKey: .sessionId)
        sessionId = RadarSettings.sessionId

        apiHelperMock = RadarAPIHelperMock()
        RadarAPIClient.sharedInstance().apiHelper = apiHelperMock
    }

    override func tearDown() {
        restoreState?()
        apiHelperMock = nil
        restoreState = nil
        super.tearDown()
    }

    func test_getConfig_tracingEnabled_samplesTheRequestSession() {
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = ["meta": ["sdkConfiguration": ["tracingEnabled": true]]]

        getConfig()

        XCTAssertEqual(RadarTraceManager.shared.samplingState(sessionId: sessionId), .sampled)
    }

    func test_getConfig_withoutTracingEnabled_doesNotSampleTheSession() {
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = ["meta": ["sdkConfiguration": [:]]]

        getConfig()

        XCTAssertEqual(RadarTraceManager.shared.samplingState(sessionId: sessionId), .notSampled)
    }

    func test_getConfig_tracingDisabled_doesNotSampleTheSession() {
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = ["meta": ["sdkConfiguration": ["tracingEnabled": false]]]

        getConfig()

        XCTAssertEqual(RadarTraceManager.shared.samplingState(sessionId: sessionId), .notSampled)
    }

    func test_getConfig_nonBooleanTracingEnabled_doesNotSampleTheSession() {
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = ["meta": ["sdkConfiguration": ["tracingEnabled": "true"]]]

        getConfig()

        XCTAssertEqual(RadarTraceManager.shared.samplingState(sessionId: sessionId), .notSampled)
    }

    func test_getConfig_malformedSettings_doesNotSampleTheSession() {
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = ["meta": ["sdkConfiguration": "not a dictionary"]]

        getConfig()

        XCTAssertEqual(RadarTraceManager.shared.samplingState(sessionId: sessionId), .notSampled)
    }

    func test_getConfig_failure_leavesTheSessionPending() {
        apiHelperMock.mockStatus = .errorServer
        apiHelperMock.mockResponse = ["meta": ["sdkConfiguration": ["tracingEnabled": true]]]

        getConfig()

        XCTAssertEqual(RadarTraceManager.shared.samplingState(sessionId: sessionId), .pending)
    }

    func test_getConfig_appliesTheDecisionToTheSessionSentWithTheRequest() {
        let helper = HoldingAPIHelper()
        RadarAPIClient.sharedInstance().apiHelper = helper
        let requestSession = sessionId

        let exp = expectation(description: "getConfig completes")
        RadarAPIClient.sharedInstance().getConfigForUsage("test", verified: false) { _, _ in
            exp.fulfill()
        }
        // The session changes while the request is in flight.
        RadarUserDefaults.set(RadarUserDefaults.double(forKey: .sessionId) + 1, forKey: .sessionId)
        helper.complete(.success, ["meta": ["sdkConfiguration": ["tracingEnabled": true]]])
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(RadarTraceManager.shared.samplingState(sessionId: requestSession), .sampled)
        XCTAssertEqual(RadarTraceManager.shared.samplingState(sessionId: RadarSettings.sessionId), .pending)
    }

    func test_track_tracingEnabled_samplesTheRequestSession() {
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = ["meta": ["featureSettings": ["tracingEnabled": true]]]

        track()

        XCTAssertEqual(RadarTraceManager.shared.samplingState(sessionId: sessionId), .sampled)
    }

    func test_track_anonymous_usesTheConfigDecisionNotTheTrackResponse() {
        // Anonymous tracks send no session, so the track response's featureSettings can't decide one. They also call
        // getConfig("track"), which sends the session, so the session is decided by that response's sdkConfiguration.
        // The mock returns the same response to both requests: tracingEnabled in featureSettings but not in
        // sdkConfiguration.
        RadarSettings.anonymousTrackingEnabled = true
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = ["meta": ["featureSettings": ["tracingEnabled": true]]]

        track()

        XCTAssertEqual(RadarTraceManager.shared.samplingState(sessionId: sessionId), .notSampled)
    }

    // MARK: - Helpers

    private func getConfig() {
        let exp = expectation(description: "getConfig completes")
        RadarAPIClient.sharedInstance().getConfigForUsage("test", verified: false) { _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    private func track() {
        let exp = expectation(description: "track completes")
        RadarAPIClient.sharedInstance().track(
            with: CLLocation(latitude: 40.0, longitude: -73.0),
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
            useSecondaryVerifiedHost: false
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
}

/// Holds a request's completion until the test calls `complete`, so the test can act while the request is in flight.
private final class HoldingAPIHelper: RadarAPIHelperMock {
    private var completion: RadarAPICompletionHandler?

    override func request(
        withMethod method: String,
        url: String,
        headers: [AnyHashable: Any]?,
        params: [AnyHashable: Any]?,
        sleep: Bool,
        logPayload: Bool,
        extendedTimeout: Bool,
        completionHandler: RadarAPICompletionHandler?
    ) {
        completion = completionHandler
    }

    func complete(_ status: RadarStatus, _ response: [AnyHashable: Any]) {
        completion?(status, response, nil)
    }
}
