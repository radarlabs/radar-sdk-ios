//
//  RadarVerificationHelpers.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/9/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Network
import Testing

@testable import RadarSDK

/// Stand-in for the Objective-C instance that currently backs the Swift twin's
/// state, so the implemented Swift methods can be exercised in isolation.
final class StubRadarVerificationManagerHost: NSObject, RadarVerificationManagerSwiftHost, @unchecked Sendable {
    var startedInterval: TimeInterval = 0
    var startedBeacons = false
    var intervalTimer: Timer?
    var monitor: nw_path_monitor_t?
    var lastToken: RadarVerifiedLocationToken?
    var lastTokenSystemUptime: TimeInterval = 0
    var lastTokenBeacons = false
    var lastIPs: String?
    var lastIPChangeDeliveredAt: TimeInterval = 0
    var expectedCountryCode: String?
    var expectedStateCode: String?
    var swiftInstance: RadarVerificationManager?
}

/// The Objective-C `RadarVerificationManager`, reached through the runtime.
///
/// `RadarVerificationManager.h` is a project header; importing it into the test
/// bridging header would make the unqualified name ambiguous with the Swift twin
/// (which is `RadarVerificationManagerSwift` only to Objective-C). The properties
/// this wrapper reads live in the `.m`'s class extension, so they are reached with
/// KVC rather than a declared interface. KVC is also the safe way to call the
/// `BOOL`-returning selectors — `perform(_:)` would misinterpret the return value.
struct ObjCVerificationManager {
    let instance: NSObject

    /// A throwaway instance, so a test can own the Objective-C side instead of
    /// sharing it. `RadarVerificationManager` has no custom `init`, so a fresh one
    /// starts with all state nil/zero and no timer or path monitor running. Its
    /// `swiftInstance` is nil, which means the flag dispatch in the `.m` can never
    /// fire — a fresh instance always takes the Objective-C path whatever
    /// `RadarSettings.sdkConfiguration` says, so tests using one do not race on
    /// that global and can run in parallel.
    static func makeFresh() -> ObjCVerificationManager? {
        guard let managerClass = NSClassFromString("RadarVerificationManager") as? NSObject.Type else {
            return nil
        }
        return ObjCVerificationManager(instance: managerClass.init())
    }

    /// The process-wide instance the Objective-C dispatcher actually talks to. Only
    /// the flag-dispatch tests need this; everything else should use `makeFresh()`.
    static var shared: ObjCVerificationManager? {
        guard let managerClass = NSClassFromString("RadarVerificationManager") as? NSObject.Type,
            let result = managerClass.perform(NSSelectorFromString("sharedInstance")),
            let instance = result.takeUnretainedValue() as? NSObject
        else {
            return nil
        }
        return ObjCVerificationManager(instance: instance)
    }

    /// The Swift twin the `.m` dispatches to, if one has been installed.
    var swiftInstance: NSObject? {
        get { instance.value(forKey: "swiftInstance") as? NSObject }
        nonmutating set { instance.setValue(newValue, forKey: "swiftInstance") }
    }

    /// The host seam the Swift twin needs in order to reach this instance's state.
    var asSwiftHost: RadarVerificationManagerSwiftHost? {
        instance as? RadarVerificationManagerSwiftHost
    }

    var expectedCountryCode: String? {
        get { instance.value(forKey: "expectedCountryCode") as? String }
        nonmutating set { instance.setValue(newValue, forKey: "expectedCountryCode") }
    }

    var expectedStateCode: String? {
        get { instance.value(forKey: "expectedStateCode") as? String }
        nonmutating set { instance.setValue(newValue, forKey: "expectedStateCode") }
    }

    var lastToken: RadarVerifiedLocationToken? {
        get { instance.value(forKey: "lastToken") as? RadarVerifiedLocationToken }
        nonmutating set { instance.setValue(newValue, forKey: "lastToken") }
    }

    var lastTokenSystemUptime: TimeInterval {
        get { instance.value(forKey: "lastTokenSystemUptime") as? TimeInterval ?? 0 }
        nonmutating set { instance.setValue(newValue, forKey: "lastTokenSystemUptime") }
    }

    /// Private to the `.m`, so it is only reachable by key.
    func isLastTokenValid() -> Bool {
        instance.value(forKey: "isLastTokenValid") as? Bool ?? false
    }

    func setExpectedJurisdiction(countryCode: String, stateCode: String) {
        _ = instance.perform(
            NSSelectorFromString("setExpectedJurisdictionWithCountryCode:stateCode:"),
            with: countryCode,
            with: stateCode
        )
    }

    func isSharing() -> Bool {
        instance.value(forKey: "isSharing") as? Bool ?? false
    }

    func clearSharing() {
        _ = instance.perform(NSSelectorFromString("clearSharing"))
    }

    func clearVerifiedLocationToken() {
        _ = instance.perform(NSSelectorFromString("clearVerifiedLocationToken"))
    }
}

// MARK: - Fixtures

enum RadarVerificationManagerSwiftTestHelpers {

    /// `isLastTokenValid` reads exactly four fields off the token: `expiresIn`,
    /// `passed`, and `user.state.distanceToBorder`, plus the stored uptime. Build a
    /// real token through the internal JSON initializer so both implementations see
    /// identical input.
    static func makeToken(
        passed: Bool = true,
        expiresIn: TimeInterval = 90,
        distanceToStateBorder: Double? = 5000
    ) -> RadarVerifiedLocationToken {
        var user: [String: Any] = [
            "_id": "test-user-id",
            "location": ["coordinates": [-73.9, 40.7]],
        ]
        if let distanceToStateBorder {
            user["state"] = [
                "_id": "test-state-id",
                "name": "New York",
                "code": "NY",
                "type": "state",
                "distanceToBorder": distanceToStateBorder,
            ]
        }

        let dict: [String: Any] = [
            "token": "test-token",
            "expiresAt": RadarUtils.isoDateFormatter.string(from: Date().addingTimeInterval(expiresIn)),
            "expiresIn": expiresIn,
            "passed": passed,
            "failureReasons": [],
            "_id": "test-token-id",
            "user": user,
            "events": [],
        ]

        guard let token = RadarVerifiedLocationToken(object: dict) else {
            preconditionFailure("failed to build a RadarVerifiedLocationToken fixture")
        }
        return token
    }

    static func makeSwiftManager(host: RadarVerificationManagerSwiftHost?) -> RadarVerificationManager {
        RadarVerificationManager(
            apiClient: RadarAPIClient.shared,
            fraudSDK: RadarSDKFraud.shared,
            locationManagerHost: nil as RadarLocationManagerSwiftHost?,
            verificationmanagerHost: host
        )
    }

    static func enableSwiftVerificationManager(_ enabled: Bool) {
        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftVerificationManager": enabled])
    }

    /// The Objective-C manager is a process-wide singleton, so every test that
    /// writes to it has to hand it back in the state it found it in.
    static func withRestoredObjCState(_ body: (ObjCVerificationManager) throws -> Void) throws {
        let objcManager = try #require(ObjCVerificationManager.shared)

        let originalConfiguration = RadarSettings.sdkConfiguration
        let originalToken = objcManager.lastToken
        let originalUptime = objcManager.lastTokenSystemUptime
        let originalCountryCode = objcManager.expectedCountryCode
        let originalStateCode = objcManager.expectedStateCode
        defer {
            RadarSettings.sdkConfiguration = originalConfiguration
            objcManager.lastToken = originalToken
            objcManager.lastTokenSystemUptime = originalUptime
            objcManager.expectedCountryCode = originalCountryCode
            objcManager.expectedStateCode = originalStateCode
        }

        try body(objcManager)
    }
}
