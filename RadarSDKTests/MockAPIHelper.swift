//
//  MockAPIHelper.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

@testable import RadarSDK

final class MockURLSession: RadarURLSessionProtocol, @unchecked Sendable {
    struct Handler {
        let on: (URLRequest) -> Bool  // swiftlint:disable:this identifier_name
        let response: Data
        var statusCode = 200
    }

    var handlers = [Handler]()

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        for handler in handlers {
            if handler.on(request) {  // swiftlint:disable:this for_where
                let response = HTTPURLResponse(url: request.url!, statusCode: handler.statusCode, httpVersion: "1.0", headerFields: [:])!
                return (handler.response, response as URLResponse)
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

    func on(_ request: @escaping (URLRequest) -> Bool, _ response: [String: Any], statusCode: Int) {
        guard let json = try? JSONSerialization.data(withJSONObject: response) else {
            return
        }
        handlers.append(Handler(on: request, response: json, statusCode: statusCode))
    }
}
