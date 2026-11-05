import CoreLocation
import XCTest

@testable import RadarSDK

// Transfers one immutable test callback to main; it is invoked only once there.
private final class TrackTestCallback: @unchecked Sendable {
    let invoke: () -> Void
    init(_ invoke: @escaping () -> Void) { self.invoke = invoke }
}

private final class TrackResultCallback: @unchecked Sendable {
    let invoke: RadarTrackAPICompletionHandler
    init(_ invoke: @escaping RadarTrackAPICompletionHandler) { self.invoke = invoke }
}

// Whether a `MainQueueAPIHelperMock` still delivers callbacks. Callbacks capture this rather
// than the mock, which isn't `Sendable`.
private final class CallbackGate: @unchecked Sendable {
    private let lock = NSLock()
    private var open = true

    func close() {
        lock.lock()
        defer { lock.unlock() }
        open = false
    }

    var isOpen: Bool {
        lock.lock()
        defer { lock.unlock() }
        return open
    }
}

final class MainQueueAPIHelperMock: RadarAPIHelperMock {
    private let gate = CallbackGate()

    /// Drops every callback not yet delivered, and any later ones. Tests call this when they
    /// end, so a response still in flight can't fulfill or fail a later test's expectations.
    func invalidate() {
        gate.close()
    }

    private func deliverOnMain(_ callback: TrackTestCallback) {
        let gate = gate
        DispatchQueue.main.async {
            guard gate.isOpen else { return }
            callback.invoke()
        }
    }

    override func request(
        withMethod method: String,
        url: String,
        headers: [AnyHashable: Any]?,
        params: [AnyHashable: Any]?,
        sleep: Bool,
        logPayload: Bool,
        extendedTimeout: Bool,
        prepareRequest: RadarAPIRequestPreparation?,
        preparationFailureHandler: ((Error) -> Void)?,
        completionHandler: RadarAPICompletionHandler?
    ) {
        do {
            var request = URLRequest(url: try XCTUnwrap(URL(string: url)))
            request.httpMethod = method
            request.allHTTPHeaderFields = headers as? [String: String]
            if let params {
                request.httpBody = try JSONSerialization.data(withJSONObject: params)
            }
            var preparedParams = params
            if let prepareRequest {
                var error: NSError?
                let prepared = prepareRequest(request, &error)
                if let error { throw error }
                let preparedRequest = try XCTUnwrap(prepared)
                let body = try XCTUnwrap(preparedRequest.httpBody)
                preparedParams = try JSONSerialization.jsonObject(with: body) as? [AnyHashable: Any]
            }
            self.request(
                withMethod: method, url: url, headers: headers, params: preparedParams,
                sleep: sleep, logPayload: logPayload, extendedTimeout: extendedTimeout,
                completionHandler: completionHandler
            )
        } catch {
            deliverOnMain(TrackTestCallback { preparationFailureHandler?(error) })
        }
    }

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
            self.deliverOnMain(TrackTestCallback { completionHandler?(status, response, error) })
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

    // Callers cancel the returned task once their wait ends, and `tearDown` cancels any the test
    // didn't. A wait that times out leaves the task running, and it would otherwise send its
    // track through whichever API helper a later test has installed on the shared client.
    @discardableResult
    func trackForEncryptionTest(
        _ preparer: RadarTrackVerifiedRequestPreparer,
        secondary: Bool = false,
        completion: @escaping RadarTrackAPICompletionHandler
    ) -> Task<Void, Never> {
        // Collect before the API call, as the verification manager now does.
        // This helper exercises the collector/API boundary, not location acquisition.
        let callback = TrackResultCallback(completion)
        let task = Task { @MainActor in
            guard RadarSettings.publishableKey != nil else {
                callback.invoke(.errorPublishableKey, nil, nil, nil, nil, nil, nil)
                return
            }
            let (status, payload, error) = await preparer.preparePayload()
            // Cancellation and this check both run on the main actor, so a cancelled task
            // never reaches the shared API client.
            guard !Task.isCancelled else { return }
            guard status == .success, let payload, error == nil else {
                callback.invoke(status == .success ? .errorUnknown : status, nil, nil, nil, nil, nil, nil)
                return
            }

            RadarTrackTestBridge.track(
                withPreparedPayload: payload, verified: true, secondary: secondary,
                completion: callback.invoke
            )
        }
        pendingTrackTasks.append(task)
        return task
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
        // Only track requests count. Anything else the SDK sends through this session (such as
        // a config request from an earlier `Radar.initialize`) gets a server error and isn't
        // recorded, so it can't consume a scripted failure or change the request count.
        guard captured.url?.path.hasSuffix("/v1/track") == true else {
            respondWithServerError()
            return
        }
        if let code = Self.state.record(captured) {
            client?.urlProtocol(self, didFailWithError: URLError(code))
            return
        }
        // A real server response ends transport retries. Use an error response to avoid
        // unrelated success-path state updates and log flushing in this transport test.
        respondWithServerError()
    }

    private func respondWithServerError() {
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

func makeCollectedFraudInstance(result: [String: Any]?) -> MockCollectingFraudInstance {
    MockCollectingFraudInstance(result: [
        "preparedPayload": MockPreparedFraudPayloadInstance(result: result)
    ])
}
