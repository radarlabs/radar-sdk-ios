//
//  RadarApiHelper.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
final class RadarApiHelper: Sendable {
    func request(method: String, url: String, query: [String: String] = [:], headers: [String: String] = [:], body: [String: Any] = [:]) async throws -> (Data, HTTPURLResponse) {

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

        if (!body.isEmpty && (method == "POST" || method == "PUT" || method == "PATCH")) {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, httpResponse)
    }

    func radarRequest(method: String, url: String, query: [String: String] = [:], headers: [String: String] = [:], body: [String: Any] = [:]) async throws -> (Data, HTTPURLResponse) {
        guard let publishableKey = RadarSettings.publishableKey else {
            throw URLError(.userAuthenticationRequired)
        }
        
        var headers = headers
        headers["Authorization"] = publishableKey
        // TODO: add additional mobile headers when RadarUtils is in swift
        /*
        @"Content-Type": @"application/json",
        @"X-Radar-Config": @"true",
        @"X-Radar-Device-Make": [RadarUtils deviceMake],
        @"X-Radar-Device-Model": [RadarUtils deviceModel],
        @"X-Radar-Device-OS": [RadarUtils deviceOS],
        @"X-Radar-Device-Type": [RadarUtils deviceType],
        @"X-Radar-SDK-Version": [RadarUtils sdkVersion],
        @"X-Radar-Mobile-Origin": [[NSBundle mainBundle] bundleIdentifier],
        @"X-Radar-Network-Type": [RadarUtils networkTypeString],
        @"X-Radar-App-Info": appInfoJSON
         */

        let url = "\(RadarSettings.host)/v1/\(url)"

        let (data, response) = try await request(method: method, url: url, query: query, headers: headers, body: body)

        return (data, response)
    }
}
