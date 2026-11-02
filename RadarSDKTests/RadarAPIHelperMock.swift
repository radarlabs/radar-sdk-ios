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
    private(set) var lastTrace: (any RadarAPIRequestTrace)?

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

    /// `RadarAPIClient` sends every request through this overload. Like `RadarAPIHelper`, it sends the trace's
    /// `traceparent` and ends the trace with the request's status before calling back. The request itself goes to the
    /// overload `RadarAPIClient` used before tracing, so subclasses that override it keep working.
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
        trace: (any RadarAPIRequestTrace)?,
        completionHandler: RadarAPICompletionHandler?
    ) {
        // Requests that prepare their body (verified requests) were never mocked here; MainQueueAPIHelperMock mocks
        // them.
        guard prepareRequest == nil else {
            super.request(
                withMethod: method, url: url, headers: headers, params: params, sleep: sleep, logPayload: logPayload,
                extendedTimeout: extendedTimeout, prepareRequest: prepareRequest,
                preparationFailureHandler: preparationFailureHandler, trace: trace, completionHandler: completionHandler)
            return
        }
        lastTrace = trace
        request(
            withMethod: method, url: url, headers: Self.headers(headers, tracedBy: trace), params: params, sleep: sleep,
            logPayload: logPayload, extendedTimeout: extendedTimeout
        ) { status, response, error in
            trace?.end(with: status)
            completionHandler?(status, response, error)
        }
    }

    /// `headers` plus the trace's `traceparent`, as `RadarAPIHelper` sends them.
    static func headers(_ headers: [AnyHashable: Any]?, tracedBy trace: (any RadarAPIRequestTrace)?) -> [AnyHashable: Any]? {
        guard let traceparent = trace?.traceparent else { return headers }
        var traced = headers ?? [:]
        traced["traceparent"] = traceparent
        return traced
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
