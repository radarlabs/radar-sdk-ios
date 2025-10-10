//
//  RadarAPIClient.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
@objc(RadarAPIClientSwift) @objcMembers
final class RadarAPIClient: NSObject, Sendable {
    
    public static let shared = RadarAPIClient()
    
    let apiHelper = RadarApiHelper()
    
    // MARK: - getAsset
    func getAsset(url: String) async throws -> Data {
        let data = if (url.starts(with: "http")) {
            try await apiHelper.request(method: .get, url: url)
        } else {
            try await apiHelper.radarRequest(method: .get, url: "assets/\(url)")
        }
        return data
    }
    
    // MARK: - getOfflineData
    @objc(RadarAPIClient_OfflineData) @objcMembers
    class OfflineData: NSObject {
        let newGeofences: [RadarGeofence]
        let removeGeofences: [String]
        let defaultTrackingOptions: RadarTrackingOptions?
        let onTripTrackingOptions: RadarTrackingOptions?
        let inGeofenceTrackingOptions: RadarTrackingOptions?
        let inGeofenceTrackingTags: [String]
        
        init(newGeofences: [RadarGeofence], removeGeofences: [String], defaultTrackingOptions: RadarTrackingOptions?, onTripTrackingOptions: RadarTrackingOptions?, inGeofenceTrackingOptions: RadarTrackingOptions?, inGeofenceTrackingTags: [String]) {
            self.newGeofences = newGeofences
            self.removeGeofences = removeGeofences
            self.defaultTrackingOptions = defaultTrackingOptions
            self.onTripTrackingOptions = onTripTrackingOptions
            self.inGeofenceTrackingOptions = inGeofenceTrackingOptions
            self.inGeofenceTrackingTags = inGeofenceTrackingTags
        }
    }
    @objc(RadarAPIClient_PostConfigResponse) @objcMembers
    class PostConfigResponse: NSObject {
        let status: RadarStatus
        let remoteTrackingOptions: RadarTrackingOptions?
        let remoteSdkConfiguration: RadarSdkConfiguration?
        let verificationSettings: RadarConfig?
        let offlineData: OfflineData?
        
        init(status: RadarStatus, remoteTrackingOptions: RadarTrackingOptions? = nil, remoteSdkConfiguration: RadarSdkConfiguration? = nil, verificationSettings: RadarConfig? = nil, offlineData: OfflineData? = nil) {
            self.status = status
            self.remoteTrackingOptions = remoteTrackingOptions
            self.remoteSdkConfiguration = remoteSdkConfiguration
            self.verificationSettings = verificationSettings
            self.offlineData = offlineData
        }
    }
    func postConfig(usage: String) async -> PostConfigResponse {
        guard let bridge = RadarSwiftBridgeHolder.shared else {
            return PostConfigResponse(status: .errorPublishableKey)
        }
        let offlineManager = bridge.RadarOfflineManager()
        
        do {
            let body: [String: Any?] = [
                "installId": RadarSettings.installId,
                "sessionId": RadarSettings.sessionId,
                "id": RadarSettings.id,
                "locationAuthorization": RadarUtils.locationAuthorization,
                "locationAccuracyAuthorization": RadarUtils.locationAccuracyAuthorization,
                "usage": usage,
                "clientSdkConfiguration": RadarSettings.clientSdkConfiguration,
                "offlineDataRequest": offlineManager.getOfflineDataRequest() ?? ""
            ]
            RadarLogger.shared.debug("📍 Radar API request | POST \(UserDefaults.standard.string(forKey: "radar-host") ?? "")/config | \(body.toJSONString())")
            
            let data = try await apiHelper.radarRequest(method: .post, url: "config", body: body)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            
            RadarLogger.shared.debug("📍 Radar API response | POST \(UserDefaults.standard.string(forKey: "radar-host") ?? "")/config | \(json.toJSONString())")
            
            let trackingOptions = RadarTrackingOptions.init(from: json["trackingOptions"] as? [String: Any])
            let sdkConfiguration = RadarSdkConfiguration.init(from: json["sdkConfiguration"] as? [String: Any])
            let verificationSettings = RadarConfig.fromDictionary(json["verificationSettings"] as? [String: Any])
            
            var offlineData: OfflineData? = nil
            if let offlineDataJSON = json["offlineData"] as? [String: Any] {
                let newGeofences = bridge.RadarGeofences(from: offlineDataJSON["newGeofences"] ?? []) ?? []
                let removeGeofences: [String] = (offlineDataJSON["removeGeofences"] as? [String]) ?? []
                let defaultTrackingOptions = RadarTrackingOptions.init(from: offlineDataJSON["defaultTrackingOptions"] as? [String: Any] ?? [:])
                let onTripTrackingOptions = RadarTrackingOptions.init(from: offlineDataJSON["onTripTrackingOptions"] as? [String: Any] ?? [:])
                let inGeofenceTrackingOptions = RadarTrackingOptions.init(from: offlineDataJSON["inGeofenceTrackingOptions"] as? [String: Any] ?? [:])
                let inGeofenceTrackingTags: [String] = (offlineDataJSON["inGeofenceTrackingTags"] as? [String]) ?? []
                
                offlineData = OfflineData(
                    newGeofences: newGeofences,
                    removeGeofences: removeGeofences,
                    defaultTrackingOptions: defaultTrackingOptions,
                    onTripTrackingOptions: onTripTrackingOptions,
                    inGeofenceTrackingOptions: inGeofenceTrackingOptions,
                    inGeofenceTrackingTags: inGeofenceTrackingTags
                )
            }
            
            return PostConfigResponse(status: .success, remoteTrackingOptions: trackingOptions, remoteSdkConfiguration: sdkConfiguration, verificationSettings: verificationSettings, offlineData: offlineData)
        } catch let error as RadarApiHelper.HTTPError {
            let dataString = String(data: error.data!, encoding: .utf8) ?? "<binary data>"
            RadarLogger.shared.debug("📍 Radar API response | POST \(UserDefaults.standard.string(forKey: "radar-host") ?? "")/config | HTTPError: \(dataString)")
            return PostConfigResponse(status: apiHelper.HTTPErrorToRadarStatus(error))
        } catch { // JSON parse error
            RadarLogger.shared.debug("📍 Radar API response | POST \(UserDefaults.standard.string(forKey: "radar-host") ?? "")/config | \(error.localizedDescription)")
            return PostConfigResponse(status: RadarStatus.errorUnknown)
        }
    }
    
    // TODO: implement rest of RadarAPIClient
}
