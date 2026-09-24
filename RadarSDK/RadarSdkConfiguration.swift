//
//  RadarSdkConfiguration.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarSdkConfiguration) @objcMembers
public class RadarSdkConfiguration: NSObject {
    private let originalDict: [String: Any]?

    public let logLevel: RadarLogLevel
    public let startTrackingOnInitialize: Bool
    public let trackOnceOnAppOpen: Bool
    public let usePersistence: Bool
    public let extendFlushReplays: Bool
    public let useLogPersistence: Bool
    public let useRadarModifiedBeacon: Bool
    public let useOpenedAppConversion: Bool
    public let useForegroundLocationUpdatedAtMsDiff: Bool
    public let syncAfterSetUser: Bool
    public let useSyncRegion: Bool
    public let defaultGeofenceDwellThreshold: Int
    public let bufferGeofenceEntries: Bool
    public let bufferGeofenceExits: Bool
    public let stopDetection: Bool
    public let skipForegroundCheck: Bool
    public let useOfflineRTOUpdates: Bool
    public let offlineEventGenerationEnabled: Bool
    public let useSwiftLocationManager: Bool
    public let startUpdatesWhileInUse: Bool
    public let remoteTrackingOptions: [RadarRemoteTrackingOptions]?
    public let useSwiftVerificationManager: Bool

    public init(dict: [String: Any]?) {
        originalDict = dict
        logLevel = RadarLogLevel.from(string: dict?["logLevel"] as? String ?? "none")
        startTrackingOnInitialize = dict?["startTrackingOnInitialize"] as? Bool ?? false
        trackOnceOnAppOpen = dict?["trackOnceOnAppOpen"] as? Bool ?? false
        usePersistence = dict?["usePersistence"] as? Bool ?? false
        extendFlushReplays = dict?["extendFlushReplays"] as? Bool ?? false
        useLogPersistence = dict?["useLogPersistence"] as? Bool ?? false
        useRadarModifiedBeacon = dict?["useRadarModifiedBeacon"] as? Bool ?? false
        useOpenedAppConversion = dict?["useOpenedAppConversion"] as? Bool ?? false
        useForegroundLocationUpdatedAtMsDiff = dict?["useForegroundLocationUpdatedAtMsDiff"] as? Bool ?? false
        syncAfterSetUser = dict?["syncAfterSetUser"] as? Bool ?? false
        useSyncRegion = dict?["useSyncRegion"] as? Bool ?? false
        defaultGeofenceDwellThreshold = dict?["defaultGeofenceDwellThreshold"] as? Int ?? 0
        bufferGeofenceEntries = dict?["bufferGeofenceEntries"] as? Bool ?? true
        bufferGeofenceExits = dict?["bufferGeofenceExits"] as? Bool ?? true
        stopDetection = dict?["stopDetection"] as? Bool ?? false
        skipForegroundCheck = dict?["skipForegroundCheck"] as? Bool ?? true
        useOfflineRTOUpdates = dict?["useOfflineRTOUpdates"] as? Bool ?? false
        offlineEventGenerationEnabled = dict?["offlineEventGenerationEnabled"] as? Bool ?? false
        useSwiftLocationManager = dict?["useSwiftLocationManager"] as? Bool ?? false
        startUpdatesWhileInUse = dict?["startUpdatesWhileInUse"] as? Bool ?? false
        remoteTrackingOptions = RadarRemoteTrackingOptions.from(
            array: dict?["remoteTrackingOptions"] as? [[String: Any]]
        )
        useSwiftVerificationManager = dict?["useSwiftVerificationManager"] as? Bool ?? false
    }

    public func dictionaryValue() -> [String: Any] {
        if let originalDict {
            return originalDict
        }

        var dictionary: [String: Any] = [
            "logLevel": logLevel.toString(),
            "startTrackingOnInitialize": startTrackingOnInitialize,
            "trackOnceOnAppOpen": trackOnceOnAppOpen,
            "usePersistence": usePersistence,
            "extendFlushReplays": extendFlushReplays,
            "useLogPersistence": useLogPersistence,
            "useRadarModifiedBeacon": useRadarModifiedBeacon,
            "useOpenedAppConversion": useOpenedAppConversion,
            "useForegroundLocationUpdatedAtMsDiff": useForegroundLocationUpdatedAtMsDiff,
            "syncAfterSetUser": syncAfterSetUser,
            "useSyncRegion": useSyncRegion,
            "defaultGeofenceDwellThreshold": defaultGeofenceDwellThreshold,
            "bufferGeofenceEntries": bufferGeofenceEntries,
            "bufferGeofenceExits": bufferGeofenceExits,
            "stopDetection": stopDetection,
            "skipForegroundCheck": skipForegroundCheck,
            "useOfflineRTOUpdates": useOfflineRTOUpdates,
            "offlineEventGenerationEnabled": offlineEventGenerationEnabled,
            "useSwiftLocationManager": useSwiftLocationManager,
            "startUpdatesWhileInUse": startUpdatesWhileInUse,
            "useSwiftVerificationManager": useSwiftVerificationManager,
        ]
        if let remoteTrackingOptions = RadarRemoteTrackingOptions.toDictionaries(remoteTrackingOptions) {
            dictionary["remoteTrackingOptions"] = remoteTrackingOptions
        }
        return dictionary
    }
}

extension RadarSdkConfiguration {
    /// QA accessor exposed via the public ObjC header. Returns the cached
    /// SDK configuration, or nil if none has been fetched yet.
    @objc public static func current() -> RadarSdkConfiguration? {
        RadarSettings.sdkConfiguration
    }
}
