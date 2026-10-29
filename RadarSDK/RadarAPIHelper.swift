//
//  RadarApiHelper.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

protocol RadarURLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
extension URLSession: RadarURLSessionProtocol {}

final class RadarAPIHelper: Sendable {

    let session: RadarURLSessionProtocol

    init(session: RadarURLSessionProtocol? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10
            config.timeoutIntervalForResource = 10
            self.session = URLSession(configuration: config)
        }
    }

    func retryingRequest(
        for request: URLRequest,
        prepareRequest: ((URLRequest) throws -> URLRequest)? = nil
    ) async throws -> (Data, URLResponse) {
        let firstRequest = try prepareRequest?(request) ?? request

        do {
            return try await session.data(for: firstRequest)
        } catch {
            guard let error = error as? URLError,
                error.code == .networkConnectionLost
            else {
                throw error
            }

            let retryRequest = try prepareRequest?(request) ?? request
            return try await session.data(for: retryRequest)
        }
    }

    func request(
        method: String,
        url: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: [String: Any?] = [:],
        prepareRequest: ((URLRequest) throws -> URLRequest)? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        return try await request(
            method: method,
            url: url,
            query: query,
            headers: headers,
            body: try Self.jsonBody(body, method: method),
            prepareRequest: prepareRequest
        )
    }

    /// Sends `body` as is, for callers that encode it themselves.
    func request(
        method: String,
        url: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data?,
        prepareRequest: ((URLRequest) throws -> URLRequest)? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard var urlComponents = URLComponents(string: url) else {
            throw URLError(.badURL)
        }
        if !query.isEmpty {
            urlComponents.queryItems = query
        }
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = body

        let startTime = Date()
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await retryingRequest(
                for: request,
                prepareRequest: prepareRequest
            )
        } catch {
            let elapsedMs = Int(Date().timeIntervalSince(startTime) * 1000)
            RadarLogger.shared.log(
                level: .error,
                message: RadarAPIHelper.networkErrorMessage(host: urlComponents.host, error: error, elapsedMs: elapsedMs),
                type: .sdkError
            )
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, httpResponse)
    }

    /// Adds the standard Radar headers. `publishableKey` overrides the current key, for callers that must
    /// authenticate with the key they read earlier (e.g. traces).
    func addRadarHeaders(_ headers: [String: String], publishableKey: String? = nil) async throws -> [String: String] {
        guard let publishableKey = publishableKey ?? RadarSettings.publishableKey else {
            throw RadarError(status: .errorPublishableKey)
        }

        var headers = headers
        headers["Authorization"] = publishableKey
        headers["Content-Type"] = "application/json"
        headers["X-Radar-Config"] = "true"
        headers["X-Radar-Device-Make"] = RadarUtils.deviceMake
        headers["X-Radar-Device-Model"] = RadarUtils.deviceModel
        headers["X-Radar-Device-OS"] = await RadarUtils.deviceOSVersion
        headers["X-Radar-Device-Type"] = RadarUtils.deviceType
        headers["X-Radar-SDK-Version"] = RadarUtils.sdkVersion
        headers["X-Radar-Mobile-Origin"] = Bundle.main.bundleIdentifier
        headers["X-Radar-Network-Type"] = RadarUtils.networkType.rawValue
        headers["X-Radar-App-Info"] = RadarUtils.escapeNonAsciiCharacters(RadarUtils.dictionaryToJson(RadarUtils.appInfo))
        if let product = RadarSettings.product {
            headers["X-Radar-Product"] = product
        }

        return headers
    }

    enum RadarHost {
        case defaultHost
        case verifiedHost
        case verifiedSecondaryHost
    }
    func radarRequest(
        host: RadarHost,
        method: String,
        url: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: [String: Any?] = [:],
        prepareRequest: ((URLRequest) throws -> URLRequest)? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        return try await radarRequest(
            host: host,
            method: method,
            url: url,
            query: query,
            headers: headers,
            body: try Self.jsonBody(body, method: method),
            prepareRequest: prepareRequest
        )
    }

    /// Sends `body` as is, for callers that encode it themselves.
    func radarRequest(
        host: RadarHost,
        method: String,
        url: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data?,
        // nil uses the current key. Trace uploads pass the key that selected the batch, so a key change
        // before the upload can't send one project's spans under another project's key.
        publishableKey: String? = nil,
        prepareRequest: ((URLRequest) throws -> URLRequest)? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let hostUrl =
            switch host {
            case .defaultHost:
                RadarSettings.host
            case .verifiedHost:
                RadarSettings.verifiedHost
            case .verifiedSecondaryHost:
                RadarSettings.defaultVerifiedHostSecondary
            }

        let headers = try await addRadarHeaders(headers, publishableKey: publishableKey)
        let url = "\(hostUrl)/v1/\(url)"

        let (data, response) = try await request(
            method: method,
            url: url,
            query: query,
            headers: headers,
            body: body,
            prepareRequest: prepareRequest
        )

        return (data, response)
    }

    func radarRequest(method: String, url: String, query: [URLQueryItem] = [], headers: [String: String] = [:], body: [String: Any?] = [:]) async throws -> (Data, HTTPURLResponse) {
        return try await radarRequest(host: .defaultHost, method: method, url: url, query: query, headers: headers, body: body)
    }

    func radarVerifiedRequest(method: String, url: String, query: [URLQueryItem] = [], headers: [String: String] = [:], body: [String: Any?] = [:]) async throws -> (Data, HTTPURLResponse) {
        let headers = try await addRadarHeaders(headers)
        let url = "\(RadarSettings.verifiedHost)/v1/\(url)"

        let (data, response) = try await request(method: method, url: url, query: query, headers: headers, body: body)

        return (data, response)
    }

    /// JSON for a non-empty body on a method that takes one, otherwise nil.
    private static func jsonBody(_ body: [String: Any?], method: String) throws -> Data? {
        guard !body.isEmpty, method == "POST" || method == "PUT" || method == "PATCH" else { return nil }
        return try JSONSerialization.data(withJSONObject: body, options: [])
    }

    static func networkErrorMessage(host: String?, error: Error, elapsedMs: Int) -> String {
        let nsError = error as NSError
        return "Network error | host = \(host ?? "unknown"); errorDomain = \(nsError.domain); errorCode = \(nsError.code); errorDescription = \(nsError.localizedDescription); elapsedMs = \(elapsedMs)"
    }
}
