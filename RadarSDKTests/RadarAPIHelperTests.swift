//
//  RadarAPIHelperTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

actor RetryTestSession: RadarURLSessionProtocol {
    private let failures: [URLError.Code]
    private let responseData: Data
    private var requests: [URLRequest] = []

    init(failures: [URLError.Code], responseData: Data = Data()) {
        self.failures = failures
        self.responseData = responseData
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let attempt = requests.count
        requests.append(request)

        if attempt < failures.count {
            throw URLError(failures[attempt])
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        return (responseData, response)
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

@Suite
struct RadarAPIHelperTests {

    @Test func networkErrorMessage_includesHost() {
        let error = URLError(.timedOut)
        let message = RadarAPIHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 1234)
        #expect(message.contains("host = api.radar.io"))
    }

    @Test func networkErrorMessage_nilHostShowsUnknown() {
        let error = URLError(.timedOut)
        let message = RadarAPIHelper.networkErrorMessage(host: nil, error: error, elapsedMs: 0)
        #expect(message.contains("host = unknown"))
    }

    @Test func networkErrorMessage_includesElapsedMs() {
        let error = URLError(.timedOut)
        let message = RadarAPIHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 5678)
        #expect(message.contains("elapsedMs = 5678"))
    }

    @Test func networkErrorMessage_timeout() {
        let error = URLError(.timedOut)
        let message = RadarAPIHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 0)
        #expect(message.contains("errorDomain = NSURLErrorDomain"))
        #expect(message.contains("errorCode = \(URLError.Code.timedOut.rawValue)"))
    }

    @Test func networkErrorMessage_dnsFailure() {
        let error = URLError(.cannotFindHost)
        let message = RadarAPIHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 0)
        #expect(message.contains("errorCode = \(URLError.Code.cannotFindHost.rawValue)"))
    }

    @Test func networkErrorMessage_sslFailure() {
        let error = URLError(.secureConnectionFailed)
        let message = RadarAPIHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 0)
        #expect(message.contains("errorCode = \(URLError.Code.secureConnectionFailed.rawValue)"))
    }

    @Test func networkErrorMessage_cannotConnect() {
        let error = URLError(.cannotConnectToHost)
        let message = RadarAPIHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 0)
        #expect(message.contains("errorCode = \(URLError.Code.cannotConnectToHost.rawValue)"))
    }

    @Test func networkErrorMessage_includesErrorDescription() {
        let error = URLError(.timedOut)
        let message = RadarAPIHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 0)
        #expect(message.contains("errorDescription ="))
        #expect(!message.contains("errorDescription = ;"))
    }

    @Test("A lost connection retries the same request")
    func lostConnectionReusesRequest() async throws {
        let session = RetryTestSession(failures: [.networkConnectionLost])
        let helper = RadarAPIHelper(session: session)
        let url = try #require(
            URL(string: "https://api-verified.radar.io/v1/reveal/risk")
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("encrypted-envelope".utf8)
        request.setValue("test-key", forHTTPHeaderField: "Authorization")

        _ = try await helper.retryingRequest(for: request)

        let requests = await session.recordedRequests()
        #expect(requests.count == 2)

        for sentRequest in requests {
            #expect(sentRequest.url == request.url)
            #expect(sentRequest.httpMethod == request.httpMethod)
            #expect(sentRequest.httpBody == request.httpBody)
            #expect(sentRequest.allHTTPHeaderFields == request.allHTTPHeaderFields)
        }
    }

    @Test("A second lost connection is propagated without another retry")
    func lostConnectionRetriesOnlyOnce() async throws {
        let session = RetryTestSession(
            failures: [.networkConnectionLost, .networkConnectionLost]
        )
        let helper = RadarAPIHelper(session: session)
        let url = try #require(URL(string: "https://api-verified.radar.io"))

        do {
            _ = try await helper.retryingRequest(for: URLRequest(url: url))
            Issue.record("Expected the second connection failure")
        } catch {
            #expect((error as? URLError)?.code == .networkConnectionLost)
        }

        let requests = await session.recordedRequests()
        #expect(requests.count == 2)
    }

    @Test(
        "Other network errors are propagated without retrying",
        arguments: [
            URLError.Code.timedOut,
            .cannotFindHost,
            .cannotConnectToHost,
            .secureConnectionFailed,
            .cancelled,
        ]
    )
    func otherNetworkErrorsDoNotRetry(code: URLError.Code) async throws {
        let session = RetryTestSession(failures: [code])
        let helper = RadarAPIHelper(session: session)
        let url = try #require(URL(string: "https://api-verified.radar.io"))

        do {
            _ = try await helper.retryingRequest(for: URLRequest(url: url))
            Issue.record("Expected the network error")
        } catch {
            #expect((error as? URLError)?.code == code)
        }

        let requests = await session.recordedRequests()
        #expect(requests.count == 1)
    }

    @Test("Request preparation runs before each transport attempt")
    func preparesEachAttempt() async throws {
        let session = RetryTestSession(failures: [.networkConnectionLost])
        let helper = RadarAPIHelper(session: session)
        let url = try #require(URL(string: "https://api-verified.radar.io"))

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("test-key", forHTTPHeaderField: "Authorization")

        var preparations = 0
        _ = try await helper.retryingRequest(for: request) { original in
            #expect(original.httpBody == nil)
            preparations += 1

            var prepared = original
            prepared.httpBody = Data("envelope-\(preparations)".utf8)
            return prepared
        }

        let requests = await session.recordedRequests()
        #expect(preparations == 2)
        #expect(requests.count == 2)
        guard requests.count == 2 else { return }

        #expect(requests[0].httpBody == Data("envelope-1".utf8))
        #expect(requests[1].httpBody == Data("envelope-2".utf8))

        for sent in requests {
            #expect(sent.url == request.url)
            #expect(sent.httpMethod == request.httpMethod)
            #expect(sent.allHTTPHeaderFields == request.allHTTPHeaderFields)
        }
    }

    @Test(
        "Preparation failure stops dispatch without another preparation",
        arguments: [1, 2]
    )
    func preparationFailureStopsDispatch(failingAttempt: Int) async throws {
        let session = RetryTestSession(failures: [.networkConnectionLost])
        let helper = RadarAPIHelper(session: session)
        let url = try #require(URL(string: "https://api-verified.radar.io"))
        var preparations = 0

        do {
            _ = try await helper.retryingRequest(
                for: URLRequest(url: url)
            ) { original in
                preparations += 1

                if preparations == failingAttempt {
                    // Even this error must not trigger a retry when preparation throws it.
                    throw URLError(.networkConnectionLost)
                }

                var prepared = original
                prepared.httpBody = Data("encrypted-envelope".utf8)
                return prepared
            }
            Issue.record("Expected preparation to fail")
        } catch {
            #expect((error as? URLError)?.code == .networkConnectionLost)
        }

        let requests = await session.recordedRequests()
        #expect(preparations == failingAttempt)
        #expect(requests.count == failingAttempt - 1)
    }
}
