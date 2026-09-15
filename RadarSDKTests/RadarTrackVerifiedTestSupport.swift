import CoreLocation
import XCTest

@testable import RadarSDK

// Transfers one immutable test callback to main; it is invoked only once there.
private final class TrackTestCallback: @unchecked Sendable {
    let invoke: () -> Void
    init(_ invoke: @escaping () -> Void) { self.invoke = invoke }
}

final class PreparationRejectingAPIHelperMock: RadarAPIHelperMock {
    override func request(
        withMethod method: String,
        url: String,
        headers: [AnyHashable: Any]?,
        params: [AnyHashable: Any]?,
        sleep: Bool,
        logPayload: Bool,
        extendedTimeout: Bool,
        completionHandler: RadarAPICompletionHandler?
    ) {
        // Match the real helper's main-thread callback contract after async encryption.
        super.request(
            withMethod: method, url: url, headers: headers, params: params,
            sleep: sleep, logPayload: logPayload, extendedTimeout: extendedTimeout
        ) { status, response, error in
            let callback = TrackTestCallback { completionHandler?(status, response, error) }
            DispatchQueue.main.async { callback.invoke() }
        }
    }
}
extension RadarVerifiedHostOverrideTests {
    func makeTrackPreparer(
        instance: NSObject?,
        options: [String: Any] = [:]
    ) throws -> RadarTrackVerifiedRequestPreparer {
        let fraudSDK: RadarSDKFraud?
        if let instance {
            fraudSDK = try XCTUnwrap(RadarSDKFraud(instance: instance))
        } else {
            fraudSDK = nil
        }
        return RadarTrackVerifiedRequestPreparer(fraudSDK: fraudSDK, options: options)
    }

    func trackForEncryptionTest(
        _ preparer: RadarTrackVerifiedRequestPreparer,
        verified: Bool = true,
        secondary: Bool = false,
        completion: @escaping RadarTrackAPICompletionHandler
    ) {
        RadarTrackTestBridge.track(
            withPreparer: preparer,
            verified: verified,
            secondary: secondary,
            completion: completion
        )
    }
}

final class TrackRetryTransportState: @unchecked Sendable {
    private let lock = NSLock()
    private var failures: [URLError.Code] = []
    private var requests: [URLRequest] = []

    func reset(failures: [URLError.Code]) {
        lock.lock()
        defer { lock.unlock() }
        self.failures = failures
        requests = []
    }

    func record(_ request: URLRequest) -> URLError.Code? {
        lock.lock()
        defer { lock.unlock() }
        let attempt = requests.count
        requests.append(request)
        return attempt < failures.count ? failures[attempt] : nil
    }

    func recordedRequests() -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return requests
    }
}

final class TrackRetryProtocol: URLProtocol {
    static let state = TrackRetryTransportState()

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        var captured = request
        if captured.httpBody == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while true {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 {
                    if count < 0 { XCTFail("Unable to read test request body") }
                    break
                }
                data.append(contentsOf: buffer.prefix(count))
            }
            captured.httpBody = data
        }
        if let code = Self.state.record(captured) {
            client?.urlProtocol(self, didFailWithError: URLError(code))
            return
        }
        // A real server response ends transport retries. Use an error response to avoid
        // unrelated success-path state updates and log flushing in this transport test.
        guard let url = request.url,
            let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)
        else {
            XCTFail("Invalid intercepted request URL")
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("{}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class VerifiedFailureDelegate: NSObject, RadarDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var failures: [RadarStatus] = []

    func didFail(status: RadarStatus) {
        lock.lock()
        defer { lock.unlock() }
        failures.append(status)
    }

    var recordedStatuses: [RadarStatus] {
        lock.lock()
        defer { lock.unlock() }
        return failures
    }
}
