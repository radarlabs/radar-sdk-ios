//
//  RadarSettings.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarSettings) @objcMembers
class RadarSettings: NSObject {
    
    static let DefaultHost = "https://api.radar.io"
    static let DefaultVerifiedHost = "https://api-verified.radar.io"
    
    // protected by MainThread in setAppGroup
    nonisolated(unsafe)
    static var radarUserDefaults: RadarUserDefaults = RadarUserDefaults.shared
    
    public static func setAppGroup(_ appGroup: String?) {
        // this call needs to by synchronised to prevent race conditions in checking / updating the app group
        let updateAppGroup = {
            // no change in app group
            if radarUserDefaults.string(forKey: .AppGroup) == appGroup {
                return
            }
            
            let prevUserDefaults = radarUserDefaults.userDefaults
            // if new user defaults cannot be created, default to .standard, UserDefaults(suiteName: nil) also references the standard user default
            let newUserDefaults = UserDefaults(suiteName: appGroup) ?? .standard
            
            // if newUserDefaults[AppGroup] is already equal to the appGroup, we're already cloned the UserDefaults,
            // so we just start using the new user defaults. This is for initializing with an app group.
            if newUserDefaults.string(forKey: RadarUserDefaults.Key.AppGroup.rawValue) == appGroup {
                UserDefaults.standard.set(appGroup, forKey: RadarUserDefaults.Key.AppGroup.rawValue)
                radarUserDefaults.userDefaults = newUserDefaults
                return
            }
            
            RadarUserDefaults.clone(from: prevUserDefaults, to: newUserDefaults)
            
            // set AppGroup to nil, so next time we switch from another app group to the current, it'll detect it's new and clone
            radarUserDefaults.set(nil, forKey: .AppGroup)
            radarUserDefaults.userDefaults = newUserDefaults
            
            // set AppGroup in default keys so we can initialize to the correct app group
            UserDefaults.standard.set(appGroup, forKey: RadarUserDefaults.Key.AppGroup.rawValue)
            // and set appGroup in new user defaults to signify initialized
            radarUserDefaults.set(appGroup, forKey: .AppGroup)
        }
        
        if Thread.isMainThread {
            updateAppGroup()
        } else {
            DispatchQueue.main.sync {
                updateAppGroup()
            }
        }
    }
    
    public static func getAppGroup() -> String? {
        return radarUserDefaults.string(forKey: .AppGroup)
    }
    
    public static var publishableKey: String? {
        get { return radarUserDefaults.string(forKey: .PublishableKey) }
        set { radarUserDefaults.set(newValue, forKey: .PublishableKey) }
    }
    
    public static var installId: String {
        if let uuid = radarUserDefaults.string(forKey: .InstallId) {
            return uuid
        } else {
            let uuid = UUID().uuidString
            radarUserDefaults.set(uuid, forKey: .InstallId)
            return uuid
        }
    }
    
    public static var sessionId: String {
        String(format: "%.f", radarUserDefaults.double(forKey: .SessionId))
    }
    
    public static func updateSessionId() -> Bool {
        let timestampSeconds: Double = Date().timeIntervalSince1970
        var sessionIdSeconds: Double = radarUserDefaults.double(forKey: .SessionId)
        
        let sdkConfiguration = RadarSettings.sdkConfiguration
        if (sdkConfiguration?.extendFlushReplays ?? false) {
            RadarLogger.shared.info("Flushing replays from updateSessionId()", type: .sdkCall)
            // TODO: call swift RadarReplayBuffer when implemented
            RadarSwift.bridge?.flushReplays()
        }
        
        if timestampSeconds - sessionIdSeconds > 300 {
            sessionIdSeconds = timestampSeconds
            radarUserDefaults.set(sessionIdSeconds, forKey: .SessionId)
            // TODO: fix this call when it can be called from swift cleanly
            RadarSwift.bridge?.logOpenedAppConversion()
            RadarLogger.shared.debug(String(format: "New session | sessionId = %@", RadarSettings.sessionId))
            return true
        }
        return false
    }
    
    public static var id: String? {
        @objc(_id)
        get { return radarUserDefaults.string(forKey: .Id) }
        set { radarUserDefaults.set(newValue, forKey: .Id) }
    }

    public static var userId: String? {
        get { return radarUserDefaults.string(forKey: .UserId) }
        set {
            let oldUserId = radarUserDefaults.string(forKey: .UserId)
            if (oldUserId != nil && oldUserId != newValue) {
                RadarSettings.id = nil
            }
            radarUserDefaults.set(newValue, forKey: .UserId)
        }
    }

    public static var description: String? {
        @objc(__description)
        get { return radarUserDefaults.string(forKey: .Description) }
        set { radarUserDefaults.set(newValue, forKey: .Description) }
    }

    public static var product: String? {
        get { return radarUserDefaults.string(forKey: .Product) }
        set { radarUserDefaults.set(newValue, forKey: .Product) }
    }
    
    public static var metadata: [String: Any]? {
        get { return radarUserDefaults.dictionary(forKey: .Metadata) }
        set { radarUserDefaults.set(newValue, forKey: .Metadata) }
    }
    
    public static var anonymousTrackingEnabled: Bool {
        get { return radarUserDefaults.bool(forKey: .Anonymous) }
        set { radarUserDefaults.set(newValue, forKey: .Anonymous) }
    }
    
    public static var tracking: Bool {
        get { return radarUserDefaults.bool(forKey: .Tracking) }
        set { radarUserDefaults.set(newValue, forKey: .Tracking) }
    }
    
    public static var trackingOptions: RadarTrackingOptions! {
        get {
            if let optionsDict = radarUserDefaults.dictionary(forKey: .TrackingOptions) {
                return RadarTrackingOptions(from: optionsDict) ?? .presetEfficient
            }
            return .presetEfficient
        }
        set {
            radarUserDefaults.set(newValue?.dictionaryValue(), forKey: .TrackingOptions)
        }
    }

    public static var previousTrackingOptions: RadarTrackingOptions? {
        get {
            if let options = radarUserDefaults.dictionary(forKey: .PreviousTrackingOptions) {
                return RadarTrackingOptions(from: options)
            }
            return nil
        }
        set {
            radarUserDefaults.set(newValue?.dictionaryValue(), forKey: .PreviousTrackingOptions)
        }
    }
    
    public static var remoteTrackingOptions: RadarTrackingOptions? {
        get {
            if let options = radarUserDefaults.dictionary(forKey: .RemoteTrackingOptions) {
                return RadarTrackingOptions(from: options)
            }
            return nil
        }
        set { radarUserDefaults.set(newValue?.dictionaryValue(), forKey: .RemoteTrackingOptions) }
    }
    
    public static var tripOptions: RadarTripOptions? {
        get {
            if let options = radarUserDefaults.dictionary(forKey: .TripOptions) {
                return RadarTripOptions(from: options)
            }
            return nil
        }
        set { radarUserDefaults.set(newValue?.dictionaryValue(), forKey: .TripOptions) }
    }
    
    public static var trip: RadarTrip? {
        get {
            if let dict = radarUserDefaults.dictionary(forKey: .Trip) {
                return RadarTrip(object: dict)
            }
            return nil
        }
        set { radarUserDefaults.set(newValue?.dictionaryValue(), forKey: .Trip) }
    }

    public static var clientSdkConfiguration: [String: Any] {
        get { return radarUserDefaults.dictionary(forKey: .ClientSdkConfiguration) ?? [:] }
        set { radarUserDefaults.set(newValue, forKey: .ClientSdkConfiguration) }
    }

    public static var sdkConfiguration: RadarSdkConfiguration? {
        get {
            let options = radarUserDefaults.dictionary(forKey: .SdkConfiguration)
            return RadarSdkConfiguration(dict: options)
        }
        set {
            radarUserDefaults.set(newValue?.dictionaryValue(), forKey: .SdkConfiguration)
            
            if let newValue = newValue {
                logLevel = newValue.logLevel;
                RadarSwift.bridge?.setLogBufferPersistantLog(newValue.useLogPersistence)
            } else {
                RadarSwift.bridge?.setLogBufferPersistantLog(false)
            }
        }
    }

    public static var logLevel: RadarLogLevel {
        get {
            if radarUserDefaults.object(forKey: .LogLevel) == nil {
                if userDebug {
                    return .debug
                } else {
                    #if DEBUG
                    return .debug;
                    #else
                    return .none
                    #endif
                }
            }
            return RadarLogLevel(rawValue: radarUserDefaults.integer(forKey: .LogLevel)) ?? .none;
        }
        set { radarUserDefaults.set(newValue.rawValue, forKey: .LogLevel) }
    }

    public static var beaconUUIDs: [String]? {
        get { return radarUserDefaults.object(forKey: .BeaconUUIDs) as? [String] }
        set { radarUserDefaults.set(newValue, forKey: .BeaconUUIDs) }
    }
    
    public static var host: String {
        get { return radarUserDefaults.string(forKey: .Host) ?? DefaultHost }
    }
    
    public static func updateLastTrackedTime() {
        let timeStamp: Date = Date()
        radarUserDefaults.set(timeStamp, forKey: .LastTrackedTime)
    }
    
    public static var lastTrackedTime: Date {
        let lastTrackedTime: Date? = radarUserDefaults.object(forKey: .LastTrackedTime) as? Date
        return lastTrackedTime ?? Date(timeIntervalSince1970: 0)
    }

    public static var verifiedHost: String {
        radarUserDefaults.string(forKey: .VerifiedHost) ?? DefaultVerifiedHost
    }
    
    public static var userDebug: Bool {
        get {
            return radarUserDefaults.bool(forKey: .UserDebug)
        }
        set {
            radarUserDefaults.set(newValue, forKey: .UserDebug)
        }
    }

    public static func updateLastAppOpenTime() {
        let timeStamp: Date = Date()
        radarUserDefaults.set(timeStamp, forKey: .LastAppOpenTime)
    }
    
    public static var lastAppOpenTime: Date {
        let lastAppOpenTime: Date? = radarUserDefaults.object(forKey: .LastAppOpenTime) as? Date
        return lastAppOpenTime ?? Date(timeIntervalSince1970: 0)
    }

    public static var useRadarModifiedBeacon: Bool {
        sdkConfiguration?.useRadarModifiedBeacon ?? false
    }
    
    public static var xPlatform: Bool {
        xPlatformSDKType != nil && xPlatformSDKVersion != nil
    }
    
    public static var xPlatformSDKType: String? {
        radarUserDefaults.string(forKey: .XPlatformSDKType)
    }
    
    public static var xPlatformSDKVersion: String? {
        radarUserDefaults.string(forKey: .XPlatformSDKVersion)
    }
    
    public static var useOpenedAppConversion: Bool {
        sdkConfiguration?.useOpenedAppConversion ?? true
    }
    
    public static var initializeOptions: RadarInitializeOptions? {
        get {
            if let options = radarUserDefaults.dictionary(forKey: .InitializeOptions) {
                return RadarInitializeOptions(dict: options)
            }
            return nil
        }
        set { radarUserDefaults.set(newValue?.dictionaryValue(), forKey: .InitializeOptions) }
    }

    public static var inSurveyMode: Bool {
        get { return radarUserDefaults.bool(forKey: .InSurveyMode) }
        set { radarUserDefaults.set(newValue, forKey: .InSurveyMode) }
    }
    
    public static var tags: [String] {
        get { return radarUserDefaults.array(forKey: .UserTags) as? [String] ?? [] }
        set { radarUserDefaults.set(newValue, forKey: .UserTags) }
    }
    
    public static func addTags(_ tags: [String]) {
        var existingTags: [String] = self.tags
        
        let existingTagsSet: Set<String> = Set(self.tags)
        for tag in tags {
            if !existingTagsSet.contains(tag) {
                existingTags.append(tag)
            }
        }
        self.tags = existingTags
    }
    
    public static func removeTags(_ tags: [String]) {
        self.tags = self.tags.filter { !tags.contains($0) }
    }

    public static var pushNotificationToken: String? {
        get { return radarUserDefaults.string(forKey: .PushNotificationToken) }
        set { radarUserDefaults.set(newValue, forKey: .PushNotificationToken) }
    }
    
    public static var locationExtensionToken: String? {
        get { return radarUserDefaults.string(forKey: .LocationExtensionToken) }
        set { radarUserDefaults.set(newValue, forKey: .LocationExtensionToken) }
    }
}
