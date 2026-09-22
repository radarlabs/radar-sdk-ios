//
//  RadarTrackVerifiedManagerTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 9/17/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import XCTest

@testable import RadarSDK

private final class TrackVerifiedLocationManagerMock: RadarLocationManager {
    override func getLocationWith(
        _ desiredAccuracy: RadarTrackingOptionsDesiredAccuracy,
        completionHandler: RadarLocationCompletionHandler?
    ) {
        completionHandler?(
            .success,
            CLLocation(latitude: 40.0, longitude: -73.0),
            false
        )
    }
}

extension RadarVerifiedHostOverrideTests {
    func test_trackVerifiedManager_collectionFailureReportsErrorWithoutSendingTrack() throws {
        try assertManagerRejectsPayload(result: ["error": "encryption failed"])
    }

    func test_trackVerifiedManager_missingOrEmptyPayloadDoesNotSendTrack() throws {
        let results: [[String: Any]?] = [nil, [:], ["payload": ""], ["error": "failed", "payload": "must-not-send"]]
        for result in results {
            try assertManagerRejectsPayload(result: result)
        }
    }

    func test_trackVerifiedManager_anonymousRequestDoesNotSendTrack() throws {
        try assertManagerRejectsPayload(result: ["preparedPayload": MockPreparedFraudPayloadInstance(result: ["payload": "encrypted-envelope"])], anonymous: true)
    }

    private func assertManagerRejectsPayload(result: [String: Any]?, anonymous: Bool = false) throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        let originalAnonymous = RadarSettings.anonymousTrackingEnabled
        let originalReplayCount = RadarReplayBuffer.sharedInstance.mutableReplayBuffer.count
        defer {
            client.apiHelper = originalHelper
            RadarSettings.anonymousTrackingEnabled = originalAnonymous
        }
        RadarSettings.anonymousTrackingEnabled = anonymous

        let helper = MainQueueAPIHelperMock()
        helper.mockStatus = .success
        helper.mockResponse = [
            "meta": ["config": [:]],
            "nonce": "manager-test-nonce",
        ]
        client.apiHelper = helper

        let instance = MockEncryptedFraudInstance(result: result)
        let manager = try makeVerificationManager(instance: instance)

        let delegateHolder = RadarDelegateHolder.sharedInstance()
        let originalDelegate = delegateHolder.delegate
        let delegate = VerifiedFailureDelegate()
        delegateHolder.delegate = delegate
        defer { delegateHolder.delegate = originalDelegate }

        runVerificationManager(manager, expectedStatus: .errorUnknown)

        let options = instance.recordedOptions()
        XCTAssertEqual(options.count, 1)
        XCTAssertEqual(options.first?["nonce"] as? String, "manager-test-nonce")
        XCTAssertNil(options.first?["canonicalRoute"])

        XCTAssertEqual(delegate.recordedStatuses, [.errorUnknown])
        XCTAssertEqual(helper.lastMethod, "GET")
        XCTAssertTrue(helper.lastUrl?.contains("/v1/config?") == true)
        XCTAssertEqual(RadarReplayBuffer.sharedInstance.mutableReplayBuffer.count, originalReplayCount)
    }

    func test_trackVerifiedManager_collectionSuccessForwardsPayloadAndContext() throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        let originalAnonymous = RadarSettings.anonymousTrackingEnabled
        let originalProduct = RadarSettings.product
        let buffer = RadarReplayBuffer.sharedInstance
        let originalReplays = buffer.mutableReplayBuffer
        defer {
            client.apiHelper = originalHelper
            RadarSettings.anonymousTrackingEnabled = originalAnonymous
            RadarSettings.product = originalProduct
            buffer.mutableReplayBuffer = originalReplays
        }
        RadarSettings.anonymousTrackingEnabled = false
        RadarSettings.product = "manager-test-product"
        buffer.mutableReplayBuffer = []

        let helper = MainQueueAPIHelperMock()
        helper.mockStatus = .success
        helper.mockResponse = [
            "meta": ["config": [:]],
            "nonce": "manager-test-nonce",
        ]
        let trackURL = "\(RadarSettings.verifiedHost)/v1/track"
        helper.setMockStatus(.errorServer, forMethod: trackURL)
        client.apiHelper = helper

        let instance = makeCollectedFraudInstance(result: ["payload": "encrypted-envelope"])
        let manager = try makeVerificationManager(instance: instance)
        // Collection succeeds; the mocked track endpoint returns an error.
        runVerificationManager(manager, expectedStatus: .errorServer)

        XCTAssertEqual(helper.lastMethod, "POST")
        XCTAssertEqual(helper.lastUrl, trackURL)
        XCTAssertEqual(
            helper.lastParams?["fraudPayload"] as? String,
            "encrypted-envelope"
        )
        XCTAssertEqual(helper.lastParams?["latitude"] as? Double, 40.0)
        XCTAssertEqual(helper.lastParams?["longitude"] as? Double, -73.0)

        try assertMatchingEncryptionContext(instance: instance, helper: helper)
    }

    private func makeVerificationManager(instance: MockEncryptedFraudInstance) throws -> ObjCVerificationManager {
        let fraudSDK = try XCTUnwrap(RadarSDKFraud(instance: instance))
        let manager = try XCTUnwrap(ObjCVerificationManager.makeFresh())
        manager.instance.setValue(
            TrackVerifiedLocationManagerMock(),
            forKey: "trackVerifiedLocationManager"
        )

        let factory: @convention(block) ([String: Any]) -> NSObject = { options in
            RadarTrackVerifiedRequestPreparer(fraudSDK: fraudSDK, options: options)
        }
        manager.instance.setValue(factory as AnyObject, forKey: "trackVerifiedPayloadFactory")
        return manager
    }

    private func runVerificationManager(_ manager: ObjCVerificationManager, expectedStatus: RadarStatus) {
        let finished = expectation(description: "Verification manager completes")
        finished.assertForOverFulfill = true
        let completion: @convention(block) (RadarStatus, RadarVerifiedLocationToken?) -> Void = { status, token in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(status, expectedStatus)
            XCTAssertNil(token)
            finished.fulfill()
        }
        manager.instance.perform(
            NSSelectorFromString("trackVerifiedWithCompletionHandler:"),
            with: completion as AnyObject
        )
        wait(for: [finished], timeout: 5)
    }

    private func assertMatchingEncryptionContext(
        instance: MockEncryptedFraudInstance,
        helper: MainQueueAPIHelperMock
    ) throws {
        let recordedOptions = instance.recordedOptions()
        XCTAssertEqual(recordedOptions.count, 1)
        let prepared = try XCTUnwrap(instance.result?["preparedPayload"] as? MockPreparedFraudPayloadInstance)
        let context = try XCTUnwrap(prepared.capturedOptions.first)
        XCTAssertEqual(context["method"] as? String, "POST")
        XCTAssertEqual(context["canonicalRoute"] as? String, "/v1/track")
        XCTAssertEqual(recordedOptions.first?["nonce"] as? String, "manager-test-nonce")
        XCTAssertEqual(context["product"] as? String, "manager-test-product")
        XCTAssertEqual(context["origin"] as? String, Bundle.main.bundleIdentifier)

        let sentInstallId = try XCTUnwrap(
            helper.lastParams?["installId"] as? String
        )
        XCTAssertEqual(context["installId"] as? String, sentInstallId)

        let headers = try XCTUnwrap(helper.lastHeaders)
        XCTAssertNotNil(headers["Authorization"])
        XCTAssertNotNil(headers["X-Radar-SDK-Version"])
        XCTAssertNil(headers["Origin"])
        XCTAssertEqual(headers["X-Radar-Mobile-Origin"] as? String, Bundle.main.bundleIdentifier)

        for (field, header) in [
            ("authorization", "Authorization"),
            ("product", "X-Radar-Product"),
            ("sdkVersion", "X-Radar-SDK-Version"),
            ("origin", "X-Radar-Mobile-Origin"),
        ] {
            XCTAssertEqual(context[field] as? String, headers[header] as? String)
        }
    }
}
