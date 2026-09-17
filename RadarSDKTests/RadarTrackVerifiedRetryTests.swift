import CoreLocation
import XCTest

@testable import RadarSDK

extension RadarVerifiedHostOverrideTests {
    func test_trackVerified_lostConnection_reusesEncryptedBodyOnBothHosts() throws {
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

    private func assertTrackTransport(
        failures: [URLError.Code],
        expectedStatus: RadarStatus,
        expectedRequests: Int,
        secondary: Bool = false
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

            let instance = MockEncryptedFraudInstance(result: ["payload": "encrypted-envelope"])
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
            let context = try XCTUnwrap(instance.recordedOptions().first)
            try assertEncryptedRequests(requests, context: context, secondary: secondary)
            let replays = RadarReplayBuffer.sharedInstance.flushableReplays
            XCTAssertEqual(replays.count, 1)
            XCTAssertNil(replays.first?.replayParams["fraudPayload"])
        }
    }

    private func assertEncryptedRequests(
        _ requests: [URLRequest],
        context: [String: Any],
        secondary: Bool
    ) throws {
        let first = try XCTUnwrap(requests.first)
        let firstBody = try XCTUnwrap(first.httpBody)
        let host = secondary ? RadarSettings.defaultVerifiedHostSecondary : RadarSettings.verifiedHost

        for request in requests {
            XCTAssertEqual(request.url?.absoluteString, "\(host)/v1/track")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.httpBody, firstBody)
            XCTAssertEqual(request.allHTTPHeaderFields, first.allHTTPHeaderFields)
            let body = try XCTUnwrap(
                JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: Any]
            )
            XCTAssertEqual(body["fraudPayload"] as? String, "encrypted-envelope")
            XCTAssertEqual(context["installId"] as? String, body["installId"] as? String)
            for (field, header) in [
                ("authorization", "Authorization"), ("product", "X-Radar-Product"),
                ("sdkVersion", "X-Radar-SDK-Version"), ("origin", "Origin"),
            ] {
                XCTAssertEqual(context[field] as? String, request.value(forHTTPHeaderField: header))
            }
        }
        XCTAssertEqual(context["method"] as? String, "POST")
        XCTAssertEqual(context["canonicalRoute"] as? String, "/v1/track")
        XCTAssertEqual(context["nonce"] as? String, "test-nonce")
        XCTAssertFalse(try XCTUnwrap(context["encryptionAttemptId"] as? String).isEmpty)
    }
}
