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
    
    static func urlMatch(_ match: String) -> (URLRequest) -> Bool {
        return { request in
            guard let url = request.url else {
                return false
            }
            let sections = url.absoluteString.split(separator: "?")
            guard let base = sections.first else {
                return false
            }
            return base == match
        }
    }
}
