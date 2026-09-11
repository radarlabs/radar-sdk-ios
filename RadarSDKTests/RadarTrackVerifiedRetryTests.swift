import CoreLocation
import XCTest

@testable import RadarSDK

extension RadarVerifiedHostOverrideTests {
    func test_verifiedPreparation_refreshesAttemptOnNetworkRetry() throws {
        // Reuse the Objective-C URLProtocol from the preparation tests.
        let protocolClass: AnyClass = try XCTUnwrap(
            NSClassFromString("RadarPreparationTestProtocol")
        )

        let fixture = try VerifiedTrackRetryFixture(protocolClass: protocolClass, options: ["nonce": "test-nonce"])
        defer { fixture.session.invalidateAndCancel() }

        let finished = expectation(description: "Verified preparation retries")
        finished.assertForOverFulfill = true
        let startedAt = Int(Date().timeIntervalSince1970)

        fixture.helper.request(
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
            prepareRequest: fixture.prepareWithAttemptHeader,
            completionHandler: { status, response, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertEqual(status, .success)
                XCTAssertNil(error)
                XCTAssertEqual(response?["ok"] as? Bool, true)
                finished.fulfill()
            }
        )

        wait(for: [finished], timeout: 5.0)

        try fixture.assertRetryContexts(startedAt: startedAt)

    }

    func test_verifiedRetryPreparationFailure_doesNotSendAgain() throws {
        RetryPreparationFailureProtocol.requests.reset()

        let fixture = try VerifiedTrackRetryFixture(protocolClass: RetryPreparationFailureProtocol.self)
        defer { fixture.session.invalidateAndCancel() }
        let instance = fixture.instance
        let preparer = fixture.preparer

        let preparationCalls = expectation(description: "Two preparations")
        preparationCalls.expectedFulfillmentCount = 2
        preparationCalls.assertForOverFulfill = true
        let finished = expectation(description: "One final failure callback")
        finished.assertForOverFulfill = true
        let expectedError = NSError(domain: "RadarPreparationTest", code: 1)

        fixture.helper.request(
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

    func test_preparationFailure_usesDedicatedCallbackAndReleasesSemaphore() {
        RetryPreparationFailureProtocol.requests.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RetryPreparationFailureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let helper = RadarAPIHelper()
        helper.setValue(session, forKey: "standardSession")

        let first = expectation(description: "First preparation failure")
        let second = expectation(description: "Second preparation failure")
        first.assertForOverFulfill = true
        second.assertForOverFulfill = true

        let expectedError = NSError(
            domain: "RadarPreparationTest",
            code: 42
        )

        for finished in [first, second] {
            helper.request(
                withMethod: "POST",
                url: "https://api-verified.radar.io/v1/track",
                headers: ["Content-Type": "application/json"],
                params: ["installId": "test-install"],
                sleep: true,
                logPayload: false,
                extendedTimeout: false,
                prepareRequest: { _, completion in
                    DispatchQueue.global().async {
                        completion(.errorUnknown, nil, expectedError)
                    }
                },
                preparationFailureHandler: { status, error in
                    XCTAssertTrue(Thread.isMainThread)
                    XCTAssertEqual(status, .errorUnknown)

                    let actualError = error as NSError?
                    XCTAssertEqual(actualError?.domain, expectedError.domain)
                    XCTAssertEqual(actualError?.code, expectedError.code)

                    finished.fulfill()
                },
                completionHandler: { _, _, _ in
                    XCTFail(
                        "Preparation failure must not invoke the normal completion handler"
                    )
                }
            )
        }

        wait(for: [first, second], timeout: 5.0)
        XCTAssertEqual(RetryPreparationFailureProtocol.requests.value, 0)
    }
}
