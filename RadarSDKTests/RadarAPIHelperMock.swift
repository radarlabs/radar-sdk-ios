//
//  RadarAPIHelperMock.swift
//  RadarSDKTests
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation
// Not `@testable`: that would also expose the SDK's internal Swift `RadarAPIHelper`, making the
// name ambiguous. This mock subclasses the Objective-C one that `RadarAPIClient.apiHelper` holds.
import RadarSDK

/// Returns canned responses instead of making network requests, and records the last request.
///
/// Responses and statuses set for a URL take precedence over `mockResponse` and `mockStatus`.
class RadarAPIHelperMock: RadarAPIHelper {
    var mockStatus: RadarStatus = .success
    var mockResponse: [AnyHashable: Any] = [:]
    var mockError: Error?

    private(set) var lastMethod: String?
    private(set) var lastUrl: String?
    private(set) var lastHeaders: [AnyHashable: Any]?
    private(set) var lastParams: [AnyHashable: Any]?

    private var mockResponses: [String: [AnyHashable: Any]] = [:]
    private var mockStatuses: [String: RadarStatus] = [:]

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
        lastMethod = method
        lastUrl = url
        lastHeaders = headers
        lastParams = params

        let response = mockResponses[url] ?? mockResponse
        let status = mockStatuses[url] ?? mockStatus
        completionHandler?(status, response, mockError)
    }

    func setMockResponse(_ response: [AnyHashable: Any], forMethod url: String) {
        mockResponses[url] = response
    }

    func setMockStatus(_ status: RadarStatus, forMethod url: String) {
        mockStatuses[url] = status
    }

    func setMockStatus(_ status: RadarStatus, response: [AnyHashable: Any], forMethod url: String) {
        mockStatuses[url] = status
        mockResponses[url] = response
    }
}
