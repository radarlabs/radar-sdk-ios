//
//  RadarApiHelper.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 8/6/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
class RadarApiHelper {
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
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, httpResponse)
    }
    
    func radarRequest(method: String, url: String, query: [String: String] = [:], headers: [String: String] = [:], body: [String: Any] = [:]) async throws {
        let publishableKey = UserDefaults.standard.string(forKey: "radar-publishableKey")!
        let radarHost = UserDefaults.standard.string(forKey: "radar-host")!
        
        var headers = headers
        headers["Authorization"] = publishableKey
        
        var url = "\(radarHost)/v1/\(url)"
        
        let (data, response) = try await request(method: method, url: url, query: query, headers: headers, body: body)
        
        
    }
}
