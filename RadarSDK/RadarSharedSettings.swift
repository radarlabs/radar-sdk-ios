//
//  RadarSettings.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc @objcMembers
public class RadarSharedSettings: NSObject {
    
    public static let PublishableKey = "radar-publishableKey";
    public static let InstallId = "radar-installId";
    public static let SessionId = "radar-sessionId";
    public static let Id = "radar-_id";
    public static let UserId = "radar-userId";
    public static let Description = "radar-description";
    public static let Product = "radar-product";
    public static let Metadata = "radar-metadata";
    public static let Anonymous = "radar-anonymous";
    public static let Tracking = "radar-tracking";
    public static let TrackingOptions = "radar-trackingOptions";
    public static let PreviousTrackingOptions = "radar-previousTrackingOptions";
    public static let RemoteTrackingOptions = "radar-remoteTrackingOptions";
    public static let ClientSdkConfiguration = "radar-clientSdkConfiguration";
    public static let SdkConfiguration = "radar-sdkConfiguration";
    public static let TripOptions = "radar-tripOptions";
    public static let LogLevel = "radar-logLevel";
    public static let BeaconUUIDs = "radar-beaconUUIDs";
    public static let Host = "radar-host";
    public static let DefaultHost = "https://api.radar.io";
    public static let LastTrackedTime = "radar-lastTrackedTime";
    public static let VerifiedHost = "radar-verifiedHost";
    public static let DefaultVerifiedHost = "https://api-verified.radar.io";
    public static let LastAppOpenTime = "radar-lastAppOpenTime";
    public static let UserDebug = "radar-userDebug";
    public static let XPlatformSDKType = "radar-xPlatformSDKType";
    public static let XPlatformSDKVersion = "radar-xPlatformSDKVersion";
    public static let InitializeOptions = "radar-initializeOptions";
    public static let UserTags = "radar-userTags";
    
    public static func settings(_ value: String, forKey key: String) {
        UserDefaults(suiteName: "RadarSDK")?.set(value, forKey: key)
    }
    
    public static func string(key: String) -> String? {
        return UserDefaults(suiteName: "RadarSDK")?.string(forKey: key)
    }
}
