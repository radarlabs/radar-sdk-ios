//
//  RadarAPIClient.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

extension CLLocation {
    func commaSeparatedString(format: String = "%.6f") -> String {
        return "\(String(format: format, coordinate.latitude)),\(String(format: format, coordinate.longitude))"
    }
}

@available(iOS 13.0, *)
public final class RadarAPIClient {
    
    struct APIError: Error {
        let data: Data
        let response: URLResponse
        let message: String
    }
    
    nonisolated(unsafe)
    public static let shared = RadarAPIClient()
    
    let apiHelper: RadarApiHelper
    let radarState: RadarState
    
    init(apiHelper: RadarApiHelper? = nil, radarState: RadarState? = nil) {
        self.apiHelper = apiHelper ?? RadarApiHelper()
        self.radarState = radarState ?? RadarState.shared
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
    
    // TODO: implement rest of RadarAPIClient
    struct GetDistanceResponse: Codable {
        let routes: RadarRoutes
    }
    func getDistance(origin: CLLocation, destination: CLLocation, modes: RadarRouteMode, units: RadarRouteUnits, points: Int) async throws -> RadarRoutes {
        
        let query = [
            "origin": origin.commaSeparatedString(),
            "destination": destination.commaSeparatedString(),
            "modes": modes.commaSeparatedString(),
            "units": units.toString(),
            "geometryPoints": "\(points)",
            "geometry": "linestring",
        ]
        
        let (data, response) = try await apiHelper.radarRequest(method: "GET", url: "route/distance", query: query)
        
        if response.statusCode != 200 {
            throw APIError(data: data, response: response, message: "GET route/distance returned status \(response.statusCode)")
        }
        
        let result = try JSONDecoder().decode(GetDistanceResponse.self, from: data)
        return result.routes
    }
    
    // this struct is currently not used, but represents the response type of /track
    struct TrackResponse {
        let status: RadarStatus
        let events: [RadarEvent]
        let user: RadarUser
        let nearbyGeofences: [RadarGeofence]
        let config: [String: Any] // RadarConfig
        let token: RadarVerifiedLocationToken
    }
    /**
     This function is different to the Objective C function in that it doesn't modify any state upon completion, this function also only uses the standard track endpoint.
     
     This function is currently only used by mock tracking.
     */
    func track(location: CLLocation,
               stopped: Bool,
               foreground: Bool,
               source: RadarLocationSource,
               replayed: Bool,
               beacons: [RadarBeacon]?,
               verified: Bool = false,
               fraudPayload: String? = nil,
               expectedCountryCode: String? = nil,
               expectedStateCode: String? = nil,
               reason: String? = nil,
               transactionId: String? = nil) async throws -> [String: Any] {

        let anonymous = RadarSettings.anonymousTrackingEnabled
        let sdkConfiguration = RadarSettings.sdkConfiguration
        let options = Radar.getTrackingOptions()

        // Build trip params
        var tripParams: [String: Any]? = nil
        if let tripOptions = Radar.getTripOptions() {
            var tp = [String: Any]()
            tp["version"] = "2"
            tp["externalId"] = tripOptions.externalId
            tp["metadata"] = tripOptions.metadata
            tp["destinationGeofenceTag"] = tripOptions.destinationGeofenceTag
            tp["destinationGeofenceExternalId"] = tripOptions.destinationGeofenceExternalId
            tp["mode"] = Radar.stringForMode(tripOptions.mode)
            tripParams = tp
        }

        // Build location metadata
        var locationMetadata: [String: Any]? = nil
        if options.useMotion || options.usePressure {
            var lm = [String: Any]()
            if options.useMotion {
                lm["motionActivityData"] = radarState.lastMotionActivityData
                lm["heading"] = radarState.lastHeadingData
                lm["speed"] = location.speed
                lm["speedAccuracy"] = location.speedAccuracy
                lm["course"] = location.course
                if #available(iOS 13.4, *) {
                    lm["courseAccuracy"] = location.courseAccuracy
                }
                lm["battery"] = await UIDevice.current.batteryLevel
                lm["altitude"] = location.altitude
                if #available(iOS 15, *) {
                    lm["ellipsoidalAltitude"] = location.ellipsoidalAltitude
                    lm["isProducedByAccessory"] = location.sourceInformation?.isProducedByAccessory
                    lm["isSimulatedBySoftware"] = location.sourceInformation?.isSimulatedBySoftware
                }
            }
            if options.usePressure {
                lm["altitude"] = location.altitude
                lm["floor"] = location.floor?.level
                lm["pressureHPa"] = radarState.lastRelativeAltitudeData
                if let pressureDict = radarState.lastRelativeAltitudeData {
                    let pressure = pressureDict["pressure"]
                    let relAlt = pressureDict["relativeAltitude"]
                    RadarLogger.shared.debug("Including pressure metadata: pressure=\(pressure ?? "nil") hPa, relative=\(relAlt ?? "nil") m")
                } else {
                    RadarLogger.shared.warning("usePressure enabled but no recent pressure data available; sending without pressureHPa")
                }
            }
            locationMetadata = lm
        }

        var updatedAtMsDiff: Int? = nil
        if sdkConfiguration?.useForegroundLocationUpdatedAtMsDiff == true || !foreground {
            updatedAtMsDiff = Int(Date().timeIntervalSince(location.timestamp) * 1000)
        }
        
        var courseAccuracy: CLLocationDirectionAccuracy? = nil
        if #available(iOS 13.4, *) {
            courseAccuracy = location.courseAccuracy
        }
        
        var altitudeAdjustments: [[String: Any]]? = nil
        if let adjustments = radarState.altitudeAdjustments,
           !adjustments.isEmpty {
            altitudeAdjustments = adjustments
        }
        
        let params: [String: Any] = [
            "anonymous": anonymous,
            "deviceId": anonymous ? "anonymous" : await RadarUtils.deviceId,
            // anonymous fields
            "id": anonymous ? nil : RadarSettings.id,
            "installId": anonymous ? nil : RadarSettings.installId,
            "userId": anonymous ? nil : RadarSettings.userId,
            "description": anonymous ? nil : RadarSettings.description,
            "metadata": anonymous ? nil : RadarSettings.metadata,
            "userTags": anonymous ? nil : { let t = RadarSettings.tags; return t.isEmpty ? nil : t }(),
            "sessionId": anonymous ? nil : RadarSettings.sessionId,
            // non-anonymous fields
            "geofenceIds": anonymous ? radarState.geofenceIds : nil,
            "placeId": anonymous ? radarState.placeId : nil,
            "regionIds": anonymous ? radarState.regionIds : nil,
            "beaconIds": anonymous ? radarState.beaconIds : nil,
            // common fields
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy <= 0 ? 1 : location.horizontalAccuracy,
            "altitude": location.altitude,
            "verticalAccuracy": location.verticalAccuracy,
            "speed": location.speed,
            "speedAccuracy": location.speedAccuracy,
            "course": location.course,
            "courseAccuracy": courseAccuracy,
            "floorLevel": location.floor?.level,
            "updatedAtMsDiff": updatedAtMsDiff,
            "locationMs": location.timestamp.timeIntervalSince1970 * 1000,
            "foreground": foreground,
            "stopped": stopped,
            "replayed": replayed,
            "source": Radar.stringForLocationSource(source),
            "deviceType": RadarUtils.deviceType,
            "deviceMake": RadarUtils.deviceMake,
            "sdkVersion": RadarUtils.sdkVersion,
            "deviceModel": RadarUtils.deviceModel,
            "deviceOS": await RadarUtils.deviceOS,
            "country": RadarUtils.country,
            "timeZoneOffset": RadarUtils.timeZoneOffset.doubleValue,
            "xPlatformType": RadarSettings.xPlatform ? RadarSettings.xPlatformSDKType : "Native",
            "xPlatformSDKVersion": RadarSettings.xPlatform ? RadarSettings.xPlatformSDKVersion : nil,
            "pushNotificationToken": RadarSettings.pushNotificationToken,
            "locationExtensionToken": RadarSettings.locationExtensionToken,
            "tripOptions": tripParams,
            "nearbyGeofences": options.syncGeofences,
            "trackingOptions": options.dictionaryValue(),
            "usingRemoteTrackingOptions": RadarSettings.tracking && RadarSettings.remoteTrackingOptions != nil,
            "beacons": beacons != nil ? RadarBeacon.array(for: beacons) : nil,
            "locationAuthorization": RadarUtils.locationAuthorization,
            "locationAccuracyAuthorization": RadarUtils.locationAccuracyAuthorization,
            "notificationAuthorization": radarState.notificationPermissionGranted,
            "motionAuthorization": options.usePressure ? radarState.motionAuthorizationString : nil,
            "verified": verified,
            "expectedCountryCode": verified ? expectedCountryCode : nil,
            "expectedStateCode": verified ? expectedStateCode : nil,
            "reason": verified ? reason : nil,
            "transactionId": verified ? transactionId : nil,
            "fraudPayload": verified ? fraudPayload : nil,
            "appId": Bundle.main.bundleIdentifier,
            "appName": Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            "appBuild": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            "locationMetadata": locationMetadata,
            "altitudeAdjustments": altitudeAdjustments
        ].compactMapValues { $0 }
        
        let body = try JSONSerialization.data(withJSONObject: params)
        
        let (data, response) = try await apiHelper.radarRequest(method: "POST", url: "track", body: body)
        
        guard let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError(data: data, response: response, message: "Failed to deserialize response data")
        }
        return result
    }
}
