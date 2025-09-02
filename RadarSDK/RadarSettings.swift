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

    // TODO: complete implementation for SdkConfiguration
    public static func setAppGroup(appGroup: String) {
        RadarUserDefaults.appGroup = appGroup
    }
    
    public static var publishableKey: String? {
        get { return RadarUserDefaults.string(forKey: .PublishableKey) }
        set { RadarUserDefaults.set(newValue, forKey: .PublishableKey) }
    }
    
    public static var installId: String {
        get {
            if let uuid = RadarUserDefaults.string(forKey: .InstallId) {
                return uuid
            } else {
                let uuid = UUID().uuidString
                RadarUserDefaults.set(uuid, forKey: .InstallId)
                return uuid
            }
        }
    }
    
    public static var sessionId: String {
        get { String(format: "%.f", RadarUserDefaults.double(forKey: .SessionId)) }
    }
    
    public static func updateSessionId() -> Bool {
        let timestampSeconds: Double = Date().timeIntervalSince1970
        var sessionIdSeconds: Double = RadarUserDefaults.double(forKey: .SessionId)
        
        let sdkConfiguration = RadarSettings.sdkConfiguration
        if (sdkConfiguration?.extendFlushReplays ?? false) {
            RadarLogger.shared.info("Flushing replays from updateSessionId()", type: .sdkCall)
            // TODO:
            // [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
        }
        
        if timestampSeconds - sessionIdSeconds > 300 {
            sessionIdSeconds = timestampSeconds
            RadarUserDefaults.set(sessionIdSeconds, forKey: .SessionId)
            // TODO:
            // Radar.logOpenedAppConversion()
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
            RadarUserDefaults.set(newValue, forKey: .UserId) }
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
        set { RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .SdkConfiguration) }
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
        set { RadarUserDefaults.set(newValue, forKey: .LogLevel) }
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
        get {
            let lastTrackedTime: Date? = RadarUserDefaults.object(forKey: .LastTrackedTime) as? Date
            return lastTrackedTime ?? Date(timeIntervalSince1970: 0)
        }
    }

    public static var verifiedHost: String {
        get { return RadarUserDefaults.string(forKey: .VerifiedHost) ?? DefaultVerifiedHost }
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
        get {
            let lastAppOpenTime: Date? = RadarUserDefaults.object(forKey: .LastAppOpenTime) as? Date
            return lastAppOpenTime ?? Date(timeIntervalSince1970: 0)
        }
    }

    public static var useRadarModifiedBeacon: Bool {
        get { return sdkConfiguration?.useRadarModifiedBeacon ?? false }
    }
    
    public static var xPlatform: Bool {
        get { return xPlatformSDKType != nil && xPlatformSDKVersion != nil }
    }
    
    public static var xPlatformSDKType: String? {
        get { return RadarUserDefaults.string(forKey: .XPlatformSDKType) }
    }
    
    public static var xPlatformSDKVersion: String? {
        get { return RadarUserDefaults.string(forKey: .XPlatformSDKVersion) }
    }
    
    public static var useOpenedAppConversion: Bool {
        get { return sdkConfiguration?.useOpenedAppConversion ?? true }
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
