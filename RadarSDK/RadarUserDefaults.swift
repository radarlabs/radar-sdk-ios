//
//  RadarUserDefaults.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarUserDefaults) class RadarUserDefaults: NSObject {

    public enum Key: String, CaseIterable {
        // RadarSettings
        case publishableKey = "radar-publishableKey"
        case installId = "radar-installId"
        case sessionId = "radar-sessionId"
        case id = "radar-_id"
        case userId = "radar-userId"
        case userLanguage = "radar-userLanguage"
        case description = "radar-description"
        case product = "radar-product"
        case metadata = "radar-metadata"
        case anonymous = "radar-anonymous"
        case tracking = "radar-tracking"
        case trackingOptions = "radar-trackingOptions"
        case previousTrackingOptions = "radar-previousTrackingOptions"
        case remoteTrackingOptions = "radar-remoteTrackingOptions"
        case clientSdkConfiguration = "radar-clientSdkConfiguration"
        case sdkConfiguration = "radar-sdkConfiguration"
        case tripOptions = "radar-tripOptions"
        case trip = "radar-trip"
        case logLevel = "radar-logLevel"
        case beaconUUIDs = "radar-beaconUUIDs"
        case host = "radar-host"
        case lastTrackedTime = "radar-lastTrackedTime"
        case verifiedHost = "radar-verifiedHost"
        case lastAppOpenTime = "radar-lastAppOpenTime"
        case userDebug = "radar-userDebug"
        case xPlatformSDKType = "radar-xPlatformSDKType"
        case xPlatformSDKVersion = "radar-xPlatformSDKVersion"
        case initializeOptions = "radar-initializeOptions"
        case userTags = "radar-userTags"
        case pushNotificationToken = "radar-pushNotificationToken"
        case locationExtensionToken = "radar-locationExtensionToken"
        case inSurveyMode = "radar-inSurveyMode"
        case appGroup = "radar-appGroup"

        // RadarState
        case lastLocation = "radar-lastLocation"
        case lastMovedLocation = "radar-lastMovedLocation"
        case lastMovedAt = "radar-lastMovedAt"
        case stopped = "radar-stopped"
        case lastSentAt = "radar-lastSentAt"
        case canExit = "radar-canExit"
        case lastFailedStoppedLocation = "radar-lastFailedStoppedLocation"
        case geofenceIds = "radar-geofenceIds"
        case placeId = "radar-placeId"
        case regionIds = "radar-regionIds"
        case beaconIds = "radar-beaconIds"
        case lastHeadingData = "radar-lastHeadingData"
        case lastMotionActivityData = "radar-lastMotionActivityData"
        case lastPressureData = "radar-lastPressureData"
        case notificationPermissionGranted = "radar-notificationPermissionGranted"
        case registeredNotifications = "radar-registeredNotifications"
        case locationAuthorizationStatus = "radar-locationAuthorizationStatus"
    }

    // should be set once and then readonly
    nonisolated(unsafe)
        static var userDefaults: UserDefaults = {
            // initialized with the appGroup value of UserDefaults.standard
            if let appGroup = UserDefaults.standard.string(forKey: Key.appGroup.rawValue),
                let appGroupSuite = UserDefaults(suiteName: appGroup)
            {
                return appGroupSuite
            } else {
                return UserDefaults.standard
            }
        }()

    /// The backing store the SDK persists to — the app-group suite when one is configured
    /// via `Radar.initializeWithAppGroup:`, otherwise `UserDefaults.standard`. Exposed to
    /// ObjC so accessors not yet migrated to the `Key`-typed API (e.g. `RadarState`'s
    /// heading data) read and write the same store this funnel uses.
    @objc static var sharedUserDefaults: UserDefaults { userDefaults }

    private static let flushQueue = DispatchQueue(
        label: "io.radar.userdefaults.flush",
        qos: .utility
    )

    private static let flushLock = NSLock()
    nonisolated(unsafe)
        private static var pendingFlushTargets: [ObjectIdentifier: UserDefaults] = [:]

    public static func clone(from source: UserDefaults, to target: UserDefaults) {
        for key in Key.allCases {
            let value = source.value(forKey: key.rawValue)
            target.set(value, forKey: key.rawValue)
        }
    }

    public static func set(_ value: Any?, forKey key: Key) {
        let target = userDefaults
        target.set(value, forKey: key.rawValue)
        scheduleFlush(for: target)
    }

    private static func scheduleFlush(for target: UserDefaults) {
        let id = ObjectIdentifier(target)

        flushLock.lock()
        let alreadyScheduled = pendingFlushTargets[id] != nil
        pendingFlushTargets[id] = target
        flushLock.unlock()

        guard !alreadyScheduled else { return }
        flushQueue.async {
            flushLock.lock()
            let captured = pendingFlushTargets.removeValue(forKey: id)
            flushLock.unlock()

            captured?.synchronize()
        }
    }

    public static func string(forKey key: Key) -> String? {
        return userDefaults.string(forKey: key.rawValue)
    }

    public static func bool(forKey key: Key) -> Bool {
        return userDefaults.bool(forKey: key.rawValue)
    }

    public static func object(forKey key: Key) -> Any? {
        return userDefaults.object(forKey: key.rawValue)
    }

    public static func integer(forKey key: Key) -> Int {
        return userDefaults.integer(forKey: key.rawValue)
    }

    public static func double(forKey key: Key) -> Double {
        return userDefaults.double(forKey: key.rawValue)
    }

    public static func dictionary(forKey key: Key) -> [String: Any]? {
        return userDefaults.dictionary(forKey: key.rawValue)
    }

    public static func array(forKey key: Key) -> [Any]? {
        return userDefaults.array(forKey: key.rawValue)
    }

    public static func data(forKey key: Key) -> Data? {
        return userDefaults.data(forKey: key.rawValue)
    }
}
