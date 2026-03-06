//
//  RadarAPIClient.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class RadarAPIClient: Sendable {
    
    public static let shared = RadarAPIClient()
    
    let apiHelper = RadarApiHelper()
    
    func getAsset(url: String) async throws -> Data {
        let (data, _) = if (url.starts(with: "http")) {
            try await apiHelper.request(method: "GET", url: url)
        } else {
            try await apiHelper.radarRequest(method: "GET", url: "assets/\(url)")
        }
        return data
    }
    // TODO: implement rest of RadarAPIClient
}
