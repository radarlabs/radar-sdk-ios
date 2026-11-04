import CoreLocation
import XCTest

@testable import RadarSDK

extension RadarVerifiedHostOverrideTests {
    func test_track_missingAuthorizationFailsBeforeSending() throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        let originalKey = RadarSettings.publishableKey
        defer {
            client.apiHelper = originalHelper
            RadarSettings.publishableKey = originalKey
        }
        RadarSettings.publishableKey = nil

        let helper = MainQueueAPIHelperMock()
        client.apiHelper = helper

        let finished = expectation(description: "Missing authorization")
        finished.assertForOverFulfill = true

        RadarTrackTestBridge.track(
            withPreparedPayload: nil,
            verified: true,
            secondary: false
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
            withPreparedPayload: nil,
            verified: false,
            secondary: true
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

    func test_track_verified_preparesRequestOnBothHosts() throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        defer { client.apiHelper = originalHelper }

        for (secondary, hasCompatibilityMarker) in [(false, true), (true, true), (false, false), (true, false)] {
            let helper = MainQueueAPIHelperMock()
            helper.mockStatus = .errorServer
            helper.mockResponse = ["meta": ["config": [:]]]
            client.apiHelper = helper
            let instance = MockCollectingFraudInstance(
                result: ["preparedPayload": MockPreparedFraudPayloadInstance(result: ["payload": MockFraudEnvelope.payload])],
                missingSelectors: hasCompatibilityMarker ? [] : ["coreCompatibilityVersion"]
            )
            let preparer = try makeTrackPreparer(instance: instance, options: ["nonce": "test-nonce"])
            let finished = expectation(description: "Verified track completes")
            finished.assertForOverFulfill = true
            let track = trackForEncryptionTest(preparer, secondary: secondary) { _, _, _, _, _, _, _ in
                finished.fulfill()
            }
            wait(for: [finished], timeout: 5)
            track.cancel()

            let host = secondary ? RadarSettings.defaultVerifiedHostSecondary : RadarSettings.verifiedHost
            XCTAssertEqual(helper.lastUrl, "\(host)/v1/track")
            XCTAssertEqual(helper.lastMethod, "POST")
            let sentBody = try XCTUnwrap(helper.lastParams as? [String: Any])
            XCTAssertEqual(Set(sentBody.keys), MockFraudEnvelope.fieldNames)
            XCTAssertEqual(sentBody["ct"] as? String, "mock-ct")
            XCTAssertEqual(instance.recordedOptions().count, 1)
            let prepared = try XCTUnwrap(instance.result?["preparedPayload"] as? MockPreparedFraudPayloadInstance)
            let context = try XCTUnwrap(prepared.capturedOptions.first)
            XCTAssertEqual(context["method"] as? String, "POST")
            XCTAssertEqual(context["canonicalRoute"] as? String, "/v1/track")
            XCTAssertEqual(instance.recordedOptions().first?["nonce"] as? String, "test-nonce")
            let coreBody = try XCTUnwrap(
                JSONSerialization.jsonObject(with: try XCTUnwrap(context["body"] as? Data)) as? [String: Any]
            )
            XCTAssertEqual(coreBody["latitude"] as? Double, 40.0)
            XCTAssertEqual(coreBody["longitude"] as? Double, -73.0)
            XCTAssertNotNil(coreBody["installId"] as? String)
            XCTAssertNil(coreBody["fraudPayload"])
            XCTAssertNil(context["installId"])
            for (field, header) in [
                ("authorization", "Authorization"), ("product", "X-Radar-Product"),
                ("sdkVersion", "X-Radar-SDK-Version"), ("origin", "X-Radar-Mobile-Origin"),
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
            (MockCollectingFraudInstance(result: nil, missingSelectors: ["coreCompatibilityVersion"]), .errorBadRequest),
            (MockCollectingFraudInstance(result: nil, compatibilityVersion: NSNumber(value: 0)), .errorPlugin),
            (MockCollectingFraudInstance(result: nil, compatibilityVersion: NSNumber(value: 2)), .errorPlugin),
            (MockCollectingFraudInstance(result: nil), .errorBadRequest),
            (MockCollectingFraudInstance(result: ["payload": ""]), .errorBadRequest),
            (MockCollectingFraudInstance(result: ["error": "failed", "payload": "must-not-send"]), .errorBadRequest),
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
            let track = trackForEncryptionTest(preparer) { status, _, _, _, _, _, _ in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(status, expectedStatus)
                finished.fulfill()
            }
            wait(for: [finished], timeout: 5)
            track.cancel()
            XCTAssertNil(helper.lastMethod)
        }
    }
}
