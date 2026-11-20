//
//  RadarAPIHelperTraceTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
// Not `@testable`, for the same reason as RadarAPIHelperMock: this tests the Objective-C `RadarAPIHelper`.
import RadarSDK
import XCTest

/// Records what `RadarAPIHelper` does with a request's trace.
private final class FakeRequestTrace: NSObject, RadarAPIRequestTrace, @unchecked Sendable {
    let traceparent: String?
    private let lock = NSLock()
    private var recorded: [String] = []
    private(set) var startedURL: String?
    private(set) var startedHeaders: [AnyHashable: Any]?
    private(set) var networkError: NSError?

    init(traceparent: String?) {
        self.traceparent = traceparent
    }

    var events: [String] {
        lock.withLock { recorded }
    }

    func record(_ event: String) {
        lock.withLock { recorded.append(event) }
    }

    func requestStarted(withURL url: String, headers: [AnyHashable: Any]?, queueNanos: UInt64) {
        startedURL = url
        startedHeaders = headers
        record("started")
    }

    func setResendCount(_ count: Int) {
        record("resend \(count)")
    }

    func end(withNetworkError error: Error) {
        networkError = error as NSError
        record("network error")
    }

    func end(with status: RadarStatus) {
        record("end \(Radar.stringForStatus(status))")
    }
}

/// Answers requests with replies queued per URL path, so concurrent tests don't share replies.
private final class TraceStubURLProtocol: URLProtocol {
    enum Reply {
        case response(statusCode: Int, body: Data)
        case failure(URLError.Code)
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var replies: [String: [Reply]] = [:]
    nonisolated(unsafe) private static var requests: [String: [URLRequest]] = [:]

    static func enqueue(_ reply: Reply, path: String) {
        lock.withLock { replies[path, default: []].append(reply) }
    }

    static func requests(path: String) -> [URLRequest] {
        lock.withLock { requests[path] ?? [] }
    }

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.path ?? ""
        let reply: Reply? = Self.lock.withLock {
            Self.requests[path, default: []].append(request)
            return Self.replies[path]?.isEmpty == false ? Self.replies[path]?.removeFirst() : nil
        }
        switch reply ?? .failure(.cannotFindHost) {
        case .response(let statusCode, let body):
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        }
    }

    override func stopLoading() {}
}

final class RadarAPIHelperTraceTests: XCTestCase {
    private var helper: RadarAPIHelper!
    private var path = ""
    private var url: String { "https://api.radar.io\(path)" }

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TraceStubURLProtocol.self]
        helper = RadarAPIHelper()
        // The helper creates its sessions in init and has no injection point; replace the standard one.
        helper.setValue(URLSession(configuration: configuration), forKey: "standardSession")
        path = "/v1/trace-test/\(UUID().uuidString)"
    }

    func test_sendsTraceparent_andEndsTraceBeforeCompletion() throws {
        TraceStubURLProtocol.enqueue(.response(statusCode: 200, body: Data(#"{"meta":{"code":200}}"#.utf8)), path: path)
        let trace = FakeRequestTrace(traceparent: "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01")

        let status = request(trace: trace, headers: ["X-Radar-Network-Type": "wifi"])

        XCTAssertEqual(status, .success)
        XCTAssertEqual(trace.events, ["started", "end SUCCESS", "completion"])
        XCTAssertEqual(trace.startedURL, url)
        XCTAssertEqual(trace.startedHeaders?["X-Radar-Network-Type"] as? String, "wifi")
        let sent = try XCTUnwrap(TraceStubURLProtocol.requests(path: path).first)
        XCTAssertEqual(sent.value(forHTTPHeaderField: "traceparent"), trace.traceparent)
    }

    func test_sendsNoTraceparent_whenTheTraceHasNone() throws {
        TraceStubURLProtocol.enqueue(.response(statusCode: 200, body: Data("{}".utf8)), path: path)
        let trace = FakeRequestTrace(traceparent: nil)

        _ = request(trace: trace)

        let sent = try XCTUnwrap(TraceStubURLProtocol.requests(path: path).first)
        XCTAssertNil(sent.value(forHTTPHeaderField: "traceparent"))
        XCTAssertEqual(trace.events, ["started", "end SUCCESS", "completion"])
    }

    func test_endsTraceWithTheResponseStatus() {
        TraceStubURLProtocol.enqueue(.response(statusCode: 404, body: Data("{}".utf8)), path: path)
        let trace = FakeRequestTrace(traceparent: nil)

        XCTAssertEqual(request(trace: trace), .errorNotFound)
        XCTAssertEqual(trace.events, ["started", "end ERROR_NOT_FOUND", "completion"])
    }

    func test_endsTraceWithServerError_forABodyThatIsNotJSON() {
        TraceStubURLProtocol.enqueue(.response(statusCode: 502, body: Data("<html>".utf8)), path: path)
        let trace = FakeRequestTrace(traceparent: nil)

        XCTAssertEqual(request(trace: trace), .errorServer)
        XCTAssertEqual(trace.events, ["started", "end ERROR_SERVER", "completion"])
    }

    func test_endsTraceWithTheNetworkError() {
        TraceStubURLProtocol.enqueue(.failure(.timedOut), path: path)
        let trace = FakeRequestTrace(traceparent: nil)

        XCTAssertEqual(request(trace: trace), .errorNetwork)
        XCTAssertEqual(trace.events, ["started", "network error", "completion"])
        XCTAssertEqual(trace.networkError?.domain, NSURLErrorDomain)
        XCTAssertEqual(trace.networkError?.code, NSURLErrorTimedOut)
    }

    func test_recordsTheResend_afterALostConnection() {
        TraceStubURLProtocol.enqueue(.failure(.networkConnectionLost), path: path)
        TraceStubURLProtocol.enqueue(.response(statusCode: 200, body: Data("{}".utf8)), path: path)
        let trace = FakeRequestTrace(traceparent: "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01")

        XCTAssertEqual(request(trace: trace), .success)
        XCTAssertEqual(trace.events, ["started", "resend 1", "end SUCCESS", "completion"])
        let sent = TraceStubURLProtocol.requests(path: path)
        XCTAssertEqual(sent.count, 2)
        XCTAssertEqual(sent.last?.value(forHTTPHeaderField: "traceparent"), trace.traceparent)
    }

    func test_endsTraceWithBadRequest_whenPreparationFails() {
        let trace = FakeRequestTrace(traceparent: nil)
        let failed = expectation(description: "Preparation failure handler")

        helper.request(
            withMethod: "POST", url: url, headers: nil, params: ["key": "value"], sleep: false, logPayload: false,
            extendedTimeout: false,
            prepareRequest: { _, error in
                error?.pointee = NSError(domain: "test", code: 1)
                return nil
            },
            preparationFailureHandler: { _ in
                trace.record("preparation failure")
                failed.fulfill()
            },
            trace: trace,
            completionHandler: { _, _, _ in XCTFail("Preparation failures don't call the completion handler") }
        )
        wait(for: [failed], timeout: 5)

        XCTAssertEqual(trace.events, ["started", "end ERROR_BAD_REQUEST", "preparation failure"])
        XCTAssertTrue(TraceStubURLProtocol.requests(path: path).isEmpty)
    }

    func test_requestsWithoutATraceStillComplete() {
        TraceStubURLProtocol.enqueue(.response(statusCode: 200, body: Data("{}".utf8)), path: path)
        let finished = expectation(description: "Completion")

        let completion: RadarAPICompletionHandler = { status, _, _ in
            XCTAssertEqual(status, .success)
            finished.fulfill()
        }
        helper.request(
            withMethod: "GET", url: url, headers: nil, params: nil, sleep: false, logPayload: false, extendedTimeout: false,
            completionHandler: completion)
        wait(for: [finished], timeout: 5)
    }

    /// Sends a GET through the traced overload and returns its status once the completion handler has run.
    private func request(trace: FakeRequestTrace, headers: [String: String]? = nil) -> RadarStatus {
        let finished = expectation(description: "Completion")
        var result: RadarStatus = .errorUnknown
        helper.request(
            withMethod: "GET", url: url, headers: headers, params: nil, sleep: false, logPayload: false,
            extendedTimeout: false, prepareRequest: nil, preparationFailureHandler: nil, trace: trace
        ) { status, _, _ in
            trace.record("completion")
            result = status
            finished.fulfill()
        }
        wait(for: [finished], timeout: 5)
        return result
    }
}
