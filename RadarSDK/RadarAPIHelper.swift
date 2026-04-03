//
//  RadarApiHelper.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

// protocol to allow URLSession to be mocked and tested
protocol RadarURLSessionProtocol: Sendable {
    @available(iOS 13.0, *)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: RadarURLSessionProtocol {}

@available(iOS 13.0, *)
final class RadarApiHelper: Sendable {
    
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
    
    func retryingRequest(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            return (data, response)
        } catch {
            // retry once on network connection lost error
            if let error = error as? URLError,
               error.code == .networkConnectionLost {
                let (data, response) = try await session.data(for: request)
                return (data, response)
            }
            
            throw error
        }
    }
    
    
    func request(method: String, url: String, query: [String: String] = [:], headers: [String: String] = [:], body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        // transform URL
        // turn query into a string of format: "?key=value&key2=value2" or "" if there are no queries
        let queryString = query.isEmpty ? "" : ("?" + query.compactMap { key, value in
            key + "=" + value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        }.joined(separator: "&"))

        guard let urlObject = URL(string: "\(url)\(queryString)") else {
            // could not turn url into an URL object
            throw URLError(.badURL)
        }

        var request = URLRequest(url: urlObject)
        request.httpMethod = method

        // add headers to the request
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }

        if (body != nil && (method == "POST" || method == "PUT" || method == "PATCH")) {
            request.httpBody = body
        }
        
        let (data, response) = try await retryingRequest(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, httpResponse)
    }

    func radarRequest(method: String, url: String, query: [String: String] = [:], headers: [String: String] = [:], body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        guard let publishableKey = RadarSettings.publishableKey else {
            throw URLError(.userAuthenticationRequired)
        }
        
        var headers = headers
        headers["Authorization"] = publishableKey
        headers["Content-Type"] = "application/json"
        headers["X-Radar-Config"] = "true"
        headers["X-Radar-Device-Make"] = RadarUtils.deviceMake
        headers["X-Radar-Device-Model"] = RadarUtils.deviceModel
        headers["X-Radar-Device-OS"] = await RadarUtils.deviceOS
        headers["X-Radar-Device-Type"] = RadarUtils.deviceType
        headers["X-Radar-SDK-Version"] = RadarUtils.sdkVersion
        headers["X-Radar-Mobile-Origin"] = Bundle.main.bundleIdentifier
        headers["X-Radar-Network-Type"] = RadarUtils.networkType.rawValue
        headers["X-Radar-App-Info"] = RadarUtils.dictionaryToJson(RadarUtils.appInfo)
        
        let url = "\(RadarSettings.host)/v1/\(url)"

        let (data, response) = try await request(method: method, url: url, query: query, headers: headers, body: body)

        return (data, response)
    }
}
