//
//  RadarSdkConfiguration.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarSdkConfiguration) @objcMembers
class RadarSdkConfiguration: NSObject {
    private let originalDict: [String: Any]?

    let logLevel: RadarLogLevel
    let startTrackingOnInitialize: Bool
    let trackOnceOnAppOpen: Bool
    let usePersistence: Bool
    let extendFlushReplays: Bool
    let useLogPersistence: Bool
    let useRadarModifiedBeacon: Bool
    let useOpenedAppConversion: Bool
    let useForegroundLocationUpdatedAtMsDiff: Bool
    let useNotificationDiff: Bool
    let syncAfterSetUser: Bool
    let useSyncRegion: Bool
    let defaultGeofenceDwellThreshold: Int
    let bufferGeofenceEntries: Bool
    let bufferGeofenceExits: Bool
    let stopDetection: Bool
    let skipForegroundCheck: Bool
    let useOfflineRTOUpdates: Bool
    let offlineEventGenerationEnabled: Bool
    let useSwiftLocationManager: Bool
    let startUpdatesWhileInUse: Bool
    let remoteTrackingOptions: [RadarRemoteTrackingOptions]?

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
        useNotificationDiff = dict?["useNotificationDiff"] as? Bool ?? false
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
        remoteTrackingOptions = RadarRemoteTrackingOptions.from(array: dict?["remoteTrackingOptions"] as? [[String: Any]])
    }

    public func dictionaryValue() -> [String: Any] {
        if let originalDict {
            return originalDict
        }
        return [
            "logLevel": logLevel.toString(),
            "startTrackingOnInitialize": startTrackingOnInitialize,
            "trackOnceOnAppOpen": trackOnceOnAppOpen,
            "usePersistence": usePersistence,
            "extendFlushReplays": extendFlushReplays,
            "useLogPersistence": useLogPersistence,
            "useRadarModifiedBeacon": useRadarModifiedBeacon,
            "useOpenedAppConversion": useOpenedAppConversion,
            "useForegroundLocationUpdatedAtMsDiff": useForegroundLocationUpdatedAtMsDiff,
            "useNotificationDiff": useNotificationDiff,
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
            "remoteTrackingOptions": RadarRemoteTrackingOptions.toDictionaries(remoteTrackingOptions) as Any,
        ]
    }
}

extension RadarSdkConfiguration {
    /// QA accessor exposed via the public ObjC header. Returns the cached
    /// SDK configuration, or nil if none has been fetched yet.
    @objc static func current() -> RadarSdkConfiguration? {
        RadarSettings.sdkConfiguration
    }
}
