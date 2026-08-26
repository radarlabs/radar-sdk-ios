//
//  RadarInitializeOptions.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarInitializeOptions)
@objcMembers
class RadarInitializeOptions: NSObject {
    private static let defaultNetworkTimeoutInterval: TimeInterval = 10
    private static let defaultIPChangeDebounceInterval: TimeInterval = 10

    var autoLogNotificationConversions = false
    var autoHandleNotificationDeepLinks = false
    var silentPush = false
    var trackVerifiedAutoFailover = false

    /// Request and resource timeout in seconds for standard API calls. Default 10 seconds.
    /// Invalid values (non-finite or ≤ 0) fall back to the default.
    var networkTimeoutInterval: TimeInterval = RadarInitializeOptions.defaultNetworkTimeoutInterval

    /// Minimum interval in seconds between deliveries of `RadarVerifiedDelegate.didChangeIP()`.
    /// Default 10 seconds. Set to 0 to disable throttling (deliver every detected change).
    /// Negative or non-finite values fall back to the default.
    var ipChangeDebounceInterval: TimeInterval = RadarInitializeOptions.defaultIPChangeDebounceInterval

    override init() {
        super.init()
    }

    @objc(initWithDict:)
    init(dict: [String: Any]?) {
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
        super.init()
    }

    func dictionaryValue() -> [String: Any] {
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
