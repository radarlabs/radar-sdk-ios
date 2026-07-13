//
//  RadarAPIClient.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

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

    func getAsset(url: String) async throws -> Data {
        let (data, _) =
            if url.starts(with: "http") {
                try await apiHelper.request(method: "GET", url: url)
            } else {
                try await apiHelper.radarRequest(method: "GET", url: "assets/\(url)")
            }
        return data
    }

    func fetchSyncRegion(latitude: Double, longitude: Double) async throws -> SyncRegionResponse {
        var body: [String: Any?] = [
            "latitude": latitude,
            "longitude": longitude,
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
            let jsonData = try? JSONSerialization.data(withJSONObject: arr)
        {
            geofences = try? decoder.decode([RadarGeofenceSwift].self, from: jsonData)
        }

        var places: [RadarPlaceSwift]?
        if let arr = res["places"] as? [[String: Any]],
            let jsonData = try? JSONSerialization.data(withJSONObject: arr)
        {
            places = try? decoder.decode([RadarPlaceSwift].self, from: jsonData)
        }

        var beacons: [RadarBeaconSwift]?
        if let arr = res["beacons"] as? [[String: Any]],
            let jsonData = try? JSONSerialization.data(withJSONObject: arr)
        {
            beacons = try? decoder.decode([RadarBeaconSwift].self, from: jsonData)
        }

        var regionCenter: RadarCoordinateSwift?
        var regionRadius: Double?
        if let regionDict = res["region"] as? [String: Any],
            let lat = regionDict["latitude"] as? Double,
            let lng = regionDict["longitude"] as? Double,
            let radius = regionDict["radius"] as? Double,
            radius > 0
        {
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
            "logs": logs.map(\.dict),
        ]

        let (data, response) = try await apiHelper.radarRequest(method: "POST", url: "logs", body: body)

        if response.statusCode >= 200 && response.statusCode < 300 {
            return
        } else {
            throw APIError(data: data, response: response, message: "Failed to send logs")
        }
    }
    
    func revealRisk(
        fraudPayload: String,
        useSecondaryVerifiedHost: Bool,
    ) async throws -> RadarRevealRiskToken {
        let sdkConfiguration = RadarSettings.sdkConfiguration
        
        let params: [String: Any?] = [
            "installId": RadarSettings.installId,
            "userId": RadarSettings.userId,
            "deviceId": await RadarUtils.deviceId,
            "description": RadarSettings.description,
            "metadata": RadarSettings.metadata,
            "sessionId": RadarSettings.sessionId,
            "deviceType": RadarUtils.deviceType,
            "deviceMake": RadarUtils.deviceMake,
            "sdkVersion": RadarUtils.sdkVersion,
            "deviceModel": RadarUtils.deviceModel,
            "deviceOS": await RadarUtils.deviceOS,
            "country": RadarUtils.country,
            "timeZoneOffset": RadarUtils.timeZoneOffset,
            "lang": RadarSettings.userLanguage,
            "fraudPayload": fraudPayload,
            "appId": Bundle.main.bundleIdentifier,
            "appName": Bundle.main.object(forInfoDictionaryKey: "CFBundleName"),
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersion"),
            "appBuild": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion"),
            "xPlatformType": RadarSettings.xPlatform ? RadarSettings.xPlatformSDKType : "Native",
            "xPlatformSDKVersion": RadarSettings.xPlatform ? RadarSettings.xPlatformSDKVersion : nil,
        ]
        
        let (data, response) = try await apiHelper.radarVerifiedRequest(method: "POST", url: "reveal/risk", body: params)

        guard let result = RadarRevealRiskToken.fromData(data) else {
            throw APIError(data: data, response: response, message: "Failed to parse reveal risk response")
        }
        return result
    }

    // TODO: implement rest of RadarAPIClient
}
