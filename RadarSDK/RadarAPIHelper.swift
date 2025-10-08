//
//  RadarApiHelper.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
final class RadarApiHelper: Sendable {
    init() {
        // initialize device info, required for Radar request headers
        DispatchQueue.main.async {
            RadarUtils.initalize()
        }
    }
    
    enum HTTPMethod: String {
        case get
        case post
        case put
        case patch
        case delete
    }
    
    internal enum HTTPError: Error {
        case badResponse
        case badRequest
        case unauthorized
        case paymentRequired
        case forbidden
        case notFound
        case rateLimit
        case server
        case unknown
    }
    
    func request(method: HTTPMethod, url: String, query: [String: String] = [:], headers: [String: String] = [:], body: [String: Any?] = [:]) async throws -> Data {
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
        request.httpMethod = method.rawValue.uppercased()
        
        // add headers to the request
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        if (!body.isEmpty && (method == .post || method == .put || method == .patch)) {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.badResponse
        }
        
        switch (httpResponse.statusCode) {
        case 200..<400:
            break // success
        case 400:
            throw HTTPError.badRequest
        case 401:
            throw HTTPError.unauthorized
        case 402:
            throw HTTPError.paymentRequired
        case 403:
            throw HTTPError.forbidden
        case 404:
            throw HTTPError.notFound
        case 429:
            throw HTTPError.rateLimit
        case 500...599:
            throw HTTPError.server
        default:
            throw HTTPError.unknown
        }
        
        return data
    }
    
    func radarRequest(method: HTTPMethod, url: String, query: [String: String] = [:], headers: [String: String] = [:], body: [String: Any?] = [:]) async throws -> Data {
        guard let publishableKey = UserDefaults.standard.string(forKey: "radar-publishableKey"),
              let radarHost = UserDefaults.standard.string(forKey: "radar-host") else {
            throw URLError(.userAuthenticationRequired)
        }
        
        var headers = headers
        headers["Authorization"] = publishableKey
        headers["Content-Type"] = "application/json"
        headers["X-Radar-Config"] = "true"
        headers["X-Radar-SDK-Version"] = RadarUtils.sdkVersion
        headers["X-Radar-Device-Type"] = RadarUtils.deviceType
        headers["X-Radar-Device-Make"] = RadarUtils.deviceMake
        headers["X-Radar-Device-Model"] = RadarUtils.deviceModel
        headers["X-Radar-Device-OS"] = RadarUtils.deviceOS
        headers["X-Radar-Mobile-Origin"] = Bundle.main.bundleIdentifier
        headers["X-Radar-Network-Type"] = RadarUtils.networkTypeString
        headers["X-Radar-App-Info"] = RadarUtils.toJSONString(dict: RadarUtils.appInfo)
        
        let url = "\(radarHost)/v1/\(url)"
        
        return try await request(method: method, url: url, query: query, headers: headers, body: body)
    }
    
    func HTTPErrorToRadarStatus(_ error: HTTPError) -> RadarStatus {
        switch error {
        case .badRequest:
            return .errorBadRequest
        case .unauthorized:
            return .errorUnauthorized
        case .paymentRequired:
            return .errorPaymentRequired
        case .forbidden:
            return .errorForbidden
        case .notFound:
            return .errorNotFound
        case .rateLimit:
            return .errorRateLimit
        case .server:
            return .errorServer
        default:
            return .errorUnknown
        }
    }
}
