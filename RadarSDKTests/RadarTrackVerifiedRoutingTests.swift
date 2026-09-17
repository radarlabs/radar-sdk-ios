import CoreLocation
import XCTest

@testable import RadarSDK

extension RadarVerifiedHostOverrideTests {
    func test_track_collectedPayloadRequiresValidContextBeforeSending() throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        let originalAnonymous = RadarSettings.anonymousTrackingEnabled
        defer {
            client.apiHelper = originalHelper
            RadarSettings.anonymousTrackingEnabled = originalAnonymous
        }
        struct Scenario {
            let payload: String?
            let installId: String?
            let anonymous: Bool
        }
        let scenarios = [
            Scenario(payload: nil, installId: "captured-install", anonymous: false),
            Scenario(payload: "", installId: "captured-install", anonymous: false),
            Scenario(payload: "encrypted-envelope", installId: nil, anonymous: false),
            Scenario(payload: "encrypted-envelope", installId: "captured-install", anonymous: true),
        ]

        for scenario in scenarios {
            RadarSettings.anonymousTrackingEnabled = scenario.anonymous
            let helper = MainQueueAPIHelperMock()
            client.apiHelper = helper
            let finished = expectation(description: "Invalid captured context")
            finished.assertForOverFulfill = true
            RadarTrackTestBridge.track(
                withPayload: scenario.payload, verified: true, secondary: false,
                headers: ["Authorization": "captured-test-key"], installId: scenario.installId
            ) { status, _, _, _, _, _, _ in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(status, .errorUnknown)
                finished.fulfill()
            }
            wait(for: [finished], timeout: 5)
            XCTAssertNil(helper.lastMethod)
        }
    }

    func test_track_capturedContextIsUsedOnlyForVerifiedRequests() throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        defer { client.apiHelper = originalHelper }
        let headers = [
            "Authorization": "captured-test-key",
            "X-Radar-Product": "captured-product",
            "X-Radar-SDK-Version": "captured-version",
            "Content-Type": "application/json",
        ]

        for verified in [true, false] {
            let helper = MainQueueAPIHelperMock()
            helper.mockStatus = .errorServer
            client.apiHelper = helper
            let instance = MockEncryptedFraudInstance(result: ["payload": "encrypted-envelope"])
            let preparer = try makeTrackPreparer(instance: instance)
            let finished = expectation(description: "Track with captured context")
            finished.assertForOverFulfill = true
            trackForEncryptionTest(
                preparer, verified: verified, headers: headers, installId: "captured-install"
            ) { _, _, _, _, _, _, _ in
                finished.fulfill()
            }
            wait(for: [finished], timeout: 5)

            if verified {
                XCTAssertEqual(helper.lastHeaders as? [String: String], headers)
                XCTAssertEqual(helper.lastParams?["installId"] as? String, "captured-install")
                let context = try XCTUnwrap(instance.recordedOptions().first)
                XCTAssertEqual(instance.recordedOptions().count, 1)
                XCTAssertEqual(context["installId"] as? String, "captured-install")
                XCTAssertEqual(context["authorization"] as? String, headers["Authorization"])
                XCTAssertEqual(context["product"] as? String, headers["X-Radar-Product"])
                XCTAssertEqual(context["sdkVersion"] as? String, headers["X-Radar-SDK-Version"])
            } else {
                XCTAssertEqual(helper.lastHeaders?["Authorization"] as? String, RadarSettings.publishableKey)
                XCTAssertEqual(helper.lastParams?["installId"] as? String, RadarSettings.installId)
                XCTAssertTrue(instance.recordedOptions().isEmpty)
            }
        }
    }

    func test_track_capturedHeadersWithoutAuthorizationFailBeforeSending() throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        defer { client.apiHelper = originalHelper }

        let helper = MainQueueAPIHelperMock()
        client.apiHelper = helper

        let finished = expectation(description: "Missing captured authorization")
        finished.assertForOverFulfill = true

        RadarTrackTestBridge.track(
            withPayload: "encrypted-payload",
            verified: true,
            secondary: false,
            headers: [:],
            installId: "captured-install"
        ) { status, _, _, _, _, _, _ in
            XCTAssertEqual(status, .errorPublishableKey)
            finished.fulfill()
        }

        wait(for: [finished], timeout: 5)
        XCTAssertNil(helper.lastMethod)
    }

    func test_track_nonVerified_usesStandardHostWithoutFraudPayload() {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        defer { client.apiHelper = originalHelper }

        let helper = MainQueueAPIHelperMock()
        helper.mockStatus = .errorServer
        helper.mockResponse = ["meta": ["config": [:]]]
        client.apiHelper = helper

        let finished = expectation(description: "Ordinary track completes")
        finished.assertForOverFulfill = true

        RadarTrackTestBridge.track(
            withPayload: nil,
            verified: false,
            secondary: true,
            headers: nil,
            installId: nil
        ) { _, _, _, _, _, _, _ in
            finished.fulfill()
        }

        wait(for: [finished], timeout: 5)

        XCTAssertEqual(helper.lastMethod, "POST")
        XCTAssertEqual(helper.lastUrl, "\(RadarSettings.host)/v1/track")
        XCTAssertNil(helper.lastParams?["fraudPayload"])
        XCTAssertEqual(helper.lastParams?["latitude"] as? Double, 40.0)
        XCTAssertEqual(helper.lastParams?["longitude"] as? Double, -73.0)
    }

    func test_track_verified_encryptsBeforeHelperOnBothHosts() throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        defer { client.apiHelper = originalHelper }

        for secondary in [false, true] {
            let helper = MainQueueAPIHelperMock()
            helper.mockStatus = .errorServer
            helper.mockResponse = ["meta": ["config": [:]]]
            client.apiHelper = helper
            let instance = MockEncryptedFraudInstance(result: ["payload": "encrypted-envelope"])
            let preparer = try makeTrackPreparer(instance: instance, options: ["nonce": "test-nonce"])
            let finished = expectation(description: "Verified track completes")
            finished.assertForOverFulfill = true
            trackForEncryptionTest(preparer, secondary: secondary) { _, _, _, _, _, _, _ in
                finished.fulfill()
            }
            wait(for: [finished], timeout: 5)

            let host = secondary ? RadarSettings.defaultVerifiedHostSecondary : RadarSettings.verifiedHost
            XCTAssertEqual(helper.lastUrl, "\(host)/v1/track")
            XCTAssertEqual(helper.lastMethod, "POST")
            XCTAssertEqual(helper.lastParams?["fraudPayload"] as? String, "encrypted-envelope")
            XCTAssertEqual(helper.lastParams?["latitude"] as? Double, 40.0)
            XCTAssertEqual(helper.lastParams?["longitude"] as? Double, -73.0)
            XCTAssertEqual(instance.recordedOptions().count, 1)
            let context = try XCTUnwrap(instance.recordedOptions().first)
            XCTAssertEqual(context["method"] as? String, "POST")
            XCTAssertEqual(context["canonicalRoute"] as? String, "/v1/track")
            XCTAssertEqual(context["nonce"] as? String, "test-nonce")
            XCTAssertEqual(context["installId"] as? String, helper.lastParams?["installId"] as? String)
            for (field, header) in [
                ("authorization", "Authorization"), ("product", "X-Radar-Product"),
                ("sdkVersion", "X-Radar-SDK-Version"), ("origin", "Origin"),
            ] {
                XCTAssertEqual(context[field] as? String, helper.lastHeaders?[header] as? String)
            }
        }
    }

    func test_track_preparationFailures_neverReachHelper() throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        defer { client.apiHelper = originalHelper }
        let scenarios: [(NSObject?, RadarStatus)] = [
            (nil, .errorPlugin),
            (MockLegacyFraudInstance(), .errorPlugin),
            (MockEncryptedFraudInstance(result: nil), .errorUnknown),
            (MockEncryptedFraudInstance(result: ["payload": ""]), .errorUnknown),
            (MockEncryptedFraudInstance(result: ["error": "failed", "payload": "must-not-send"]), .errorUnknown),
        ]

        for (instance, expectedStatus) in scenarios {
            let helper = MainQueueAPIHelperMock()
            client.apiHelper = helper

            let fraudSDK = instance.flatMap {
                RadarSDKFraud(instance: $0)
            }
            if expectedStatus == .errorPlugin {
                XCTAssertNil(fraudSDK)
            } else {
                XCTAssertNotNil(fraudSDK)
            }

            let preparer = RadarTrackVerifiedRequestPreparer(
                fraudSDK: fraudSDK,
                options: [:]
            )

            let finished = expectation(description: "One preparation failure callback")
            finished.assertForOverFulfill = true
            trackForEncryptionTest(preparer) { status, _, _, _, _, _, _ in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(status, expectedStatus)
                finished.fulfill()
            }
            wait(for: [finished], timeout: 5)
            XCTAssertNil(helper.lastMethod)
        }
    }
}
