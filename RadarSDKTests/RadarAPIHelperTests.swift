//
//  RadarAPIHelperTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
@testable import RadarSDK

@Suite
struct RadarAPIHelperTests {

    @Test func networkErrorMessage_includesHost() {
        let error = URLError(.timedOut)
        let message = RadarApiHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 1234)
        #expect(message.contains("host = api.radar.io"))
    }

    @Test func networkErrorMessage_nilHostShowsUnknown() {
        let error = URLError(.timedOut)
        let message = RadarApiHelper.networkErrorMessage(host: nil, error: error, elapsedMs: 0)
        #expect(message.contains("host = unknown"))
    }

    @Test func networkErrorMessage_includesElapsedMs() {
        let error = URLError(.timedOut)
        let message = RadarApiHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 5678)
        #expect(message.contains("elapsedMs = 5678"))
    }

    @Test func networkErrorMessage_timeout() {
        let error = URLError(.timedOut)
        let message = RadarApiHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 0)
        #expect(message.contains("errorDomain = NSURLErrorDomain"))
        #expect(message.contains("errorCode = \(URLError.Code.timedOut.rawValue)"))
    }

    @Test func networkErrorMessage_dnsFailure() {
        let error = URLError(.cannotFindHost)
        let message = RadarApiHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 0)
        #expect(message.contains("errorCode = \(URLError.Code.cannotFindHost.rawValue)"))
    }

    @Test func networkErrorMessage_sslFailure() {
        let error = URLError(.secureConnectionFailed)
        let message = RadarApiHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 0)
        #expect(message.contains("errorCode = \(URLError.Code.secureConnectionFailed.rawValue)"))
    }

    @Test func networkErrorMessage_cannotConnect() {
        let error = URLError(.cannotConnectToHost)
        let message = RadarApiHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 0)
        #expect(message.contains("errorCode = \(URLError.Code.cannotConnectToHost.rawValue)"))
    }

    @Test func networkErrorMessage_includesErrorDescription() {
        let error = URLError(.timedOut)
        let message = RadarApiHelper.networkErrorMessage(host: "api.radar.io", error: error, elapsedMs: 0)
        #expect(message.contains("errorDescription ="))
        #expect(!message.contains("errorDescription = ;"))
    }
}
