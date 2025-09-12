//
//  RadarSettings.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

class RadarUserDefaults: NSObject {
    
    public enum Key: String, CaseIterable {
        // RadarSettings
        case PublishableKey = "radar-publishableKey"
        case InstallId = "radar-installId"
        case SessionId = "radar-sessionId"
        case Id = "radar-_id"
        case UserId = "radar-userId"
        case Description = "radar-description"
        case Product = "radar-product"
        case Metadata = "radar-metadata"
        case Anonymous = "radar-anonymous"
        case Tracking = "radar-tracking"
        case TrackingOptions = "radar-trackingOptions"
        case PreviousTrackingOptions = "radar-previousTrackingOptions"
        case RemoteTrackingOptions = "radar-remoteTrackingOptions"
        case ClientSdkConfiguration = "radar-clientSdkConfiguration"
        case SdkConfiguration = "radar-sdkConfiguration"
        case TripOptions = "radar-tripOptions"
        case LogLevel = "radar-logLevel"
        case BeaconUUIDs = "radar-beaconUUIDs"
        case Host = "radar-host"
        case LastTrackedTime = "radar-lastTrackedTime"
        case VerifiedHost = "radar-verifiedHost"
        case LastAppOpenTime = "radar-lastAppOpenTime"
        case UserDebug = "radar-userDebug"
        case XPlatformSDKType = "radar-xPlatformSDKType"
        case XPlatformSDKVersion = "radar-xPlatformSDKVersion"
        case InitializeOptions = "radar-initializeOptions"
        case UserTags = "radar-userTags"
        case PushNotificationToken = "radar-pushNotificationToken"
        case LocationExtensionToken = "radar-locationExtensionToken"
        case InSurveyMode = "radar-inSurveyMode"
        
        // RadarState
        case LastLocation = "radar-lastLocation"
        case LastMovedLocation = "radar-lastMovedLocation"
        case LastMovedAt = "radar-lastMovedAt"
        case Stopped = "radar-stopped"
        case LastSentAt = "radar-lastSentAt"
        case CanExit = "radar-canExit"
        case LastFailedStoppedLocation = "radar-lastFailedStoppedLocation"
        case GeofenceIds = "radar-geofenceIds"
        case PlaceId = "radar-placeId"
        case RegionIds = "radar-regionIds"
        case BeaconIds = "radar-beaconIds"
        case LastHeadingData = "radar-lastHeadingData"
        case LastMotionActivityData = "radar-lastMotionActivityData"
        case LastPressureData = "radar-lastPressureData"
        case NotificationPermissionGranted = "radar-notificationPermissionGranted"
        case RegisteredNotifications = "radar-registeredNotifications"
    }
    
    // should be set once and then readonly
    nonisolated(unsafe)
    static var appGroup: String? = nil
    
    public static func userDefaults() -> UserDefaults {
        if (appGroup != nil) {
            guard let userDefaults = UserDefaults(suiteName: appGroup) else {
                RadarLogger.shared.warning("user default suite not found")
                return UserDefaults.standard
            }
            return userDefaults
        } else {
            return UserDefaults.standard
        }
    }
    
    public static func setAppGroup(group: String) {
        DispatchQueue.main.async {
            appGroup = group
        }
    }
    
    public static func cloneToAppGroup() {
        let appGroupDefaults = UserDefaults(suiteName: appGroup)
        let userDefaults = UserDefaults.standard
        
        for key in Key.allCases {
            let value = userDefaults.value(forKey: key.rawValue)
            appGroupDefaults?.set(value, forKey: key.rawValue)
        }
    }
    
    public static func set(_ value: Any?, forKey key: Key) {
        userDefaults().set(value, forKey: key.rawValue)
    }
    
    public static func string(forKey key: Key) -> String? {
        return userDefaults().string(forKey: key.rawValue)
    }

    public static func bool(forKey key: Key) -> Bool {
        return userDefaults().bool(forKey: key.rawValue)
    }
    
    public static func object(forKey key: Key) -> Any? {
        return userDefaults().object(forKey: key.rawValue)
    }
    
    public static func integer(forKey key: Key) -> Int {
        return userDefaults().integer(forKey: key.rawValue)
    }
    
    public static func double(forKey key: Key) -> Double {
        return userDefaults().double(forKey: key.rawValue)
    }
    
    public static func dictionary(forKey key: Key) -> [String: Any]? {
        return userDefaults().dictionary(forKey: key.rawValue)
    }
    
    public static func array(forKey key: Key) -> [Any]? {
        return userDefaults().array(forKey: key.rawValue)
    }
}
