//
//  RadarFraud.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents fraud detection signals for location verification.
///
/// - Warning: Note that these values should not be trusted unless you called `trackVerified()` instead of
///   `trackOnce()`.
///
/// - SeeAlso: https://radar.com/documentation/fraud
@objc(RadarFraud)
@objcMembers
public final class RadarFraud: NSObject {
    /// A boolean indicating whether the user passed fraud detection checks. May be `false` if Fraud is not enabled.
    public let passed: Bool
    /// A boolean indicating whether fraud detection checks were bypassed for the user for testing. May be `false`
    /// if Fraud is not enabled.
    public let bypassed: Bool
    /// A boolean indicating whether the request was made with SSL pinning configured successfully. May be `false`
    /// if Fraud is not enabled.
    public let verified: Bool
    /// A boolean indicating whether the user's IP address is a known proxy. May be `false` if Fraud is not enabled.
    public let proxy: Bool
    /// A boolean indicating whether the user's location is being mocked, such as in the simulator or using a
    /// location spoofing app. May be `false` if Fraud is not enabled.
    public let mocked: Bool
    /// A boolean indicating whether the user's device or app has been compromised according to `DeviceCheck`. May
    /// be `false` if Fraud is not enabled.
    ///
    /// - SeeAlso: https://developer.apple.com/documentation/devicecheck
    public let compromised: Bool
    /// A boolean indicating whether the user moved too far too fast. May be `false` if Fraud is not enabled.
    public let jumped: Bool
    /// A boolean indicating whether the user's location is not accurate enough. May be `false` if Fraud is not
    /// enabled.
    public let inaccurate: Bool
    /// A boolean indicating whether the user's location is not accurate enough. May be `false` if Fraud is not
    /// enabled.
    public let sharing: Bool
    /// A boolean indicating whether the user has been manually blocked. May be `false` if Fraud is not enabled.
    public let blocked: Bool

    override init() {
        passed = false
        bypassed = false
        verified = false
        proxy = false
        mocked = false
        compromised = false
        jumped = false
        inaccurate = false
        sharing = false
        blocked = false
        super.init()
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        [
            "passed": NSNumber(value: passed),
            "bypassed": NSNumber(value: bypassed),
            "verified": NSNumber(value: verified),
            "proxy": NSNumber(value: proxy),
            "mocked": NSNumber(value: mocked),
            "compromised": NSNumber(value: compromised),
            "jumped": NSNumber(value: jumped),
            "inaccurate": NSNumber(value: inaccurate),
            "sharing": NSNumber(value: sharing),
            "blocked": NSNumber(value: blocked),
        ]
    }

    /// Mirrors the legacy `asBool:` helper: anything that is not a number reads as `false`.
    internal static func boolValue(_ value: Any?) -> Bool {
        (value as? NSNumber)?.boolValue ?? false
    }

    // Keeps the hand-written Objective-C header's designated initializer selector working.
    @objc(initWithPassed:bypassed:verified:proxy:mocked:compromised:jumped:inaccurate:sharing:blocked:)
    init(
        passed: Bool,
        bypassed: Bool,
        verified: Bool,
        proxy: Bool,
        mocked: Bool,
        compromised: Bool,
        jumped: Bool,
        inaccurate: Bool,
        sharing: Bool,
        blocked: Bool
    ) {
        self.passed = passed
        self.bypassed = bypassed
        self.verified = verified
        self.proxy = proxy
        self.mocked = mocked
        self.compromised = compromised
        self.jumped = jumped
        self.inaccurate = inaccurate
        self.sharing = sharing
        self.blocked = blocked
    }

    // Keeps the hand-written Objective-C header's `initWithObject:` selector working.
    @objc(initWithObject:)
    init?(object: Any) {
        guard let dictionary = object as? NSDictionary else {
            return nil
        }

        passed = Self.boolValue(dictionary["passed"])
        bypassed = Self.boolValue(dictionary["bypassed"])
        verified = Self.boolValue(dictionary["verified"])
        proxy = Self.boolValue(dictionary["proxy"])
        mocked = Self.boolValue(dictionary["mocked"])
        compromised = Self.boolValue(dictionary["compromised"])
        jumped = Self.boolValue(dictionary["jumped"])
        inaccurate = Self.boolValue(dictionary["inaccurate"])
        sharing = Self.boolValue(dictionary["sharing"])
        blocked = Self.boolValue(dictionary["blocked"])
    }
}
