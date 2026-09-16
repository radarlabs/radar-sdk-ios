//
//  RadarFraud.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarFraud)
@objcMembers
final class RadarFraud: NSObject {
    let passed: Bool
    let bypassed: Bool
    let verified: Bool
    let proxy: Bool
    let mocked: Bool
    let compromised: Bool
    let jumped: Bool
    let inaccurate: Bool
    let sharing: Bool
    let blocked: Bool

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

    /// Keeps the hand-written Objective-C header's designated initializer selector working.
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
        super.init()
    }

    /// Keeps the hand-written Objective-C header's `initWithObject:` selector working.
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
        super.init()
    }

    func dictionaryValue() -> [String: Any] {
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
    private static func boolValue(_ value: Any?) -> Bool {
        (value as? NSNumber)?.boolValue ?? false
    }
}
