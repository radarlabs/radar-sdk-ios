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
    
    private func assertResponseCode(_ code: Int) throws {
        if code == 401 {
            throw RadarError(status: .errorUnauthorized, message: "Unauthorized")
        } else if code == 402 {
            throw RadarError(status: .errorPaymentRequired, message: "Payment required")
        } else if code == 403 {
            throw RadarError(status: .errorForbidden, message: "Forbidden")
        } else if code == 404 {
            throw RadarError(status: .errorNotFound, message: "Not found")
        } else if code == 429 {
            throw RadarError(status: .errorRateLimit, message: "Ratelimited")
        } else if code >= 500 && code <= 599 {
            throw RadarError(status: .errorServer, message: "Server error")
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
            throw RadarError(status: .errorServer, message: "Failed to send logs")
        }
    }

    func revealRisk(
        fraudPayload: String,
        useSecondaryVerifiedHost: Bool,
    ) async throws -> RadarRevealRiskToken {
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
            "deviceOS": await RadarUtils.deviceOSVersion,
            "country": RadarUtils.country,
            "timeZoneOffset": RadarUtils.timeZoneOffset,
            "lang": RadarSettings.userLanguage,
            "fraudPayload": fraudPayload,
            "appId": Bundle.main.bundleIdentifier,
            "appName": Bundle.main.object(forInfoDictionaryKey: "CFBundleName"),
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString"),
            "appBuild": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion"),
            "xPlatformType": RadarSettings.xPlatform ? RadarSettings.xPlatformSDKType : "Native",
            "xPlatformSDKVersion": RadarSettings.xPlatform ? RadarSettings.xPlatformSDKVersion : nil,
        ]

        let (data, response) = try await apiHelper.radarRequest(host: .verifiedHost, method: "POST", url: "reveal/risk", body: params)
        
        try assertResponseCode(response.statusCode)

        guard let result = RadarRevealRiskToken.fromData(data) else {
            throw APIError(data: data, response: response, message: "Failed to parse reveal risk response")
        }
        return result
    }

    func getConfig(usage: String?, host: RadarAPIHelper.RadarHost) async throws -> RadarConfig? {
        let params: [URLQueryItem] = [
            "installId": RadarSettings.installId,
            "sessionId": RadarSettings.sessionId,
            "id": RadarSettings.id,
            "locationAuthorization": RadarUtils.locationAuthorization,
            "locationAccuracyAuthorization": RadarUtils.locationAccuracyAuthorization,
            "notificationAuthorization": String(RadarState().notificationPermissionGranted),
            "usage": usage,
            "verified": String(host == .verifiedHost || host == .verifiedSecondaryHost),
            "clientSdkConfiguration": RadarUtils.dictionaryToJson(RadarSettings.clientSdkConfiguration),
        ].compactMap { key, value in
            value != nil ? URLQueryItem(name: key, value: value) : nil
        }
        
        let (data, response) = try await apiHelper.radarRequest(host: host, method: "GET", url: "config")
        
        try assertResponseCode(response.statusCode)
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return RadarConfig.from(dictionary: json)
    }
    
    
    
    // TODO: implement rest of RadarAPIClient
}
