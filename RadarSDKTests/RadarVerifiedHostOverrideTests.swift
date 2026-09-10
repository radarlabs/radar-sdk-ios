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
            revealRiskId: nil,
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
            revealRiskId: nil,
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
            revealRiskId: nil,
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

    func test_track_nonVerified_ignoresPreparationHook() {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper

        let helper = PreparationRejectingAPIHelperMock()
        helper.mockStatus = .success
        helper.mockResponse = ["meta": ["config": [:]]]

        client.apiHelper = helper
        defer {
            client.apiHelper = originalHelper
        }

        let finished = expectation(description: "Ordinary track completes")
        finished.assertForOverFulfill = true

        client.track(
            with: CLLocation(latitude: 40.0, longitude: -73.0),
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
            revealRiskId: nil,
            useSecondaryVerifiedHost: true,
            prepareRequest: { _, completion in
                XCTFail("Ordinary tracking must not invoke fraud preparation")
                completion(.errorUnknown, nil, nil)
            }
        ) { _, _, _, _, _, _, _ in
            finished.fulfill()
        }

        wait(for: [finished], timeout: 5.0)

        XCTAssertEqual(helper.lastMethod, "POST")
        XCTAssertEqual(
            helper.lastUrl,
            "\(RadarSettings.host)/v1/track"
        )

        let params = helper.lastParams
        XCTAssertNotNil(params)
        XCTAssertNil(params?["fraudPayload"])
        XCTAssertEqual(params?["latitude"] as? Double, 40.0)
        XCTAssertEqual(params?["longitude"] as? Double, -73.0)
    }

    func test_verifiedPreparation_refreshesAttemptOnNetworkRetry() throws {
        // Reuse the Objective-C URLProtocol from the preparation tests.
        let protocolClass = try XCTUnwrap(
            NSClassFromString("RadarPreparationTestProtocol")
        )

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [protocolClass]

        let session = URLSession(configuration: configuration)
        defer {
            session.invalidateAndCancel()
        }

        let helper = RadarAPIHelper()
        helper.setValue(session, forKey: "standardSession")

        let instance = MockEncryptedFraudInstance(
            result: ["payload": "encrypted-envelope"]
        )
        let fraudSDK = try XCTUnwrap(RadarSDKFraud(instance: instance))

        let preparer = RadarTrackVerifiedRequestPreparer(
            fraudSDK: fraudSDK,
            options: ["nonce": "test-nonce"]
        )

        let finished = expectation(description: "Verified preparation retries")
        finished.assertForOverFulfill = true
        let startedAt = Int(Date().timeIntervalSince1970)

        helper.request(
            withMethod: "POST",
            url: "https://api-verified.radar.io/v1/track",
            headers: [
                "Content-Type": "application/json",
                "Authorization": "test-publishable-key",
                "X-Radar-Product": "test-product",
                "X-Radar-SDK-Version": "test-version",
            ],
            params: ["installId": "test-install"],
            sleep: false,
            logPayload: false,
            extendedTimeout: false,
            prepareRequest: { request, completion in
                // The retry must start from the original request.
                XCTAssertNil(
                    request.value(forHTTPHeaderField: "X-Test-Attempt")
                )

                preparer.prepareRequest(request) { status, prepared, error in
                    guard status == .success, var prepared else {
                        XCTFail("Preparation failed: \(String(describing: error))")
                        completion(status, nil, error)
                        return
                    }

                    do {
                        let bodyData = try XCTUnwrap(prepared.httpBody)
                        let bodyObject = try JSONSerialization.jsonObject(
                            with: bodyData
                        )
                        let body = try XCTUnwrap(
                            bodyObject as? [String: Any]
                        )
                        XCTAssertEqual(
                            body["fraudPayload"] as? String,
                            "encrypted-envelope"
                        )
                        XCTAssertEqual(
                            body["installId"] as? String,
                            "test-install"
                        )
                    } catch {
                        XCTFail("Invalid prepared body: \(error)")
                        completion(.errorUnknown, nil, error as NSError)
                        return
                    }

                    // Only controls the test transport's simulated failure.
                    prepared.setValue(
                        String(instance.recordedOptions().count),
                        forHTTPHeaderField: "X-Test-Attempt"
                    )
                    completion(.success, prepared, nil)
                }
            },
            completionHandler: { status, response, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(status, .success)
                XCTAssertNil(error)
                XCTAssertEqual(response?["ok"] as? Bool, true)
                finished.fulfill()
            }
        )

        wait(for: [finished], timeout: 5.0)

        let attempts = instance.recordedOptions()
        XCTAssertEqual(attempts.count, 2)

        let first = try XCTUnwrap(attempts.first)
        let second = try XCTUnwrap(attempts.last)
        let firstID = try XCTUnwrap(first["encryptionAttemptId"] as? String)
        let secondID = try XCTUnwrap(second["encryptionAttemptId"] as? String)

        XCTAssertEqual(firstID.count, 22)
        XCTAssertEqual(secondID.count, 22)
        XCTAssertNotEqual(firstID, secondID)

        let finishedAt = Int(Date().timeIntervalSince1970)

        for options in attempts {
            XCTAssertEqual(options["method"] as? String, "POST")
            XCTAssertEqual(options["canonicalRoute"] as? String, "/v1/track")
            XCTAssertEqual(options["environment"] as? String, "production")
            XCTAssertEqual(options["installId"] as? String, "test-install")
            XCTAssertEqual(options["nonce"] as? String, "test-nonce")
            XCTAssertEqual(options["product"] as? String, "test-product")
            XCTAssertEqual(options["sdkVersion"] as? String, "test-version")
            XCTAssertEqual(
                options["authorization"] as? String,
                "test-publishable-key"
            )
            XCTAssertNil(options["origin"])

            let issuedAt = try XCTUnwrap(options["issuedAt"] as? Int)
            XCTAssertGreaterThanOrEqual(issuedAt, startedAt)
            XCTAssertLessThanOrEqual(issuedAt, finishedAt)
        }
    }

    func test_verifiedRetryPreparationFailure_doesNotSendAgain() throws {
        RetryPreparationFailureProtocol.requests.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RetryPreparationFailureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let helper = RadarAPIHelper()
        helper.setValue(session, forKey: "standardSession")

        let instance = MockEncryptedFraudInstance(
            result: ["payload": "encrypted-envelope"]
        )
        let fraudSDK = try XCTUnwrap(RadarSDKFraud(instance: instance))
        let preparer = RadarTrackVerifiedRequestPreparer(
            fraudSDK: fraudSDK,
            options: [:]
        )

        let preparationCalls = expectation(description: "Two preparations")
        preparationCalls.expectedFulfillmentCount = 2
        preparationCalls.assertForOverFulfill = true
        let finished = expectation(description: "One final failure callback")
        finished.assertForOverFulfill = true
        let expectedError = NSError(domain: "RadarPreparationTest", code: 1)

        helper.request(
            withMethod: "POST",
            url: "https://api-verified.radar.io/v1/track",
            headers: ["Content-Type": "application/json"],
            params: ["installId": "test-install"],
            sleep: true,
            logPayload: false,
            extendedTimeout: false,
            prepareRequest: { request, completion in
                preparationCalls.fulfill()
                if instance.recordedOptions().isEmpty {
                    preparer.prepareRequest(request) { status, prepared, error in
                        completion(status, prepared, error)
                    }
                } else {
                    // Simulate encryption/preparation failing on the retry.
                    DispatchQueue.global().async {
                        completion(.errorUnknown, nil, expectedError)
                    }
                }
            },
            completionHandler: { status, response, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(status, .errorUnknown)
                XCTAssertNil(response)
                let actualError = error as NSError?
                XCTAssertEqual(actualError?.domain, expectedError.domain)
                XCTAssertEqual(actualError?.code, expectedError.code)
                finished.fulfill()
            }
        )

        wait(for: [preparationCalls, finished], timeout: 5.0)
        XCTAssertEqual(RetryPreparationFailureProtocol.requests.value, 1)
        XCTAssertEqual(instance.recordedOptions().count, 1)
    }

    func test_track_verified_forwardsPreparationOnBothHosts() throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        defer {
            client.apiHelper = originalHelper
        }

        for useSecondaryHost in [false, true] {
            let helper = PreparationCapturingAPIHelperMock()
            helper.mockStatus = .success
            helper.mockResponse = ["meta": ["config": [:]]]
            client.apiHelper = helper

            let finished = expectation(description: "Track completes")
            finished.assertForOverFulfill = true

            let hookCalled = expectation(description: "Supplied hook runs")
            hookCalled.assertForOverFulfill = true

            client.track(
                with: CLLocation(latitude: 40.0, longitude: -73.0),
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
                revealRiskId: nil,
                useSecondaryVerifiedHost: useSecondaryHost,
                prepareRequest: { request, completion in
                    var prepared = request
                    prepared.setValue("yes", forHTTPHeaderField: "X-Test-Prepared")
                    hookCalled.fulfill()
                    completion(.success, prepared, nil)
                }
            ) { _, _, _, _, _, _, _ in
                finished.fulfill()
            }

            wait(for: [finished], timeout: 5.0)

            let expectedHost = useSecondaryHost
                ? RadarSettings.defaultVerifiedHostSecondary
                : RadarSettings.verifiedHost

            XCTAssertEqual(helper.lastMethod, "POST")
            XCTAssertEqual(helper.lastUrl, "\(expectedHost)/v1/track")
            XCTAssertNotNil(helper.lastParams)
            XCTAssertNil(helper.lastParams?["fraudPayload"])

            let forwardedHook = try XCTUnwrap(helper.capturedPreparation)
            let url = try XCTUnwrap(URL(string: "\(expectedHost)/v1/track"))
            let prepared = expectation(description: "Preparation completes")
            prepared.assertForOverFulfill = true

            forwardedHook(URLRequest(url: url)) { status, request, error in
                XCTAssertEqual(status, .success)
                XCTAssertNil(error)
                XCTAssertEqual(request?.url, url)
                XCTAssertEqual(
                    request?.value(forHTTPHeaderField: "X-Test-Prepared"),
                    "yes"
                )
                prepared.fulfill()
            }

            wait(for: [hookCalled, prepared], timeout: 5.0)
        }
    }
}

private final class PreparationRejectingAPIHelperMock: RadarAPIHelperMock {
    override func request(
        withMethod method: String,
        url: String,
        headers: [AnyHashable: Any]?,
        params: [AnyHashable: Any]?,
        sleep: Bool,
        logPayload: Bool,
        extendedTimeout: Bool,
        prepareRequest: RadarRequestPreparation?,
        completionHandler: RadarAPICompletionHandler?
    ) {
        XCTFail("Ordinary tracking must use the original HTTP helper method")
        completionHandler?(.errorUnknown, nil, nil)
    }
}

private final class PreparationCapturingAPIHelperMock: RadarAPIHelperMock {
    var capturedPreparation: RadarRequestPreparation?

    override func request(
        withMethod method: String,
        url: String,
        headers: [AnyHashable: Any]?,
        params: [AnyHashable: Any]?,
        sleep: Bool,
        logPayload: Bool,
        extendedTimeout: Bool,
        prepareRequest: RadarRequestPreparation?,
        completionHandler: RadarAPICompletionHandler?
    ) {
        capturedPreparation = prepareRequest

        super.request(
            withMethod: method,
            url: url,
            headers: headers,
            params: params,
            sleep: sleep,
            logPayload: logPayload,
            extendedTimeout: extendedTimeout,
            completionHandler: completionHandler
        )
    }

}

private final class RetryFailureRequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        count += 1
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        count = 0
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
}

private final class RetryPreparationFailureProtocol: URLProtocol {
    static let requests = RetryFailureRequestCounter()

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requests.increment()
        client?.urlProtocol(
            self,
            didFailWithError: URLError(.networkConnectionLost)
        )
    }

    override func stopLoading() {}
}
