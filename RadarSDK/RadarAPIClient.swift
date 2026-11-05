//
//  RadarAPIClient.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
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
        if code == 400 {
            throw RadarError(status: .errorBadRequest, message: "Bad request")
        } else if code == 401 {
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
        preparedPayload: RadarPreparedFraudPayload,
        useSecondaryVerifiedHost: Bool
    ) async throws -> RadarRevealRiskToken {
        let installId = RadarSettings.installId

        let params: [String: Any?] = [
            "installId": installId,
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
            "appId": Bundle.main.bundleIdentifier,
            "appName": Bundle.main.object(forInfoDictionaryKey: "CFBundleName"),
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString"),
            "appBuild": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion"),
            "xPlatformType": RadarSettings.xPlatform ? RadarSettings.xPlatformSDKType : "Native",
            "xPlatformSDKVersion": RadarSettings.xPlatform ? RadarSettings.xPlatformSDKVersion : nil,
        ]

        let (data, response) = try await apiHelper.radarRequest(
            host: useSecondaryVerifiedHost ? .verifiedSecondaryHost : .verifiedHost,
            method: "POST",
            url: "reveal/risk",
            body: params,
            prepareRequest: { request in
                try preparedPayload.prepareRequest(request)
            }
        )

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
            "notificationAuthorization": String(RadarState.shared.notificationPermissionGranted),
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

    // Swift port of -[RadarAPIClient searchBeaconsNear:radius:limit:completionHandler:] in
    // RadarAPIClient.m, used by RadarNearbyBeaconSearch. The Objective-C version is still used by
    // trackVerified, trackOnce, and background tracking. Keep the request and the beaconUUIDs side
    // effect in sync with it until those callers move to Swift, then delete the Objective-C version.
    struct SearchBeaconsResponse {
        let beacons: [RadarBeaconSwift]
        let uuids: [String]
    }

    func searchBeacons(near location: CLLocation, radius: Int, limit: Int) async throws -> SearchBeaconsResponse {
        let query = [
            URLQueryItem(
                name: "near",
                value: String(format: "%.06f,%.06f", location.coordinate.latitude, location.coordinate.longitude)
            ),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "limit", value: "\(min(limit, 100))"),
            // Only iBeacons. CoreLocation can only range iBeacons, and Eddystone and Radar UWB
            // beacons have no uuid/major/minor, so they can't be decoded as RadarBeaconSwift. The
            // server filters by type before applying `limit`, so the limit counts only iBeacons.
            URLQueryItem(name: "type", value: "ibeacon"),
        ]

        let (data, response) = try await apiHelper.radarRequest(method: "GET", url: "search/beacons", query: query)

        try assertResponseCode(response.statusCode)

        guard let res = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError(data: data, response: response, message: "Failed to parse search beacons response")
        }

        // Decode each beacon on its own, so one that can't be decoded doesn't drop the rest.
        let beacons = (res["beacons"] as? [[String: Any]] ?? []).compactMap { dict -> RadarBeaconSwift? in
            guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
            return try? JSONDecoder().decode(RadarBeaconSwift.self, from: jsonData)
        }

        var uuids: [String] = []
        if let meta = res["meta"] as? [String: Any],
            let settings = meta["settings"] as? [String: Any],
            let beaconSettings = settings["beacons"] as? [String: Any]
        {
            uuids = (beaconSettings["uuids"] as? [String] ?? []).filter { !$0.isEmpty }
            RadarSettings.beaconUUIDs = uuids
        }

        return SearchBeaconsResponse(beacons: beacons, uuids: uuids)
    }

    // TODO: implement rest of RadarAPIClient
}

extension RadarAPIClient {
    func validateAddress(_ request: RadarValidateAddressRequest) async throws -> RadarValidateAddressResponse {
        var fields = [
            ("countryCode", request.countryCode),
            ("stateCode", request.stateCode),
            ("city", request.city),
            ("postalCode", request.postalCode),
        ]
        switch request.line {
        case let .streetAndNumber(street, number):
            fields += [("street", street), ("number", number)]
        case let .label(label):
            fields.append(("addressLabel", label))
        }

        if let (name, _) = fields.first(where: { $0.1.isEmpty }) {
            throw RadarError(status: .errorBadRequest, message: "validateAddress() requires \(name)")
        }

        var query = fields.map { URLQueryItem(name: $0.0, value: $0.1) }
        if let unit = request.unit, !unit.isEmpty {
            query.append(URLQueryItem(name: "unit", value: unit))
        }

        let (data, response) = try await apiHelper.radarRequest(method: "GET", url: "addresses/validate", query: query)

        try assertResponseCode(response.statusCode)

        guard let res = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let addressObj = res["address"],
            let address = RadarAddress(from: addressObj),
            let result = res["result"] as? [String: Any],
            let verificationStatus = result["verificationStatus"] as? String
        else {
            throw APIError(data: data, response: response, message: "Failed to parse validate address response")
        }

        return RadarValidateAddressResponse(
            address: address,
            verificationStatus: RadarAddress.addressVerificationStatus(for: verificationStatus)
        )
    }
}

extension RadarAPIClient {
    /// Returns nil when the project doesn't enrich addresses, which the API answers with 204 and no body.
    func selectAutocompleteResult(_ resultId: String) async throws -> RadarAutocompleteEnrichedAddress? {
        guard !resultId.isEmpty else {
            throw RadarError(status: .errorBadRequest, message: "selectAddress() requires an address with a resultId")
        }

        let (data, response) = try await apiHelper.radarRequest(
            method: "POST", url: "search/autocomplete/select", body: ["resultId": resultId])

        try assertResponseCode(response.statusCode)

        guard !data.isEmpty else {
            return nil
        }
        let res = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return RadarAutocompleteEnrichedAddress(object: res?["address"])
    }
}

/// The fields `/v1/addresses/validate` takes. The API accepts a street and number or an address label, but not both.
struct RadarValidateAddressRequest {
    enum Line {
        case streetAndNumber(street: String, number: String)
        case label(String)
    }

    let line: Line
    let unit: String?
    let city: String
    let stateCode: String
    let postalCode: String
    let countryCode: String

    init(line: Line, unit: String?, city: String, stateCode: String, postalCode: String, countryCode: String) {
        self.line = line
        self.unit = unit
        self.city = city
        self.stateCode = stateCode
        self.postalCode = postalCode
        self.countryCode = countryCode
    }

    /// Uses the address's street and number when both are set, and its label otherwise. Addresses from search and
    /// geocoding have all three.
    init(address: RadarAddress) {
        let line: Line
        if let street = address.street, let number = address.number, !street.isEmpty, !number.isEmpty {
            line = .streetAndNumber(street: street, number: number)
        } else {
            line = .label(address.addressLabel ?? "")
        }
        self.init(
            line: line,
            unit: address.unit,
            city: address.city ?? "",
            stateCode: address.stateCode ?? "",
            postalCode: address.postalCode ?? "",
            countryCode: address.countryCode ?? ""
        )
    }
}

struct RadarValidateAddressResponse: @unchecked Sendable {
    let address: RadarAddress
    let verificationStatus: RadarAddressVerificationStatus
}
