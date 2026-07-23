//
//  RadarSettings.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarSettings) @objcMembers
internal class RadarSettings: NSObject {  // swiftlint:disable:this type_body_length

    static let DefaultHost = "https://api.radar.io"
    static let DefaultVerifiedHost = "https://api-verified.radar.io"
    static let DefaultVerifiedHostSecondary = "https://api-verified.radar.com"

    public static var defaultVerifiedHostSecondary: String { DefaultVerifiedHostSecondary }

    public static func setAppGroup(_ appGroup: String?) {
        // this call needs to by synchronised to prevent race conditions in checking / updating the app group
        let updateAppGroup = {
            // no change in app group
            if RadarUserDefaults.string(forKey: .appGroup) == appGroup {
                return
            }

            let prevUserDefaults = RadarUserDefaults.userDefaults
            // if new user defaults cannot be created, default to .standard, UserDefaults(suiteName: nil) also references the standard user default
            let newUserDefaults = UserDefaults(suiteName: appGroup) ?? .standard

            // if newUserDefaults[AppGroup] is already equal to the appGroup, we're already cloned the UserDefaults,
            // so we just start using the new user defaults. This is for initializing with an app group.
            if newUserDefaults.string(forKey: RadarUserDefaults.Key.appGroup.rawValue) == appGroup {
                UserDefaults.standard.set(appGroup, forKey: RadarUserDefaults.Key.appGroup.rawValue)
                RadarUserDefaults.userDefaults = newUserDefaults
                return
            }

            RadarUserDefaults.clone(from: prevUserDefaults, to: newUserDefaults)

            // set AppGroup to nil, so next time we switch from another app group to the current, it'll detect it's new and clone
            RadarUserDefaults.set(nil, forKey: .appGroup)
            RadarUserDefaults.userDefaults = newUserDefaults

            // set AppGroup in default keys so we can initialize to the correct app group
            UserDefaults.standard.set(appGroup, forKey: RadarUserDefaults.Key.appGroup.rawValue)
            // and set appGroup in new user defaults to signify initialized
            RadarUserDefaults.set(appGroup, forKey: .appGroup)
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
        return RadarUserDefaults.string(forKey: .appGroup)
    }

    public static var publishableKey: String? {
        get { return RadarUserDefaults.string(forKey: .publishableKey) }
        set { RadarUserDefaults.set(newValue, forKey: .publishableKey) }
    }

    public static var installId: String {
        if let uuid = RadarUserDefaults.string(forKey: .installId) {
            return uuid
        } else {
            let uuid = UUID().uuidString
            RadarUserDefaults.set(uuid, forKey: .installId)
            return uuid
        }
    }

    public static var sessionId: String {
        String(format: "%.f", RadarUserDefaults.double(forKey: .sessionId))
    }

    public static func updateSessionId() -> Bool {
        let timestampSeconds: Double = Date().timeIntervalSince1970
        var sessionIdSeconds: Double = RadarUserDefaults.double(forKey: .sessionId)

        let sdkConfiguration = RadarSettings.sdkConfiguration
        if sdkConfiguration?.extendFlushReplays ?? false {
            RadarLogger.shared.info("Flushing replays from updateSessionId()", type: .sdkCall)
            // TODO: call swift RadarReplayBuffer when implemented
            RadarSwift.bridge?.flushReplays()
        }

        if timestampSeconds - sessionIdSeconds > 300 {
            sessionIdSeconds = timestampSeconds
            RadarUserDefaults.set(sessionIdSeconds, forKey: .sessionId)
            // TODO: fix this call when it can be called from swift cleanly
            RadarSwift.bridge?.logOpenedAppConversion()
            RadarLogger.shared.debug(String(format: "New session | sessionId = %@", RadarSettings.sessionId))
            return true
        }
        return false
    }

    public static var id: String? {
        @objc(_id)
        get { return RadarUserDefaults.string(forKey: .id) }
        set { RadarUserDefaults.set(newValue, forKey: .id) }
    }

    public static var userId: String? {
        get { return RadarUserDefaults.string(forKey: .userId) }
        set {
            let oldUserId = RadarUserDefaults.string(forKey: .userId)
            if oldUserId != nil && oldUserId != newValue {
                RadarSettings.id = nil
            }
            RadarUserDefaults.set(newValue, forKey: .userId)
        }
    }

    public static var userLanguage: String? {
        get { return RadarUserDefaults.string(forKey: .userLanguage) }
        set { RadarUserDefaults.set(newValue, forKey: .userLanguage) }
    }

    public static var description: String? {
        @objc(__description)
        get { return RadarUserDefaults.string(forKey: .description) }
        set { RadarUserDefaults.set(newValue, forKey: .description) }
    }

    public static var product: String? {
        get { return RadarUserDefaults.string(forKey: .product) }
        set { RadarUserDefaults.set(newValue, forKey: .product) }
    }

    public static var metadata: [String: Any]? {
        get { return RadarUserDefaults.dictionary(forKey: .metadata) }
        set { RadarUserDefaults.set(newValue, forKey: .metadata) }
    }

    public static var anonymousTrackingEnabled: Bool {
        get { return RadarUserDefaults.bool(forKey: .anonymous) }
        set { RadarUserDefaults.set(newValue, forKey: .anonymous) }
    }

    public static var tracking: Bool {
        get { return RadarUserDefaults.bool(forKey: .tracking) }
        set { RadarUserDefaults.set(newValue, forKey: .tracking) }
    }

    public static var trackingOptions: RadarTrackingOptions! {
        get {
            if let optionsDict = RadarUserDefaults.dictionary(forKey: .trackingOptions) {
                return RadarTrackingOptions(from: optionsDict) ?? .presetEfficient
            }
            return .presetEfficient
        }
        set {
            RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .trackingOptions)
        }
    }

    public static var previousTrackingOptions: RadarTrackingOptions? {
        get {
            if let options = RadarUserDefaults.dictionary(forKey: .previousTrackingOptions) {
                return RadarTrackingOptions(from: options)
            }
            return nil
        }
        set {
            RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .previousTrackingOptions)
        }
    }

    public static var remoteTrackingOptions: RadarTrackingOptions? {
        get {
            if let options = RadarUserDefaults.dictionary(forKey: .remoteTrackingOptions) {
                return RadarTrackingOptions(from: options)
            }
            return nil
        }
        set { RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .remoteTrackingOptions) }
    }

    public static var tripOptions: RadarTripOptions? {
        get {
            if let options = RadarUserDefaults.dictionary(forKey: .tripOptions) {
                return RadarTripOptions(from: options)
            }
            return nil
        }
        set { RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .tripOptions) }
    }

    public static var trip: RadarTrip? {
        get {
            if let dict = RadarUserDefaults.dictionary(forKey: .trip) {
                return RadarTrip(object: dict)
            }
            return nil
        }
        set { RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .trip) }
    }

    public static var clientSdkConfiguration: [String: Any] {
        get { return RadarUserDefaults.dictionary(forKey: .clientSdkConfiguration) ?? [:] }
        set { RadarUserDefaults.set(newValue, forKey: .clientSdkConfiguration) }
    }

    public static var sdkConfiguration: RadarSdkConfiguration? {
        get {
            let options = RadarUserDefaults.dictionary(forKey: .sdkConfiguration)
            return RadarSdkConfiguration(dict: options)
        }
        set {
            RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .sdkConfiguration)

            if let newValue {
                logLevel = newValue.logLevel
            }
        }
    }

    public static var logLevel: RadarLogLevel {
        get {
            if RadarUserDefaults.object(forKey: .logLevel) == nil {
                if userDebug {
                    return .debug
                } else {
                    #if DEBUG
                        return .debug
                    #else
                        return .none
                    #endif
                }
            }
            return RadarLogLevel(rawValue: RadarUserDefaults.integer(forKey: .logLevel)) ?? .none
        }
        set { RadarUserDefaults.set(newValue.rawValue, forKey: .logLevel) }
    }

    public static var beaconUUIDs: [String]? {
        get { return RadarUserDefaults.object(forKey: .beaconUUIDs) as? [String] }
        set { RadarUserDefaults.set(newValue, forKey: .beaconUUIDs) }
    }

    public static var host: String {
        return RadarUserDefaults.string(forKey: .host) ?? DefaultHost
    }

    public static var lastTrackedTime: Date {
        let lastTrackedTime: Date? = RadarUserDefaults.object(forKey: .lastTrackedTime) as? Date
        return lastTrackedTime ?? Date(timeIntervalSince1970: 0)
    }

    public static var verifiedHost: String {
        RadarUserDefaults.string(forKey: .verifiedHost) ?? DefaultVerifiedHost
    }

    public static var userDebug: Bool {
        get {
            return RadarUserDefaults.bool(forKey: .userDebug)
        }
        set {
            RadarUserDefaults.set(newValue, forKey: .userDebug)
        }
    }

    public static var lastAppOpenTime: Date {
        let lastAppOpenTime: Date? = RadarUserDefaults.object(forKey: .lastAppOpenTime) as? Date
        return lastAppOpenTime ?? Date(timeIntervalSince1970: 0)
    }

    public static var useRadarModifiedBeacon: Bool {
        sdkConfiguration?.useRadarModifiedBeacon ?? false
    }

    public static var xPlatform: Bool {
        xPlatformSDKType != nil && xPlatformSDKVersion != nil
    }

    public static var xPlatformSDKType: String? {
        RadarUserDefaults.string(forKey: .xPlatformSDKType)
    }

    public static var xPlatformSDKVersion: String? {
        RadarUserDefaults.string(forKey: .xPlatformSDKVersion)
    }

    public static var useOpenedAppConversion: Bool {
        sdkConfiguration?.useOpenedAppConversion ?? true
    }

    public static var initializeOptions: RadarInitializeOptions? {
        get {
            if let options = RadarUserDefaults.dictionary(forKey: .initializeOptions) {
                return RadarInitializeOptions(dict: options)
            }
            return nil
        }
        set { RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .initializeOptions) }
    }

    public static var inSurveyMode: Bool {
        get { return RadarUserDefaults.bool(forKey: .inSurveyMode) }
        set { RadarUserDefaults.set(newValue, forKey: .inSurveyMode) }
    }

    public static var pushNotificationToken: String? {
        get { return RadarUserDefaults.string(forKey: .pushNotificationToken) }
        set { RadarUserDefaults.set(newValue, forKey: .pushNotificationToken) }
    }

    public static var locationExtensionToken: String? {
        get { return RadarUserDefaults.string(forKey: .locationExtensionToken) }
        set { RadarUserDefaults.set(newValue, forKey: .locationExtensionToken) }
    }

    public static func updateLastTrackedTime() {
        RadarUserDefaults.set(Date(), forKey: .lastTrackedTime)
    }

    public static func updateLastAppOpenTime() {
        RadarUserDefaults.set(Date(), forKey: .lastAppOpenTime)
    }

    public static var tags: [String] {
        get { return RadarUserDefaults.array(forKey: .userTags) as? [String] ?? [] }
        set { RadarUserDefaults.set(newValue, forKey: .userTags) }
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
}
