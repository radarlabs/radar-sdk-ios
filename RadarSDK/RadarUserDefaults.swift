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
        case PublishableKey = "radar-publishableKey"
        case InstallId = "radar-installId"
        case SessionId = "radar-sessionId"
        case Id = "radar-_id"
        case UserId = "radar-userId"
        case userLanguage = "radar-userLanguage"
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
        case Trip = "radar-trip"
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
        case AppGroup = "radar-appGroup"

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
        // swiftlint:disable:next identifier_name
        case LocationAuthorizationStatus = "radar-locationAuthorizationStatus"
    }

    // should be set once and then readonly
    nonisolated(unsafe)
        static var userDefaults: UserDefaults = {
            // initialized with the appGroup value of UserDefaults.standard
            if let appGroup = UserDefaults.standard.string(forKey: Key.AppGroup.rawValue),
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

    public static func clone(from: UserDefaults, to: UserDefaults) {
        for key in Key.allCases {
            let value = from.value(forKey: key.rawValue)
            to.set(value, forKey: key.rawValue)
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
