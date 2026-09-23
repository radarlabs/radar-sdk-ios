//
//  RadarInitializeOptions.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarInitializeOptions)
public class RadarInitializeOptions: NSObject {
    private static let defaultNetworkTimeoutInterval: TimeInterval = 10
    private static let defaultIPChangeDebounceInterval: TimeInterval = 10

    @objc public var autoLogNotificationConversions: Bool
    @objc public var autoHandleNotificationDeepLinks: Bool
    @objc public var silentPush: Bool
    @objc public var trackVerifiedAutoFailover: Bool

    /// Request and resource timeout in seconds for standard API calls. Default 10 seconds.
    /// Invalid values (non-finite or ≤ 0) fall back to the default.
    @objc public var networkTimeoutInterval: TimeInterval

    /// Minimum interval in seconds between deliveries of `RadarVerifiedDelegate.didChangeIP()`.
    /// Default 10 seconds. Set to 0 to disable throttling (deliver every detected change).
    /// Negative or non-finite values fall back to the default.
    @objc public var ipChangeDebounceInterval: TimeInterval

    @objc public override init() {
        autoLogNotificationConversions = false
        autoHandleNotificationDeepLinks = false
        silentPush = false
        trackVerifiedAutoFailover = false
        networkTimeoutInterval = RadarInitializeOptions.defaultNetworkTimeoutInterval
        ipChangeDebounceInterval = RadarInitializeOptions.defaultIPChangeDebounceInterval
        super.init()
    }

    @objc public init(dict: [AnyHashable: Any]?) {
        autoLogNotificationConversions = RadarInitializeOptions.parseBool(dict?["autoLogNotificationConversions"])
        autoHandleNotificationDeepLinks = RadarInitializeOptions.parseBool(dict?["autoHandleNotificationDeepLinks"])
        silentPush = RadarInitializeOptions.parseBool(dict?["silentPush"])
        trackVerifiedAutoFailover = RadarInitializeOptions.parseBool(dict?["trackVerifiedAutoFailover"])
        networkTimeoutInterval = RadarInitializeOptions.safeParseTimeInterval(
            dict?["networkTimeoutInterval"],
            allowsZero: false,
            defaultValue: RadarInitializeOptions.defaultNetworkTimeoutInterval)
        ipChangeDebounceInterval = RadarInitializeOptions.safeParseTimeInterval(
            dict?["ipChangeDebounceInterval"],
            allowsZero: true,
            defaultValue: RadarInitializeOptions.defaultIPChangeDebounceInterval)
    }

    @objc public func dictionaryValue() -> [AnyHashable: Any] {
        [
            "autoLogNotificationConversions": autoLogNotificationConversions,
            "autoHandleNotificationDeepLinks": autoHandleNotificationDeepLinks,
            "silentPush": silentPush,
            "trackVerifiedAutoFailover": trackVerifiedAutoFailover,
            "networkTimeoutInterval": networkTimeoutInterval,
            "ipChangeDebounceInterval": ipChangeDebounceInterval,
        ]
    }

    /// Accepts both the numbers a property list round trip produces and the strings a
    /// cross-platform wrapper may pass, matching what `-[NSObject boolValue]` did here.
    private static func parseBool(_ value: Any?) -> Bool {
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let string = value as? String {
            return (string as NSString).boolValue
        }
        return false
    }

    /// Missing, unparseable, non-finite, and disallowed non-positive values fall back to the default.
    /// `allowsZero` keeps 0 for debounce intervals, where it means "no throttling".
    private static func safeParseTimeInterval(
        _ value: Any?, allowsZero: Bool, defaultValue: TimeInterval
    ) -> TimeInterval {
        let interval: TimeInterval
        if let number = value as? NSNumber {
            interval = number.doubleValue
        } else if let string = value as? String {
            interval = (string as NSString).doubleValue
        } else {
            return defaultValue
        }

        guard interval.isFinite else {
            return defaultValue
        }
        if allowsZero ? interval < 0 : interval <= 0 {
            return defaultValue
        }
        return interval
    }
}
