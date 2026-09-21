//
//  RadarSdkConfiguration.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc @implementation extension RadarSdkConfiguration {
    private let originalDictionaryStorage: [AnyHashable: Any]?

    private let logLevelStorage: RadarLogLevel
    private let startTrackingOnInitializeStorage: Bool
    private let trackOnceOnAppOpenStorage: Bool
    private let usePersistenceStorage: Bool
    private let extendFlushReplaysStorage: Bool
    private let useLogPersistenceStorage: Bool
    private let useRadarModifiedBeaconStorage: Bool
    private let useOpenedAppConversionStorage: Bool
    private let foregroundLocationUpdatedAtMsDiffStorage: Bool
    private let syncAfterSetUserStorage: Bool
    private let useSyncRegionStorage: Bool
    private let defaultGeofenceDwellThresholdStorage: Int
    private let bufferGeofenceEntriesStorage: Bool
    private let bufferGeofenceExitsStorage: Bool
    private let stopDetectionStorage: Bool
    private let skipForegroundCheckStorage: Bool
    private let useOfflineRTOUpdatesStorage: Bool
    private let offlineEventGenerationEnabledStorage: Bool
    private let useSwiftLocationManagerStorage: Bool
    private let startUpdatesWhileInUseStorage: Bool
    private let remoteTrackingOptionsStorage: [RadarRemoteTrackingOptions]?
    private let useSwiftVerificationManagerStorage: Bool

    public init(dict: [AnyHashable: Any]?) {
        originalDictionaryStorage = dict
        logLevelStorage = RadarLogLevel.from(string: dict?["logLevel"] as? String ?? "none")
        startTrackingOnInitializeStorage = dict?["startTrackingOnInitialize"] as? Bool ?? false
        trackOnceOnAppOpenStorage = dict?["trackOnceOnAppOpen"] as? Bool ?? false
        usePersistenceStorage = dict?["usePersistence"] as? Bool ?? false
        extendFlushReplaysStorage = dict?["extendFlushReplays"] as? Bool ?? false
        useLogPersistenceStorage = dict?["useLogPersistence"] as? Bool ?? false
        useRadarModifiedBeaconStorage = dict?["useRadarModifiedBeacon"] as? Bool ?? false
        useOpenedAppConversionStorage = dict?["useOpenedAppConversion"] as? Bool ?? false
        foregroundLocationUpdatedAtMsDiffStorage = dict?["useForegroundLocationUpdatedAtMsDiff"] as? Bool ?? false
        syncAfterSetUserStorage = dict?["syncAfterSetUser"] as? Bool ?? false
        useSyncRegionStorage = dict?["useSyncRegion"] as? Bool ?? false
        defaultGeofenceDwellThresholdStorage = dict?["defaultGeofenceDwellThreshold"] as? Int ?? 0
        bufferGeofenceEntriesStorage = dict?["bufferGeofenceEntries"] as? Bool ?? true
        bufferGeofenceExitsStorage = dict?["bufferGeofenceExits"] as? Bool ?? true
        stopDetectionStorage = dict?["stopDetection"] as? Bool ?? false
        skipForegroundCheckStorage = dict?["skipForegroundCheck"] as? Bool ?? true
        useOfflineRTOUpdatesStorage = dict?["useOfflineRTOUpdates"] as? Bool ?? false
        offlineEventGenerationEnabledStorage = dict?["offlineEventGenerationEnabled"] as? Bool ?? false
        useSwiftLocationManagerStorage = dict?["useSwiftLocationManager"] as? Bool ?? false
        startUpdatesWhileInUseStorage = dict?["startUpdatesWhileInUse"] as? Bool ?? false
        remoteTrackingOptionsStorage = RadarRemoteTrackingOptions.from(array: dict?["remoteTrackingOptions"] as? [[String: Any]])
        useSwiftVerificationManagerStorage = dict?["useSwiftVerificationManager"] as? Bool ?? false
    }

    func logLevel() -> RadarLogLevel { logLevelStorage }

    func startTrackingOnInitialize() -> Bool { startTrackingOnInitializeStorage }

    func trackOnceOnAppOpen() -> Bool { trackOnceOnAppOpenStorage }

    func usePersistence() -> Bool { usePersistenceStorage }

    func extendFlushReplays() -> Bool { extendFlushReplaysStorage }

    func useLogPersistence() -> Bool { useLogPersistenceStorage }

    func useRadarModifiedBeacon() -> Bool { useRadarModifiedBeaconStorage }

    func useOpenedAppConversion() -> Bool { useOpenedAppConversionStorage }

    func useForegroundLocationUpdatedAtMsDiff() -> Bool { foregroundLocationUpdatedAtMsDiffStorage }

    func syncAfterSetUser() -> Bool { syncAfterSetUserStorage }

    func useSyncRegion() -> Bool { useSyncRegionStorage }

    func defaultGeofenceDwellThreshold() -> Int { defaultGeofenceDwellThresholdStorage }

    func bufferGeofenceEntries() -> Bool { bufferGeofenceEntriesStorage }

    func bufferGeofenceExits() -> Bool { bufferGeofenceExitsStorage }

    func stopDetection() -> Bool { stopDetectionStorage }

    func skipForegroundCheck() -> Bool { skipForegroundCheckStorage }

    func useOfflineRTOUpdates() -> Bool { useOfflineRTOUpdatesStorage }

    func offlineEventGenerationEnabled() -> Bool { offlineEventGenerationEnabledStorage }

    func useSwiftLocationManager() -> Bool { useSwiftLocationManagerStorage }

    func startUpdatesWhileInUse() -> Bool { startUpdatesWhileInUseStorage }

    func useSwiftVerificationManager() -> Bool { useSwiftVerificationManagerStorage }

    func remoteTrackingOptions() -> [RadarRemoteTrackingOptions]? { remoteTrackingOptionsStorage }

    func dictionaryValue() -> [AnyHashable: Any] {
        if let originalDictionaryStorage {
            return originalDictionaryStorage
        }

        var dictionary: [AnyHashable: Any] = [
            "logLevel": logLevelStorage.toString(),
            "startTrackingOnInitialize": startTrackingOnInitializeStorage,
            "trackOnceOnAppOpen": trackOnceOnAppOpenStorage,
            "usePersistence": usePersistenceStorage,
            "extendFlushReplays": extendFlushReplaysStorage,
            "useLogPersistence": useLogPersistenceStorage,
            "useRadarModifiedBeacon": useRadarModifiedBeaconStorage,
            "useOpenedAppConversion": useOpenedAppConversionStorage,
            "useForegroundLocationUpdatedAtMsDiff": foregroundLocationUpdatedAtMsDiffStorage,
            "syncAfterSetUser": syncAfterSetUserStorage,
            "useSyncRegion": useSyncRegionStorage,
            "defaultGeofenceDwellThreshold": defaultGeofenceDwellThresholdStorage,
            "bufferGeofenceEntries": bufferGeofenceEntriesStorage,
            "bufferGeofenceExits": bufferGeofenceExitsStorage,
            "stopDetection": stopDetectionStorage,
            "skipForegroundCheck": skipForegroundCheckStorage,
            "useOfflineRTOUpdates": useOfflineRTOUpdatesStorage,
            "offlineEventGenerationEnabled": offlineEventGenerationEnabledStorage,
            "useSwiftLocationManager": useSwiftLocationManagerStorage,
            "startUpdatesWhileInUse": startUpdatesWhileInUseStorage,
            "useSwiftVerificationManager": useSwiftVerificationManagerStorage,
        ]
        if let remoteTrackingOptions = RadarRemoteTrackingOptions.toDictionaries(remoteTrackingOptionsStorage) {
            dictionary["remoteTrackingOptions"] = remoteTrackingOptions
        }
        return dictionary
    }

    /// QA accessor exposed via the public ObjC header. Returns the cached
    /// SDK configuration, or nil if none has been fetched yet.
    class func current() -> RadarSdkConfiguration? {
        RadarSettings.sdkConfiguration
    }
}
