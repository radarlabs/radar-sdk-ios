//
//  RadarSettings.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarSettings) @objcMembers
internal class RadarSettings: NSObject {
    
    static let DefaultHost = "https://api.radar.io"
    static let DefaultVerifiedHost = "https://api-verified.radar.io"
    
    public static func setAppGroup(_ appGroup: String?) {
        // no change in app group
        if RadarUserDefaults.string(forKey: .AppGroup) == appGroup {
            return
        }
        
        let prevUserDefaults = RadarUserDefaults.userDefaults
        // if new user defaults cannot be created, default to .standard, if appGroup = nil, this also reference the standard user default
        let newUserDefaults = UserDefaults(suiteName: appGroup) ?? .standard
        
        // if newUserDefaults[AppGroup] is already equal to the appGroup, we're already cloned the UserDefaults,
        // so we just start using the new user defaults. This is for initializing with an app group.
        if newUserDefaults.string(forKey: RadarUserDefaults.Key.AppGroup.rawValue) == appGroup {
            UserDefaults.standard.set(appGroup, forKey: RadarUserDefaults.Key.AppGroup.rawValue)
            RadarUserDefaults.userDefaults = newUserDefaults
            return
        }
        
        RadarUserDefaults.clone(from: prevUserDefaults, to: newUserDefaults)
        print("Cloned")
        
        // set AppGroup to nil, so next time we switch from another app group to the current, it'll detect it's new and clone
        RadarUserDefaults.set(nil, forKey: .AppGroup)
        RadarUserDefaults.userDefaults = newUserDefaults
        
        // set AppGroup in default keys so we can initialize to the correct app group
        UserDefaults.standard.set(appGroup, forKey: RadarUserDefaults.Key.AppGroup.rawValue)
        // and set appGroup in new user defaults to signify initialized
        RadarUserDefaults.set(appGroup, forKey: .AppGroup)
    }
    
    public static func getAppGroup() -> String? {
        return RadarUserDefaults.string(forKey: .AppGroup)
    }
    
    public static var publishableKey: String? {
        get { return RadarUserDefaults.string(forKey: .PublishableKey) }
        set { RadarUserDefaults.set(newValue, forKey: .PublishableKey) }
    }
    
    public static var installId: String {
        if let uuid = RadarUserDefaults.string(forKey: .InstallId) {
            return uuid
        } else {
            let uuid = UUID().uuidString
            RadarUserDefaults.set(uuid, forKey: .InstallId)
            return uuid
        }
    }
    
    public static var sessionId: String {
        String(format: "%.f", RadarUserDefaults.double(forKey: .SessionId))
    }
    
    public static func updateSessionId() -> Bool {
        let timestampSeconds: Double = Date().timeIntervalSince1970
        var sessionIdSeconds: Double = RadarUserDefaults.double(forKey: .SessionId)
        
        let sdkConfiguration = RadarSettings.sdkConfiguration
        if (sdkConfiguration?.extendFlushReplays ?? false) {
            RadarLogger.shared.info("Flushing replays from updateSessionId()", type: .sdkCall)
            // TODO: call swift RadarReplayBuffer when implemented
            RadarSwift.bridge?.flushReplays()
        }
        
        if timestampSeconds - sessionIdSeconds > 300 {
            sessionIdSeconds = timestampSeconds
            RadarUserDefaults.set(sessionIdSeconds, forKey: .SessionId)
            // TODO: fix this call when it can be called from swift cleanly
            RadarSwift.bridge?.logOpenedAppConversion()
            RadarLogger.shared.debug(String(format: "New session | sessionId = %@", RadarSettings.sessionId))
            return true
        }
        return false
    }
    
    public static var id: String? {
        @objc(_id)
        get { return RadarUserDefaults.string(forKey: .Id) }
        set { RadarUserDefaults.set(newValue, forKey: .Id) }
    }

    public static var userId: String? {
        get { return RadarUserDefaults.string(forKey: .UserId) }
        set {
            let oldUserId = RadarUserDefaults.string(forKey: .UserId)
            if (oldUserId != nil && oldUserId != newValue) {
                RadarSettings.id = nil
            }
            RadarUserDefaults.set(newValue, forKey: .UserId)
        }
    }

    public static var description: String? {
        @objc(__description)
        get { return RadarUserDefaults.string(forKey: .Description) }
        set { RadarUserDefaults.set(newValue, forKey: .Description) }
    }

    public static var product: String? {
        get { return RadarUserDefaults.string(forKey: .Product) }
        set { RadarUserDefaults.set(newValue, forKey: .Product) }
    }
    
    public static var metadata: [String: Any]? {
        get { return RadarUserDefaults.dictionary(forKey: .Metadata) }
        set { RadarUserDefaults.set(newValue, forKey: .Metadata) }
    }
    
    public static var anonymousTrackingEnabled: Bool {
        get { return RadarUserDefaults.bool(forKey: .Anonymous) }
        set { RadarUserDefaults.set(newValue, forKey: .Anonymous) }
    }
    
    public static var tracking: Bool {
        get { return RadarUserDefaults.bool(forKey: .Tracking) }
        set { RadarUserDefaults.set(newValue, forKey: .Tracking) }
    }
    
    public static var trackingOptions: RadarTrackingOptions! {
        get {
            if let optionsDict = RadarUserDefaults.dictionary(forKey: .TrackingOptions) {
                return RadarTrackingOptions(from: optionsDict) ?? .presetEfficient
            }
            return .presetEfficient
        }
        set {
            RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .TrackingOptions)
        }
    }

    public static var previousTrackingOptions: RadarTrackingOptions? {
        get {
            if let options = RadarUserDefaults.dictionary(forKey: .PreviousTrackingOptions) {
                return RadarTrackingOptions(from: options)
            }
            return nil
        }
        set {
            RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .PreviousTrackingOptions)
        }
    }
    
    public static var remoteTrackingOptions: RadarTrackingOptions? {
        get {
            if let options = RadarUserDefaults.dictionary(forKey: .RemoteTrackingOptions) {
                return RadarTrackingOptions(from: options)
            }
            return nil
        }
        set { RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .RemoteTrackingOptions) }
    }
    
    public static var tripOptions: RadarTripOptions? {
        get {
            if let options = RadarUserDefaults.dictionary(forKey: .TripOptions) {
                return RadarTripOptions(from: options)
            }
            return nil
        }
        set { RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .TripOptions) }
    }

    public static var clientSdkConfiguration: [String: Any] {
        get { return RadarUserDefaults.dictionary(forKey: .ClientSdkConfiguration) ?? [:] }
        set { RadarUserDefaults.set(newValue, forKey: .ClientSdkConfiguration) }
    }

    public static var sdkConfiguration: RadarSdkConfiguration? {
        get {
            if let options = RadarUserDefaults.dictionary(forKey: .SdkConfiguration) {
                return RadarSdkConfiguration(dict: options)
            }
            return nil
        }
        set {
            RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .SdkConfiguration)
            
            if let newValue = newValue {
                logLevel = newValue.logLevel;
                RadarSwift.bridge!.setLogBufferPersistantLog(true)
            } else {
                RadarSwift.bridge!.setLogBufferPersistantLog(false)
            }
        }
    }

    public static var logLevel: RadarLogLevel {
        get {
            if RadarUserDefaults.object(forKey: .LogLevel) == nil {
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
            return RadarLogLevel(rawValue: RadarUserDefaults.integer(forKey: .LogLevel)) ?? .none;
        }
        set { RadarUserDefaults.set(newValue.rawValue, forKey: .LogLevel) }
    }

    public static var beaconUUIDs: [String]? {
        get { return RadarUserDefaults.object(forKey: .BeaconUUIDs) as? [String] }
        set { RadarUserDefaults.set(newValue, forKey: .BeaconUUIDs) }
    }
    
    public static var host: String {
        get { return RadarUserDefaults.string(forKey: .Host) ?? DefaultHost }
    }
    
    public static func updateLastTrackedTime() {
        let timeStamp: Date = Date()
        RadarUserDefaults.set(timeStamp, forKey: .LastTrackedTime)
    }
    
    public static var lastTrackedTime: Date {
        let lastTrackedTime: Date? = RadarUserDefaults.object(forKey: .LastTrackedTime) as? Date
        return lastTrackedTime ?? Date(timeIntervalSince1970: 0)
    }

    public static var verifiedHost: String {
        RadarUserDefaults.string(forKey: .VerifiedHost) ?? DefaultVerifiedHost
    }
    
    public static var userDebug: Bool {
        get {
            return RadarUserDefaults.bool(forKey: .UserDebug)
        }
        set {
            RadarUserDefaults.set(newValue, forKey: .UserDebug)
        }
    }

    public static func updateLastAppOpenTime() {
        let timeStamp: Date = Date()
        RadarUserDefaults.set(timeStamp, forKey: .LastAppOpenTime)
    }
    
    public static var lastAppOpenTime: Date {
        let lastAppOpenTime: Date? = RadarUserDefaults.object(forKey: .LastAppOpenTime) as? Date
        return lastAppOpenTime ?? Date(timeIntervalSince1970: 0)
    }

    public static var useRadarModifiedBeacon: Bool {
        sdkConfiguration?.useRadarModifiedBeacon ?? false
    }
    
    public static var xPlatform: Bool {
        xPlatformSDKType != nil && xPlatformSDKVersion != nil
    }
    
    public static var xPlatformSDKType: String? {
        RadarUserDefaults.string(forKey: .XPlatformSDKType)
    }
    
    public static var xPlatformSDKVersion: String? {
        RadarUserDefaults.string(forKey: .XPlatformSDKVersion)
    }
    
    public static var useOpenedAppConversion: Bool {
        sdkConfiguration?.useOpenedAppConversion ?? true
    }
    
    public static var initializeOptions: RadarInitializeOptions? {
        get {
            if let options = RadarUserDefaults.dictionary(forKey: .InitializeOptions) {
                return RadarInitializeOptions(dict: options)
            }
            return nil
        }
        set { RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .InitializeOptions) }
    }

    public static var inSurveyMode: Bool {
        get { return RadarUserDefaults.bool(forKey: .InSurveyMode) }
        set { RadarUserDefaults.set(newValue, forKey: .InSurveyMode) }
    }
    
    public static var tags: [String] {
        get { return RadarUserDefaults.array(forKey: .UserTags) as? [String] ?? [] }
        set { RadarUserDefaults.set(newValue, forKey: .UserTags) }
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
        get { return RadarUserDefaults.string(forKey: .PushNotificationToken) }
        set { RadarUserDefaults.set(newValue, forKey: .PushNotificationToken) }
    }
    
    public static var locationExtensionToken: String? {
        get { return RadarUserDefaults.string(forKey: .LocationExtensionToken) }
        set { RadarUserDefaults.set(newValue, forKey: .LocationExtensionToken) }
    }
}
