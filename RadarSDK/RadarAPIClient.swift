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
    
    struct OfflineData {
        let geofences: [RadarGeofence]
        let sdkConfigurations: [RadarSdkConfiguration]
        
        var dictionary: [String: Any] {[
                "geofences": geofences.map(RadarGeofence.dictionaryValue),
                "sdkConfigurations": sdkConfigurations.map(RadarSdkConfiguration.dictionaryValue)
        ]}
    }
    func getOfflineData() async throws -> OfflineData? {
        let (data, _) = try await apiHelper.radarRequest(method: "GET", url: "offline-data")
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        guard let bridge = RadarSwiftBridgeHolder.shared else {
            // Radar is uninitialized
            return nil
        }
        
        let geofences = bridge.RadarGeofences(from: json["geofences"] ?? [])
        let trackingOptions = RadarTrackingOptions.init(from: json["tracking_options"] as? [String: Any] ?? [:])
        
        return nil
    }
    
    // TODO: implement rest of RadarAPIClient
}
