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
    
    func fetchSyncRegion(latitude: Double, longitude: Double) async throws -> SyncRegionResponse {
        var body: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        if let userId = RadarSettings.userId {
            body["userId"] = userId
        }
        
        let (data, _) = try await apiHelper.radarRequest(
            method: "POST",
            url: "sync/region",
            body: body
        )
        
        guard let res = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        
        let decoder = JSONDecoder()
        
        var geofences: [RadarGeofenceSwift]?
        if let arr = res["geofences"] as? [[String: Any]],
           let jsonData = try? JSONSerialization.data(withJSONObject: arr) {
            geofences = try? decoder.decode([RadarGeofenceSwift].self, from: jsonData)
        }
        
        var places: [RadarPlaceSwift]?
        if let arr = res["places"] as? [[String: Any]],
           let jsonData = try? JSONSerialization.data(withJSONObject: arr) {
            places = try? decoder.decode([RadarPlaceSwift].self, from: jsonData)
        }
        
        var beacons: [RadarBeaconSwift]?
        if let arr = res["beacons"] as? [[String: Any]],
           let jsonData = try? JSONSerialization.data(withJSONObject: arr) {
            beacons = try? decoder.decode([RadarBeaconSwift].self, from: jsonData)
        }
        
        var regionCenter: RadarCoordinateSwift?
        var regionRadius: Double?
        if let regionDict = res["region"] as? [String: Any],
           let lat = regionDict["latitude"] as? Double,
           let lng = regionDict["longitude"] as? Double,
           let radius = regionDict["radius"] as? Double,
           radius > 0 {
            regionCenter = RadarCoordinateSwift(latitude: lat, longitude: lng)
            regionRadius = radius
        }
        
        return SyncRegionResponse(
            geofences: geofences,
            places: places,
            beacons: beacons,
            regionCenter: regionCenter,
            regionRadius: regionRadius
        )
    }
    
    
    // TODO: implement rest of RadarAPIClient
}
