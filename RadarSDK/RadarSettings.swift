//
//  RadarSettings.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

class RadarSettings {
    private static let kPublishableKey = "radar-publishableKey";
    private static let kInstallId = "radar-installId";
    private static let kSessionId = "radar-sessionId";
    private static let kId = "radar-_id";
    private static let kUserId = "radar-userId";
    private static let kDescription = "radar-description";
    private static let kProduct = "radar-product";
    private static let kMetadata = "radar-metadata";
    private static let kAnonymous = "radar-anonymous";
    private static let kTracking = "radar-tracking";
    private static let kTrackingOptions = "radar-trackingOptions";
    private static let kPreviousTrackingOptions = "radar-previousTrackingOptions";
    private static let kRemoteTrackingOptions = "radar-remoteTrackingOptions";
    private static let kClientSdkConfiguration = "radar-clientSdkConfiguration";
    private static let kSdkConfiguration = "radar-sdkConfiguration";
    private static let kTripOptions = "radar-tripOptions";
    private static let kLogLevel = "radar-logLevel";
    private static let kBeaconUUIDs = "radar-beaconUUIDs";
    private static let kHost = "radar-host";
    private static let kDefaultHost = "https://api.radar.io";
    private static let kLastTrackedTime = "radar-lastTrackedTime";
    private static let kVerifiedHost = "radar-verifiedHost";
    private static let kDefaultVerifiedHost = "https://api-verified.radar.io";
    private static let kLastAppOpenTime = "radar-lastAppOpenTime";
    private static let kUserDebug = "radar-userDebug";
    private static let kXPlatformSDKType = "radar-xPlatformSDKType";
    private static let kXPlatformSDKVersion = "radar-xPlatformSDKVersion";
    private static let kInitializeOptions = "radar-initializeOptions";
    private static let kUserTags = "radar-userTags";

    static var logLevel: RadarLogLevel {
        get {
            if UserDefaults.standard.object(forKey: kLogLevel) == nil {
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
            return RadarLogLevel(rawValue: UserDefaults.standard.integer(forKey: kLogLevel)) ?? .none;
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kLogLevel)
        }
    }

    static var userDebug: Bool {
        get {
            return UserDefaults.standard.bool(forKey: kUserDebug)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kUserDebug)
        }
    }
    
    static var host: String {
        return UserDefaults.standard.string(forKey: kHost) ?? kDefaultHost
    }

    static var sdkConfiguration: RadarSdkConfiguration? {
        get {
            if let dict = UserDefaults.standard.dictionary(forKey: kSdkConfiguration) {
                return RadarSdkConfiguration(dict: dict)
            }
            return nil
        }
        set {
            if let config = newValue {
                RadarLogger.shared.log(level: .debug, message: "Setting SDK configuration | sdkConfiguration = \(RadarUtils.dictionary(toJson: config.dictionaryValue()))")
                RadarLogBuffer.sharedInstance().persistentLogFeatureFlag = config.useLogPersistence
                logLevel = config.logLevel
                UserDefaults.standard.set(config.dictionaryValue(), forKey: kSdkConfiguration)
            } else {
                RadarLogBuffer.sharedInstance().persistentLogFeatureFlag = false
                UserDefaults.standard.removeObject(forKey: kSdkConfiguration)
            }
        }
    }

    // TODO: complete implementation for other radar settings
}
