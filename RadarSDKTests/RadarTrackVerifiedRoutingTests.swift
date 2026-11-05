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

        let helper = makeMainQueueHelper()
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

        wait(for: [finished], timeout: Self.callbackTimeout)
        XCTAssertNil(helper.lastMethod)
    }

    func test_track_nonVerified_usesStandardHostWithoutFraudPayload() {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        defer { client.apiHelper = originalHelper }

        let helper = makeMainQueueHelper()
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

        wait(for: [finished], timeout: Self.callbackTimeout)

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
            let helper = makeMainQueueHelper()
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
            wait(for: [finished], timeout: Self.callbackTimeout)
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

    // Preparation runs before the API client is involved: the verification manager and
    // `trackForEncryptionTest` call the track API only when it succeeds. So these await the
    // preparer directly, with no API helper, main-actor hop, or wait timeout to go wrong.

    func test_preparePayload_noFraudSDK_failsWithPluginError() async {
        await assertPreparationFails(instance: nil, expectedStatus: .errorPlugin)
    }

    func test_preparePayload_legacyFraudSDK_failsWithPluginError() async {
        await assertPreparationFails(instance: MockLegacyFraudInstance(), expectedStatus: .errorPlugin)
    }

    func test_preparePayload_missingCompatibilityVersion_failsWithBadRequest() async {
        await assertPreparationFails(
            instance: MockCollectingFraudInstance(result: nil, missingSelectors: ["coreCompatibilityVersion"]),
            expectedStatus: .errorBadRequest
        )
    }

    func test_preparePayload_compatibilityVersionZero_failsWithPluginError() async {
        await assertPreparationFails(
            instance: MockCollectingFraudInstance(result: nil, compatibilityVersion: NSNumber(value: 0)),
            expectedStatus: .errorPlugin
        )
    }

    func test_preparePayload_compatibilityVersionTwo_failsWithPluginError() async {
        await assertPreparationFails(
            instance: MockCollectingFraudInstance(result: nil, compatibilityVersion: NSNumber(value: 2)),
            expectedStatus: .errorPlugin
        )
    }

    func test_preparePayload_nilResult_failsWithBadRequest() async {
        await assertPreparationFails(instance: MockCollectingFraudInstance(result: nil), expectedStatus: .errorBadRequest)
    }

    func test_preparePayload_emptyPayload_failsWithBadRequest() async {
        await assertPreparationFails(
            instance: MockCollectingFraudInstance(result: ["payload": ""]),
            expectedStatus: .errorBadRequest
        )
    }

    func test_preparePayload_errorWithPayload_failsWithBadRequest() async {
        await assertPreparationFails(
            instance: MockCollectingFraudInstance(result: ["error": "failed", "payload": "must-not-send"]),
            expectedStatus: .errorBadRequest
        )
    }

    private func assertPreparationFails(
        instance: NSObject?,
        expectedStatus: RadarStatus,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        // A fraud SDK that can't prepare payloads at all is rejected when it's wrapped.
        let fraudSDK = instance.flatMap { RadarSDKFraud(instance: $0) }
        if expectedStatus == .errorPlugin {
            XCTAssertNil(fraudSDK, file: file, line: line)
        } else {
            XCTAssertNotNil(fraudSDK, file: file, line: line)
        }
        let preparer = RadarTrackVerifiedRequestPreparer(fraudSDK: fraudSDK, options: [:])

        let (status, payload, _) = await preparer.preparePayload()

        XCTAssertEqual(status, expectedStatus, file: file, line: line)
        XCTAssertNil(payload, file: file, line: line)
    }
}
