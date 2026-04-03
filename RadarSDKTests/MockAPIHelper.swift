//
//  MockAPIHelper.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Testing
@testable import RadarSDK

final class MockURLSession: RadarURLSessionProtocol, @unchecked Sendable {
    struct Handler {
        let on: (URLRequest) -> Bool
        let response: Data
    }
    
    var handlers = [Handler]()
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let ok = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.0", headerFields: [:])!
        for handler in handlers {
            if handler.on(request) {
                return (handler.response, ok as URLResponse)
            }
        }
        let notFound = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: "1.0", headerFields: [:])!
        return (Data(), notFound)
    }
    
    func on(_ request: @escaping (URLRequest) -> Bool, _ response: Data) {
        handlers.append(Handler(on: request, response: response))
    }
    
    func on(_ request: String, _ response: [String: Any]) {
        guard let json = try? JSONSerialization.data(withJSONObject: response) else {
            return
        }
        on({ req in req.url?.absoluteString == request }, json)
    }
    
    func on(_ request: String, respondWithResource resource: String) {
        guard let response = RadarTestUtilsSwift.data(fromResource: resource) else {
            Issue.record("invalid resource '\(resource)'")
            return
        }
        on({ req in req.url?.absoluteString == request }, response)
    }
}
