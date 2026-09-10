import CoreLocation
import XCTest

@testable import RadarSDK

final class PreparationRejectingAPIHelperMock: RadarAPIHelperMock {
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

final class PreparationCapturingAPIHelperMock: RadarAPIHelperMock {
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

final class RetryFailureRequestCounter: @unchecked Sendable {
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

final class RetryPreparationFailureProtocol: URLProtocol {
    static let requests = RetryFailureRequestCounter()

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(
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

struct VerifiedTrackRetryFixture {
    let session: URLSession
    let helper = RadarAPIHelper()
    let instance: MockEncryptedFraudInstance
    let preparer: RadarTrackVerifiedRequestPreparer

    init(protocolClass: AnyClass, options: [String: Any] = [:]) throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [protocolClass]
        session = URLSession(configuration: configuration)
        helper.setValue(session, forKey: "standardSession")
        instance = MockEncryptedFraudInstance(result: ["payload": "encrypted-envelope"])
        let fraudSDK = try XCTUnwrap(RadarSDKFraud(instance: instance))
        preparer = RadarTrackVerifiedRequestPreparer(fraudSDK: fraudSDK, options: options)
    }

    func prepareWithAttemptHeader(
        _ request: URLRequest,
        completion: @escaping @Sendable (RadarStatus, URLRequest?, Error?) -> Void
    ) {
        let instance = self.instance
        // The retry must start from the original request.
        XCTAssertNil(
            request.value(forHTTPHeaderField: "X-Test-Attempt")
        )

        self.preparer.prepareRequest(request) { status, prepared, error in
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

    }

    func assertRetryContexts(startedAt: Int) throws {
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
}
