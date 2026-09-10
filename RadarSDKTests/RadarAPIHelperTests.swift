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

private enum RequestPreparationError: Error {
    case failed
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

    @Test("A lost connection rebuilds the request before retrying")
    func lostConnectionRebuildsRequest() async throws {
        let session = RetryTestSession(failures: [.networkConnectionLost])
        let helper = RadarAPIHelper(session: session)
        let url = try #require(URL(string: "https://api-verified.radar.io/v1/reveal/risk"))

        _ = try await helper.retryingRequest(makeRequest: {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = Data(UUID().uuidString.utf8)
            return request
        })

        let requests = await session.recordedRequests()
        #expect(requests.count == 2)
        guard requests.count == 2 else { return }

        let firstBody = try #require(requests[0].httpBody)
        let retryBody = try #require(requests[1].httpBody)

        #expect(firstBody != retryBody)
        #expect(requests[0].url == url)
        #expect(requests[1].url == url)
        #expect(requests[0].httpMethod == "POST")
        #expect(requests[1].httpMethod == "POST")
    }

    @Test("A second lost connection is propagated without another retry")
    func lostConnectionRetriesOnlyOnce() async throws {
        let session = RetryTestSession(
            failures: [.networkConnectionLost, .networkConnectionLost]
        )
        let helper = RadarAPIHelper(session: session)
        let url = try #require(URL(string: "https://api-verified.radar.io"))

        do {
            _ = try await helper.retryingRequest(makeRequest: {
                URLRequest(url: url)
            })
            Issue.record("Expected the second connection failure")
        } catch {
            #expect((error as? URLError)?.code == .networkConnectionLost)
        }

        let requests = await session.recordedRequests()
        #expect(requests.count == 2)
    }

    @Test("A timeout is propagated without retrying")
    func timeoutDoesNotRetry() async throws {
        let session = RetryTestSession(failures: [.timedOut])
        let helper = RadarAPIHelper(session: session)
        let url = try #require(URL(string: "https://api-verified.radar.io"))

        do {
            _ = try await helper.retryingRequest(makeRequest: {
                URLRequest(url: url)
            })
            Issue.record("Expected the timeout")
        } catch {
            #expect((error as? URLError)?.code == .timedOut)
        }

        let requests = await session.recordedRequests()
        #expect(requests.count == 1)
    }

    @Test(
        "Preparation failure prevents sending that attempt",
        arguments: [false, true]
    )
    func preparationFailureStopsSending(onRetry: Bool) async throws {
        let session = RetryTestSession(failures: [.networkConnectionLost])
        let helper = RadarAPIHelper(session: session)
        let url = try #require(URL(string: "https://api-verified.radar.io"))

        do {
            _ = try await helper.retryingRequest(makeRequest: {
                let sentRequests = await session.recordedRequests()

                if !onRetry || !sentRequests.isEmpty {
                    throw RequestPreparationError.failed
                }

                return URLRequest(url: url)
            })
            Issue.record("Expected request preparation to fail")
        } catch {
            #expect(error is RequestPreparationError)
        }

        let requests = await session.recordedRequests()
        #expect(requests.count == (onRetry ? 1 : 0))
    }
}
