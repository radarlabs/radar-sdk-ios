import CoreLocation
import XCTest

@testable import RadarSDK

extension RadarVerifiedHostOverrideTests {
    func test_trackVerified_lostConnection_resealsOnBothHosts() throws {
        for secondary in [false, true] {
            try assertTrackTransport(
                failures: [.networkConnectionLost],
                expectedStatus: .errorServer,
                expectedRequests: 2,
                secondary: secondary
            )
        }
    }

    func test_trackVerified_secondLostConnection_stopsRetrying() throws {
        try assertTrackTransport(
            failures: [.networkConnectionLost, .networkConnectionLost],
            expectedStatus: .errorNetwork,
            expectedRequests: 2
        )
    }

    func test_trackVerified_otherNetworkErrors_doNotRetry() throws {
        for code in [URLError.Code.timedOut, .cannotFindHost, .secureConnectionFailed, .cancelled] {
            try assertTrackTransport(
                failures: [code],
                expectedStatus: .errorNetwork,
                expectedRequests: 1
            )
        }
    }

    func test_trackVerified_sealingFailure_neverDispatchesOrBuffersOnBothHosts() throws {
        for secondary in [false, true] {
            for failingSeal in [1, 2] {
                try assertTrackTransport(
                    failures: [.networkConnectionLost],
                    expectedStatus: .errorUnknown,
                    expectedRequests: failingSeal - 1,
                    secondary: secondary,
                    failingSeal: failingSeal
                )
            }
        }
    }

    // Keep the request, retry, and semaphore-release assertions in one transport scenario.
    // swiftlint:disable:next function_body_length
    private func assertTrackTransport(
        failures: [URLError.Code],
        expectedStatus: RadarStatus,
        expectedRequests: Int,
        secondary: Bool = false,
        failingSeal: Int? = nil
    ) throws {
        try withIsolatedReplayState {
            let client = RadarAPIClient.sharedInstance()
            let originalHelper = client.apiHelper
            TrackRetryProtocol.state.reset(failures: failures)
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [TrackRetryProtocol.self]
            let session = URLSession(configuration: configuration)
            let helper = RadarAPIHelper()
            helper.setValue(session, forKey: "standardSession")
            client.apiHelper = helper
            defer {
                client.apiHelper = originalHelper
                session.invalidateAndCancel()
                TrackRetryProtocol.state.reset(failures: [])
            }

            var sealCalls = 0
            let prepared = MockPreparedFraudPayloadInstance(result: nil) { options in
                sealCalls += 1
                if sealCalls == failingSeal { return ["error": "Seal failed"] }
                guard let attemptId = options["encryptionAttemptId"] as? String else {
                    return ["error": "Missing attempt ID"]
                }
                return ["payload": "encrypted-\(attemptId)"]
            }
            let instance = MockCollectingFraudInstance(result: ["preparedPayload": prepared])
            let preparer = try makeTrackPreparer(instance: instance, options: ["nonce": "test-nonce"])
            let finished = expectation(description: "One final track callback")
            finished.assertForOverFulfill = true
            trackForEncryptionTest(preparer, secondary: secondary) { status, _, _, _, _, _, _ in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(status, expectedStatus)
                finished.fulfill()
            }
            wait(for: [finished], timeout: 5)

            let requests = TrackRetryProtocol.state.recordedRequests()
            XCTAssertEqual(requests.count, expectedRequests)
            XCTAssertEqual(instance.recordedOptions().count, 1)
            XCTAssertEqual(instance.recordedOptions().first?["nonce"] as? String, "test-nonce")
            XCTAssertEqual(prepared.capturedOptions.count, failingSeal ?? expectedRequests)
            let contexts = prepared.capturedOptions
            let ids = contexts.compactMap { $0["encryptionAttemptId"] as? String }
            XCTAssertEqual(Set(ids).count, contexts.count)
            try assertEncryptedRequests(requests, contexts: contexts, secondary: secondary)
            let replays = RadarReplayBuffer.sharedInstance.flushableReplays
            XCTAssertEqual(replays.count, failingSeal == nil ? 1 : 0)
            XCTAssertNil(replays.first?.replayParams["fraudPayload"])
            if failingSeal != nil {
                XCTAssertNil(RadarSyncManager.syncStore.read()?.geofenceEntryTimestamps["verified-replay-offline-test"])
                // A failed preparation must release the helper's semaphore for subsequent requests.
                TrackRetryProtocol.state.reset(failures: [])
                let next = expectation(description: "Next track is not blocked")
                next.assertForOverFulfill = true
                trackForEncryptionTest(preparer, secondary: secondary) { status, _, _, _, _, _, _ in
                    XCTAssertEqual(status, .errorServer)
                    next.fulfill()
                }
                wait(for: [next], timeout: 5)
                XCTAssertEqual(TrackRetryProtocol.state.recordedRequests().count, 1)
            }
        }
    }

    private func assertEncryptedRequests(
        _ requests: [URLRequest],
        contexts: [[String: Any]],
        secondary: Bool
    ) throws {
        guard let first = requests.first else { return }
        let host = secondary ? RadarSettings.defaultVerifiedHostSecondary : RadarSettings.verifiedHost

        for (index, request) in requests.enumerated() {
            let context = contexts[index]
            XCTAssertEqual(request.url?.absoluteString, "\(host)/v1/track")
            XCTAssertEqual(request.httpMethod, "POST")
            if index > 0 { XCTAssertNotEqual(request.httpBody, first.httpBody) }
            XCTAssertEqual(request.allHTTPHeaderFields, first.allHTTPHeaderFields)
            let body = try XCTUnwrap(
                JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: Any]
            )
            let attemptId = try XCTUnwrap(context["encryptionAttemptId"] as? String)
            XCTAssertEqual(body["fraudPayload"] as? String, "encrypted-\(attemptId)")
            XCTAssertEqual(context["method"] as? String, "POST")
            XCTAssertEqual(context["canonicalRoute"] as? String, "/v1/track")
            XCTAssertNotNil(context["issuedAt"] as? Int)
            XCTAssertEqual(context["installId"] as? String, body["installId"] as? String)
            for (field, header) in [
                ("authorization", "Authorization"), ("product", "X-Radar-Product"),
                ("sdkVersion", "X-Radar-SDK-Version"), ("origin", "X-Radar-Mobile-Origin"),
            ] {
                XCTAssertEqual(context[field] as? String, request.value(forHTTPHeaderField: header))
            }
        }
    }
}
