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
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try await retryingRequest(makeRequest: { request })
    }

    func retryingRequest(
        makeRequest: () async throws -> URLRequest
    ) async throws -> (Data, URLResponse) {
        let firstRequest = try await makeRequest()

        do {
            return try await session.data(for: firstRequest)
        } catch {
            guard let networkError = error as? URLError,
                networkError.code == .networkConnectionLost
            else {
                throw error
            }
        }

        let retryRequest = try await makeRequest()
        return try await session.data(for: retryRequest)
    }

    func request(
        method: String,
        url: String,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        body: [String: Any?] = [:],
        prepareRequest: ((URLRequest) async throws -> URLRequest)? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let queryString =
            query.isEmpty
            ? ""
            : ("?"
                + query.compactMap { key, value in
                    key + "=" + value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                }.joined(separator: "&"))

        guard let urlObject = URL(string: "\(url)\(queryString)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: urlObject)
        request.httpMethod = method

        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }

        if !body.isEmpty && (method == "POST" || method == "PUT" || method == "PATCH") {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        let baseRequest = request
        let startTime = Date()
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await retryingRequest(makeRequest: {
                guard let prepareRequest else {
                    return baseRequest
                }

                return try await prepareRequest(baseRequest)
            })
        } catch {
            let elapsedMs = Int(Date().timeIntervalSince(startTime) * 1000)
            RadarLogger.shared.log(
                level: .error,
                message: RadarAPIHelper.networkErrorMessage(host: urlObject.host, error: error, elapsedMs: elapsedMs),
                type: .sdkError
            )
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, httpResponse)
    }

    func addRadarHeaders(_ headers: [String: String]) async throws -> [String: String] {
        guard let publishableKey = RadarSettings.publishableKey else {
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

    func radarRequest(method: String, url: String, query: [String: String] = [:], headers: [String: String] = [:], body: [String: Any?] = [:]) async throws -> (Data, HTTPURLResponse) {

        let headers = try await addRadarHeaders(headers)
        let url = "\(RadarSettings.host)/v1/\(url)"

        let (data, response) = try await request(method: method, url: url, query: query, headers: headers, body: body)

        return (data, response)
    }

    func radarVerifiedRequest(
        method: String,
        url: String,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        body: [String: Any?] = [:],
        useSecondaryVerifiedHost: Bool = false,
        prepareRequest: ((URLRequest) async throws -> URLRequest)? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let headers = try await addRadarHeaders(headers)

        let host =
            useSecondaryVerifiedHost
            ? RadarSettings.DefaultVerifiedHostSecondary
            : RadarSettings.verifiedHost

        let requestURL = "\(host)/v1/\(url)"

        return try await request(
            method: method,
            url: requestURL,
            query: query,
            headers: headers,
            body: body,
            prepareRequest: prepareRequest
        )
    }

    static func networkErrorMessage(host: String?, error: Error, elapsedMs: Int) -> String {
        let nsError = error as NSError
        return "Network error | host = \(host ?? "unknown"); errorDomain = \(nsError.domain); errorCode = \(nsError.code); errorDescription = \(nsError.localizedDescription); elapsedMs = \(elapsedMs)"
    }
}
