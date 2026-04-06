//
//  RadarAPIClient.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class RadarAPIClient: Sendable {
    
    struct APIError: Error {
        let data: Data
        let response: URLResponse
        let message: String
    }
    
    public static let shared = RadarAPIClient()
    
    let apiHelper: RadarAPIHelper
    
    init(apiHelper: RadarAPIHelper? = nil) {
        if let apiHelper {
            self.apiHelper = apiHelper
        } else {
            self.apiHelper = RadarAPIHelper()
        }
    }
    
    func logRequest() {
//        RadarLogger.shared.debug("📍 Radar API request | \() \(); headers = \(); params = \()")
    }
    
    func getAsset(url: String) async throws -> Data {
        let (data, response) = if (url.starts(with: "http")) {
            try await apiHelper.request(method: "GET", url: url)
        } else {
            try await apiHelper.radarRequest(method: "GET", url: "assets/\(url)")
        }
        if response.statusCode >= 200 && response.statusCode < 300 {
            return data
        } else {
            throw APIError(data: data, response: response, message: "Invalid asset")
        }
    }
    
    
    struct SyncRegionResponse: Codable {
        let geofences: [RadarGeofenceSwift]?
        let places: [RadarPlaceSwift]?
        let beacons: [RadarBeaconSwift]?
        let regionCenter: RadarCoordinateSwift?
        let regionRadius: Double?
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
        
        do {
            let result = try JSONDecoder().decode(SyncRegionResponse.self, from: data)
        } catch {
            
        }
        
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
    
    func sendLogs(logs: [RadarLog]) async throws {
        let body: [String: Any?] = [
            "id": RadarSettings.id ?? "",
            "installId": RadarSettings.installId,
            "deviceId": await RadarUtils.deviceId,
            "sessionId": RadarSettings.sessionId,
            "logs": logs.map(\.dict)
        ]
        
        let (data, response) = try await apiHelper.radarRequest(method: "POST", url: "logs", body: body)
        
        if response.statusCode >= 200 && response.statusCode < 300 {
            return
        } else {
            throw APIError(data: data, response: response, message: "Failed to send logs")
        }
    }
    
    // TODO: implement rest of RadarAPIClient
}
