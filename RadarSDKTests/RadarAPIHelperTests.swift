//
//  RadarAPIHelperTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
@testable import RadarSDK

@Suite struct RadarAPIHelperTests {

    @Test("completion handler receives nil error on success")
    func completionHandler_nilErrorOnSuccess() {
        let mock = RadarAPIHelperMock()
        mock.mockStatus = .success
        mock.mockResponse = [:]

        var receivedError: Error?
        var receivedStatus: RadarStatus = .errorUnknown
        mock.request(withMethod: "GET", url: "https://api.radar.io/test",
                     headers: nil, params: nil, sleep: false, logPayload: false,
                     extendedTimeout: false) { status, _, error in
            receivedStatus = status
            receivedError = error
        }

        #expect(receivedError == nil)
        #expect(receivedStatus == .success)
    }

    @Test("completion handler propagates NSError through RadarAPICompletionHandler")
    func completionHandler_propagatesError() {
        let mock = RadarAPIHelperMock()
        mock.mockStatus = .errorNetwork
        mock.mockResponse = [:]
        let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        mock.mockError = expectedError

        var receivedError: Error?
        var receivedStatus: RadarStatus = .success
        mock.request(withMethod: "GET", url: "https://api.radar.io/test",
                     headers: nil, params: nil, sleep: false, logPayload: false,
                     extendedTimeout: false) { status, _, error in
            receivedStatus = status
            receivedError = error
        }

        #expect(receivedError != nil)
        #expect((receivedError as? NSError)?.domain == NSURLErrorDomain)
        #expect((receivedError as? NSError)?.code == NSURLErrorNotConnectedToInternet)
        #expect(receivedStatus == .errorNetwork)
    }
}
