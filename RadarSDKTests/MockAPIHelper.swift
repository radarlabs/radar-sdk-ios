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
    }

    var handlers = [Handler]()

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let ok = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.0", headerFields: [:])!  // swiftlint:disable:this identifier_name
        for handler in handlers {
            if handler.on(request) {  // swiftlint:disable:this for_where
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
}
