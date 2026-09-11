import CoreLocation
import XCTest

@testable import RadarSDK

extension RadarVerifiedHostOverrideTests {
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
            },
            completionHandler: { _, _, _, _, _, _, _ in
                finished.fulfill()
            }
        )

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
                },
                completionHandler: { _, _, _, _, _, _, _ in
                    finished.fulfill()
                }
            )

            wait(for: [finished], timeout: 5.0)

            try assertForwardedPreparation(helper, useSecondaryHost: useSecondaryHost, hookCalled: hookCalled)
        }
    }

    private func assertForwardedPreparation(
        _ helper: PreparationCapturingAPIHelperMock,
        useSecondaryHost: Bool,
        hookCalled: XCTestExpectation
    ) throws {
        let expectedHost =
            useSecondaryHost
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
