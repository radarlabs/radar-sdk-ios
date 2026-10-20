//
//  RadarAPIClient.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

// swiftlint:disable file_length

import Foundation
import UIKit

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

        var regionCenter: RadarCoordinate?
        var regionRadius: Double?
        if let regionDict = res["region"] as? [String: Any],
            let lat = regionDict["latitude"] as? Double,
            let lng = regionDict["longitude"] as? Double,
            let radius = regionDict["radius"] as? Double,
            radius > 0
        {
            regionCenter = RadarCoordinate(latitude: lat, longitude: lng)
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

        let (_, response) = try await apiHelper.radarRequest(method: "POST", url: "logs", body: body)

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

        let (data, response) = try await apiHelper.radarRequest(host: host, method: "GET", url: "config", query: params)

        try assertResponseCode(response.statusCode)

        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return RadarConfig.from(dictionary: json)
    }

    func searchBeacons(near: CLLocation, radius: Int, limit: Int) async throws -> ([RadarBeaconSwift], [String]) {
        let sixDecimal = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(6))
        let params: [URLQueryItem] = [
            "near": "\(near.coordinate.latitude.formatted(sixDecimal)),\(near.coordinate.longitude.formatted(sixDecimal))",
            "radius": String(radius),
            "limit": String(min(limit, 100)),
        ].compactMap { key, value in
            value != nil ? URLQueryItem(name: key, value: value) : nil
        }

        let (data, response) = try await apiHelper.radarRequest(method: "GET", url: "search/beacons", query: params)

        try assertResponseCode(response.statusCode)

        let json = try JSONDecoder().decode(SearchBeaconResponse.self, from: data)

        return (json.beacons, json.meta.settings.beacons.uuids)
    }

    // TODO: implement rest of RadarAPIClient
}

// MARK: - Track helpers

extension RadarAPIClient {

    // Swift port of the verified path of `trackWithLocation:` in RadarAPIClient.m. Verified tracks
    // are never batched or replayed, so the request is always sent directly.
    // swiftlint:disable:next function_parameter_count
    func trackVerified(
        location: CLLocation,
        stopped: Bool,
        foreground: Bool,
        source: RadarLocationSource,
        beacons: [RadarBeacon]?,
        fraudPayload: String,
        expectedCountryCode: String?,
        expectedStateCode: String?,
        expectedAddress: String?,
        reason: String?,
        transactionId: String?,
        revealRiskId: String?,
        useSecondaryVerifiedHost: Bool,
    ) async throws -> RadarTrackResponse {
        guard RadarSettings.publishableKey != nil else {
            throw RadarError(status: .errorPublishableKey)
        }

        let options = Radar.getTrackingOptions()
        var params = await trackParams(location: location, stopped: stopped, foreground: foreground, source: source, options: options)
        if let beacons {
            params["beacons"] = RadarBeacon.array(for: beacons)
        }

        params["verified"] = true
        params["expectedCountryCode"] = expectedCountryCode
        params["expectedStateCode"] = expectedStateCode
        params["expectedAddress"] = expectedAddress
        params["reason"] = reason
        params["transactionId"] = transactionId
        params["revealRiskId"] = revealRiskId
        params["fraudPayload"] = fraudPayload

        let locationMetadata = await trackLocationMetadata(location: location, options: options, params: &params)
        if !locationMetadata.isEmpty {
            params["locationMetadata"] = locationMetadata
        }

        // Include stored altitudeAdjustments from previous track responses
        if let altitudeAdjustments = RadarSwift.bridge?.altitudeAdjustments(), !altitudeAdjustments.isEmpty {
            params["altitudeAdjustments"] = altitudeAdjustments
        }

        if RadarSettings.anonymousTrackingEnabled {
            Task {
                _ = try? await self.getConfig(usage: "track", host: .verifiedHost)
            }
        }

        // Matches RadarNotificationUtils.getNotificationDiff, which skips under XCTest.
        let notificationsDelivered: [[String: Sendable]] =
            NSClassFromString("XCTestCase") == nil ? await RadarNotificationHelper.shared.getDeliveredNotifications() : []
        if !notificationsDelivered.isEmpty {
            params["notificationDiff"] = notificationsDelivered
        }

        let host: RadarAPIHelper.RadarHost = useSecondaryVerifiedHost ? .verifiedSecondaryHost : .verifiedHost

        let res: [String: Any]
        do {
            res = try await sendTrackRequest(host: host, params: params)
        } catch {
            handleTrackFailure(
                status: error.status,
                params: params,
                notificationsDelivered: notificationsDelivered,
                options: options,
                location: location,
                storeFailedStoppedLocation: stopped && !(source == .foregroundLocation || source == .manualLocation)
            )
            throw error
        }

        return try await handleTrackResponse(res, location: location, locationMetadata: locationMetadata)
    }

    private func sendTrackRequest(host: RadarAPIHelper.RadarHost, params: [String: Any]) async throws(RadarError) -> [String: Any] {
        do {
            let (data, response) = try await apiHelper.radarRequest(host: host, method: "POST", url: "track", body: params)
            try assertResponseCode(response.statusCode)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw RadarError(status: .errorServer, message: "Failed to parse track response")
            }
            return json
        } catch let error as RadarError {
            throw error
        } catch is URLError {
            throw RadarError(status: .errorNetwork)
        } catch {
            throw RadarError(status: .errorUnknown)
        }
    }

    private func trackParams(
        location: CLLocation,
        stopped: Bool,
        foreground: Bool,
        source: RadarLocationSource,
        options: RadarTrackingOptions
    ) async -> [String: Any] {
        var params = await trackIdentityParams()
        params.merge(trackLocationParams(location)) { $1 }
        let nowMs = Int(Date().timeIntervalSince1970 * 1000)
        let locationMs = Int(location.timestamp.timeIntervalSince1970 * 1000)
        if RadarSettings.sdkConfiguration?.useForegroundLocationUpdatedAtMsDiff == true || !foreground {
            params["updatedAtMsDiff"] = nowMs - locationMs
        }
        params["locationMs"] = locationMs
        params["foreground"] = foreground
        params["stopped"] = stopped
        params["replayed"] = false
        params["deviceType"] = RadarUtils.deviceType
        params["deviceMake"] = RadarUtils.deviceMake
        params["sdkVersion"] = RadarUtils.sdkVersion
        params["deviceModel"] = RadarUtils.deviceModel
        params["deviceOS"] = await RadarUtils.deviceOSVersion
        params["country"] = RadarUtils.country
        params["timeZoneOffset"] = RadarUtils.timeZoneOffset
        params["source"] = Radar.stringForLocationSource(source)
        params["lang"] = RadarSettings.userLanguage
        if RadarSettings.xPlatform {
            params["xPlatformType"] = RadarSettings.xPlatformSDKType
            params["xPlatformSDKVersion"] = RadarSettings.xPlatformSDKVersion
        } else {
            params["xPlatformType"] = "Native"
        }
        params["pushNotificationToken"] = RadarSettings.pushNotificationToken
        params["locationExtensionToken"] = RadarSettings.locationExtensionToken

        if let tripOptions = Radar.getTripOptions() {
            params["tripOptions"] = trackTripParams(tripOptions)
        }
        if options.syncGeofences {
            params["nearbyGeofences"] = true
        }
        params["locationAuthorization"] = RadarUtils.locationAuthorization
        params["locationAccuracyAuthorization"] = RadarUtils.locationAccuracyAuthorization
        params["notificationAuthorization"] = RadarState().notificationPermissionGranted

        params["trackingOptions"] = options.dictionaryValue()

        params["usingRemoteTrackingOptions"] = RadarSettings.tracking && RadarSettings.remoteTrackingOptions != nil

        params["appId"] = Bundle.main.bundleIdentifier
        params["appName"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")
        params["appVersion"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        params["appBuild"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")

        return params
    }

    private func trackLocationParams(_ location: CLLocation) -> [String: Any] {
        var params: [String: Any] = [:]
        params["latitude"] = location.coordinate.latitude
        params["longitude"] = location.coordinate.longitude
        params["accuracy"] = location.horizontalAccuracy <= 0 ? 1 : location.horizontalAccuracy
        params["altitude"] = location.altitude
        params["verticalAccuracy"] = location.verticalAccuracy
        params["speed"] = location.speed
        params["speedAccuracy"] = location.speedAccuracy
        params["course"] = location.course
        params["courseAccuracy"] = location.courseAccuracy
        params["floorLevel"] = location.floor?.level
        return params
    }

    private func trackIdentityParams() async -> [String: Any] {
        var params: [String: Any] = [:]
        let anonymous = RadarSettings.anonymousTrackingEnabled
        params["anonymous"] = anonymous
        if anonymous {
            params["deviceId"] = "anonymous"
            params["geofenceIds"] = RadarSwift.bridge?.geofenceIds()
            params["placeId"] = RadarSwift.bridge?.placeId()
            params["regionIds"] = RadarSwift.bridge?.regionIds()
            params["beaconIds"] = RadarSwift.bridge?.beaconIds()
        } else {
            params["id"] = RadarSettings.id
            params["installId"] = RadarSettings.installId
            params["userId"] = RadarSettings.userId
            params["deviceId"] = await RadarUtils.deviceId
            params["description"] = RadarSettings.description
            params["metadata"] = RadarSettings.metadata
            let userTags = RadarSettings.tags
            if !userTags.isEmpty {
                params["userTags"] = userTags
            }
            params["sessionId"] = RadarSettings.sessionId
        }
        return params
    }

    private func trackTripParams(_ tripOptions: RadarTripOptions) -> [String: Any] {
        var tripParams: [String: Any] = [:]
        tripParams["version"] = "2"
        if !tripOptions.externalId.isEmpty {
            tripParams["externalId"] = tripOptions.externalId
        }
        tripParams["metadata"] = tripOptions.metadata
        tripParams["destinationGeofenceTag"] = tripOptions.destinationGeofenceTag
        tripParams["destinationGeofenceExternalId"] = tripOptions.destinationGeofenceExternalId
        tripParams["mode"] = Radar.stringForMode(tripOptions.mode)
        return tripParams
    }

    private func trackLocationMetadata(
        location: CLLocation,
        options: RadarTrackingOptions,
        params: inout [String: Any]
    ) async -> [String: Any] {
        var locationMetadata: [String: Any] = [:]
        if options.useMotion {
            locationMetadata["motionActivityData"] = RadarSwift.bridge?.lastMotionActivityData()
            locationMetadata["heading"] = RadarState().lastHeadingData
            locationMetadata["speed"] = location.speed
            locationMetadata["speedAccuracy"] = location.speedAccuracy
            locationMetadata["course"] = location.course
            locationMetadata["courseAccuracy"] = location.courseAccuracy
            locationMetadata["battery"] = await MainActor.run { UIDevice.current.batteryLevel }
            locationMetadata["altitude"] = location.altitude
            locationMetadata["ellipsoidalAltitude"] = location.ellipsoidalAltitude
            locationMetadata["isProducedByAccessory"] = location.sourceInformation?.isProducedByAccessory ?? false
            locationMetadata["isSimulatedBySoftware"] = location.sourceInformation?.isSimulatedBySoftware ?? false
        }

        if options.usePressure {
            let pressureDict = RadarSwift.bridge?.lastRelativeAltitudeData()
            locationMetadata["altitude"] = location.altitude
            locationMetadata["floor"] = location.floor?.level ?? 0
            locationMetadata["pressureHPa"] = pressureDict
            params["motionAuthorization"] = RadarSwift.bridge?.motionAuthorizationString()
            if let pressureDict {
                let pressure = pressureDict["pressure"] ?? "nil"
                let relAlt = pressureDict["relativeAltitude"] ?? "nil"
                RadarLogger.shared.debug("Including pressure metadata: pressure=\(pressure) hPa, relative=\(relAlt) m")
            } else {
                RadarLogger.shared.log(level: .warning, message: "usePressure enabled but no recent pressure data available; sending without pressureHPa")
            }
        }

        return locationMetadata
    }

    // swiftlint:disable:next function_parameter_count
    private func handleTrackFailure(
        status: RadarStatus,
        params: [String: Any],
        notificationsDelivered: [[String: Sendable]],
        options: RadarTrackingOptions,
        location: CLLocation,
        storeFailedStoppedLocation: Bool
    ) {
        if options.replay == .all {
            // create a copy of params that we can use to write to the buffer in case of request failure
            var bufferParams = params
            bufferParams["replayed"] = true

            // Skip notification removal under XCTest, matching RadarAPIClient.m.
            if NSClassFromString("XCTestCase") == nil {
                let notificationDiff = notificationsDelivered.isEmpty ? nil : notificationsDelivered
                Task {
                    await RadarNotificationHelper.shared.removeRegisteredNotifications(notifications: notificationDiff)
                }
            }

            RadarReplayBuffer.sharedInstance.writeNewReplayToBuffer(bufferParams)
        } else if options.replay == .stops && storeFailedStoppedLocation {
            RadarSwift.bridge?.setLastFailedStoppedLocation(location)
        }

        RadarSwift.bridge?.didFail(status: status)

        // Generate offline events on track failure (gated internally by offlineEventGenerationEnabled)
        RadarOfflineEventManager.handleTrackFailure(location)
    }

    private func handleTrackResponse(
        _ res: [String: Any],
        location: CLLocation,
        locationMetadata: [String: Any]
    ) async throws -> RadarTrackResponse {
        RadarReplayBuffer.sharedInstance.clearBuffer()
        RadarSwift.bridge?.setLastFailedStoppedLocation(nil)
        RadarLogger.flushLogs()
        RadarSettings.updateLastTrackedTime()

        let config = RadarConfig.from(dictionary: res)

        let events = res["events"].flatMap { RadarSwift.bridge?.events(fromObject: $0) }
        let user = trackUser(from: res["user"], locationMetadata: locationMetadata)
        let nearbyGeofences = res["nearbyGeofences"].flatMap { RadarSwift.bridge?.geofences(fromObject: $0) }
        let token = RadarSwift.bridge?.createVerifiedLocationToken(dict: res)

        if let inAppMessagesObj = res["inAppMessages"] {
            nonisolated(unsafe) let inAppMessages = RadarInAppMessage_Swift.fromArray(inAppMessagesObj)
            if !inAppMessages.isEmpty {
                await RadarInAppMessageManager.shared.onInAppMessageReceived(messages: inAppMessages)
            }
        }

        if let user {
            updateTrackState(from: user)
        }

        RadarOfflineEventManager.reset()

        guard let events, let user else {
            // getNotificationDiff never reports remaining notifications, so this always clears them.
            RadarLogger.shared.info("Setting 0 notifications remaining")
            RadarSwift.bridge?.setRegisteredNotifications([])
            RadarSwift.bridge?.didFail(status: .errorServer)
            throw RadarError(status: .errorServer)
        }

        RadarSettings.id = user._id
        RadarSwift.bridge?.setRadarUser(user)

        updateTrip(from: user)

        RadarSettings.userDebug = user.debug

        RadarSwift.bridge?.didUpdateLocation(location, user: user)

        if !events.isEmpty {
            RadarSwift.bridge?.didReceiveEvents(events, user: user)
        }

        if let token {
            RadarSwift.bridge?.didUpdateToken(token)
        }

        if let regions = res["nearbyBeaconRegions"] as? [[String: Any]] {
            nonisolated(unsafe) let beaconRegions = regions
            Task { @MainActor in
                RadarBeaconManagerSwift.shared.registerBeaconRegionNotifications(from: beaconRegions)
            }
        }

        return RadarTrackResponse(res: res, events: events, user: user, nearbyGeofences: nearbyGeofences, config: config, token: token)
    }

    private func trackUser(from userObj: Any?, locationMetadata: [String: Any]) -> RadarUser? {
        guard var mutableUserObj = userObj as? [String: Any] else {
            return nil
        }
        mutableUserObj["metadata"] = locationMetadata

        // Extract and store altitudeAdjustments from user object
        if let altitudeAdjustments = mutableUserObj["altitudeAdjustments"] as? [[AnyHashable: Any]] {
            RadarSwift.bridge?.setAltitudeAdjustments(altitudeAdjustments)
            RadarLogger.shared.debug("Stored \(altitudeAdjustments.count) altitude adjustments from track response")
        } else {
            RadarSwift.bridge?.setAltitudeAdjustments(nil)
        }

        return RadarSwift.bridge?.createUser(dict: mutableUserObj)
    }

    private func updateTrip(from user: RadarUser) {
        // Update local trip state from server response
        if let trip = user.trip {
            // Update local trip with latest state (ETAs, leg statuses, etc.)
            RadarSettings.trip = trip
        } else if RadarSettings.tripOptions != nil {
            // Trip ended server-side - restore previous tracking options
            RadarSwift.bridge?.restartPreviousTrackingOptions()
            RadarSettings.tripOptions = nil
            RadarSettings.trip = nil
        }
    }

    private func updateTrackState(from user: RadarUser) {
        let inGeofences = !(user.geofences?.isEmpty ?? true)
        let atPlace = user.place != nil
        RadarSwift.bridge?.setCanExit(inGeofences || atPlace)

        RadarSwift.bridge?.setGeofenceIds(user.geofences?.map(\._id) ?? [])
        RadarSwift.bridge?.setPlaceId(user.place?._id)
        RadarSwift.bridge?.setRegionIds([user.country, user.state, user.dma, user.postalCode].compactMap { $0?._id })
        RadarSwift.bridge?.setBeaconIds(user.beacons?.compactMap(\._id) ?? [])
    }
}
