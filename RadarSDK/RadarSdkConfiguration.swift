//
//  RadarSdkConfiguration.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/15/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

internal class RadarSdkConfiguration {
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
    
    init?(from dict: [String: Any]?) {
        guard let dict = dict else {
            return nil
        }
        
        logLevel = RadarLogLevel.fromString(dict["logLevel"] as? String)
        startTrackingOnInitialize = (dict["startTrackingOnInitialize"] as? Bool) ?? false
        trackOnceOnAppOpen = (dict["trackOnceOnAppOpen"] as? Bool) ?? false
        usePersistence = (dict["usePersistence"] as? Bool) ?? false
        extendFlushReplays = (dict["extendFlushReplays"] as? Bool) ?? false
        useLogPersistence = (dict["useLogPersistence"] as? Bool) ?? false
        useRadarModifiedBeacon = (dict["useRadarModifiedBeacon"] as? Bool) ?? false
        useOpenedAppConversion = (dict["useOpenedAppConversion"] as? Bool) ?? false
        useForegroundLocationUpdatedAtMsDiff = (dict["useForegroundLocationUpdatedAtMsDiff"] as? Bool) ?? false
        useNotificationDiff = (dict["useNotificationDiff"] as? Bool) ?? false
        syncAfterSetUser = (dict["syncAfterSetUser"] as? Bool) ?? false
    }
    
    func dictionaryValue() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        dict["logLevel"] = logLevel.toString()
        dict["startTrackingOnInitialize"] = startTrackingOnInitialize
        dict["trackOnceOnAppOpen"] = trackOnceOnAppOpen
        dict["usePersistence"] = usePersistence
        dict["extendFlushReplays"] = extendFlushReplays
        dict["useLogPersistence"] = useLogPersistence
        dict["useRadarModifiedBeacon"] = useRadarModifiedBeacon
        dict["useOpenedAppConversion"] = useOpenedAppConversion
        dict["useForegroundLocationUpdatedAtMsDiff"] = useForegroundLocationUpdatedAtMsDiff
        dict["useNotificationDiff"] = useNotificationDiff
        dict["syncAfterSetUser"] = syncAfterSetUser
        
        return dict
    }
    
    // TODO: updateSdkConfigurationFromServer
}
