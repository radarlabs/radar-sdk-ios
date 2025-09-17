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
    
    // MARK: - getAsset
    func getAsset(url: String) async throws -> Data {
        let (data, _) = if (url.starts(with: "http")) {
            try await apiHelper.request(method: "GET", url: url)
        } else {
            try await apiHelper.radarRequest(method: "GET", url: "assets/\(url)")
        }
        return data
    }
    
    // MARK: - getOfflineData
    struct OfflineData {
        let newGeofences: [RadarGeofence]
        let removeGeofences: [String]
        let defaultTrackingOptions: RadarTrackingOptions?
        let onTripTrackingOptions: RadarTrackingOptions?
        let inGeofenceTrackingOptions: RadarTrackingOptions?
        let inGeofenceTrackingTags: [String]
    }
    func getOfflineData(geofenceIds: [String]) async throws -> OfflineData? {
        let (data, _) = try await apiHelper.radarRequest(method: "GET", url: "offline-data")
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        guard let bridge = RadarSwiftBridgeHolder.shared else {
            // Radar is uninitialized
            return nil
        }
        
        let newGeofences = bridge.RadarGeofences(from: json["newGeofences"] ?? []) ?? []
        let removeGeofences: [String] = (json["removeGeofences"] as? [String]) ?? []
        let defaultTrackingOptions = RadarTrackingOptions.init(from: json["defaultTrackingOptions"] as? [String: Any] ?? [:])
        let onTripTrackingOptions = RadarTrackingOptions.init(from: json["onTripTrackingOptions"] as? [String: Any] ?? [:])
        let inGeofenceTrackingOptions = RadarTrackingOptions.init(from: json["inGeofenceTrackingOptions"] as? [String: Any] ?? [:])
        let inGeofenceTrackingTags: [String] = (json["inGeofenceTrackingTags"] as? [String]) ?? []
        
        return OfflineData(
            newGeofences: newGeofences,
            removeGeofences: removeGeofences,
            defaultTrackingOptions: defaultTrackingOptions,
            onTripTrackingOptions: onTripTrackingOptions,
            inGeofenceTrackingOptions: inGeofenceTrackingOptions,
            inGeofenceTrackingTags: inGeofenceTrackingTags
        )
    }
    
    // TODO: implement rest of RadarAPIClient
}
