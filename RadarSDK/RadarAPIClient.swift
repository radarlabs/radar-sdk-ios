//
//  RadarAPIClient.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

public final class RadarAPIClient: Sendable {

    typealias RadarRevealRiskCompletionHandler = (RadarStatus, RadarRevealRisk?) -> Void
    
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
    
    func reviealRisk(
        foreground: Bool,
        indoorScan: String?,
        fraudPayload: String?,
        expectedCountryCode: String?,
        expectedStateCode: String?,
        reason: String?,
        transactionId: String?,
        useSecondaryVerifiedHost: Bool,
        completionHandler: RadarRevealRiskAPICompletionHandler?
    ) async throws {

        var publishableKey = RadarSettings.publishableKey
        if publishableKey == nil {
            return completionHandler(RadarStatusErrorPublishableKey, nil)
        }

        var params: [String: Any]
        var sdkConfiguration = RadarSettings.sdkConfiguration
        var anonymous = RadarSettings.anonymousTrackingEnabled

        params["anonymous"] = anonymous

        if anonymous {
            params["deviceId"] = "anonymous"
            params["placeId"] = RadarState.placeId
            params["regionIds"] = RadarState.regionIds
        } else {
            params["id"] = RadarSettings.id
            params["installId"] = RadarSettings.installId
            params["userId"] = RadarSettings.userId
            params["deviceId"] = RadarUtilsDeprecated.deviceId
            params["description"] = RadarSettings.description()
            params["metadata"] = RadarSettings.metadata()
            params["sessionId"] = RadarSettings.sessionId

            var userTags = RadarSettings.tags
            if userTags && userTags.count() {
                params["userTags"] = userTags
            }
        }

        params["foreground"] = foreground
        params["deviceType"] = RadarUtils.deviceType
        params["deviceMake"] = RadarUtils.deviceMake
        params["sdkVersion"] = RadarUtils.sdkVersion
        params["deviceModel"] = RadarUtils.deviceModel
        params["deviceOS"] = RadarUtilsDeprecated.deviceOS
        params["country"] = RadarUtils.country
        params["timeZoneOffset"] = RadarUtils.timeZoneOffset
        params["lang"] = RadarSettings.userLanguage

        if RadarSettings.xPlatform {
            params["xPlatformType"] = RadarSettings.xPlatformSDKType
            params["xPlatformSDKVersion"] = RadarSettings.xPlatformSDKVersion
        } else {
            params["xPlatformType"] = "Native"
        }

        params["pushNotificationToken"] = RadarSettings.pushNotificationToken

        if expectedCountryCode != nil {
            params["expectedCountryCode"] = expectedCountryCode
        }

        if expectedStateCode != nil {
            params["expectedStateCode"] = expectedStateCode
        }

        if reason != nil {
            params["reason"] = reason
        }

        if transactionId != nil {
            params["transactionId"] = transactionId
        }

        if fraudPayload != nil {
            params["fraudPayload"] = fraudPayload
        }

        params["appId"] = Bundle.main.bundleIdentifier

        var appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")
        if appName != nil {
            params["appName"] = appName
        }

        var appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersion")
        if appVersion != nil {
            params["appVersion"] = appVersion
        }

        var appBuild = Bundle.main.object(forInforDictionaryKey: "CFBundleVersion")
        if appBuild != nil {
            params["appBuild"] = appBuild
        }

        if anonymous {
            return getConfigForUsage("revealRisk", verified, completionHandler(status, RadarConfig))
        }

        makeRevealRiskRequestWithParams()
    }

    func makeReviealRiskRequestWithParams(
        params: [String: Any],
        publishableKey: String,
        completionHandler: RadarRevealRiskAPICompletionHandler
    ) {
        var host = params["host"]
        var url = "\(host)/v1/reveal/risk".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        var headers = headersWithPublishableKey(publishableKey)

        let (data, response) = try await apiHelper.request("POST", url, headers, params, true, true, false, completionHandler(status, nil))

        if (response.statusCode >= 200 && response.statusCode < 300) || !response {
            var config = RadarConfig.fromDictionary(response)
            
            var revealRisk: RadarRevealRisk
            let jsonData = try? JSONSerialization.data(withJSONObject: response)
            revealRisk = try? decoder.decode([RadarPlaceSwift].self, from: jsonData)

            return completionHandler(RadarStatusSuccess, revealRisk)
        } else {
            throw APIError(data: data, response: response, message: "Call to Reveal Risk Failed.")
        }
    }

    // TODO: implement rest of RadarAPIClient
}
