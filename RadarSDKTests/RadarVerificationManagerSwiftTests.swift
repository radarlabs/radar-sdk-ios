//
//  RadarVerificationManagerSwiftTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//
//  Covers the Swift twin of `RadarVerificationManager` while the class is
//  mid-migration. Three things are checked, in this order:
//
//  1. Every implemented Swift method runs without crashing and returns the same
//     answer as the Objective-C original for the same state.
//  2. With `useSwiftVerificationManager` on and `swiftInstance` installed, calling
//     the Objective-C method routes into Swift and still lands on the Objective-C
//     properties (the Swift twin's state is backed by the ObjC instance).
//  3. State written on the Objective-C side *before* the flag is turned on is
//     visible to the Swift twin afterwards.
//

import Foundation
import Network
import Testing

@testable import RadarSDK

// MARK: - Test doubles

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

    static var shared: ObjCVerificationManager? {
        guard let managerClass = NSClassFromString("RadarVerificationManager") as? NSObject.Type,
            let result = managerClass.perform(NSSelectorFromString("sharedInstance")),
            let instance = result.takeUnretainedValue() as? NSObject
        else {
            return nil
        }
        return ObjCVerificationManager(instance: instance)
    }

    var swiftInstance: AnyObject? {
        instance.value(forKey: "swiftInstance") as AnyObject?
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

    static func makeSwiftManager(host: StubRadarVerificationManagerHost) -> RadarVerificationManager {
        RadarVerificationManager(
            apiClient: RadarAPIClient.shared,
            fraudSDK: RadarSDKFraud.shared,
            locationManagerHost: nil,
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

// MARK: - 1. Implemented methods run and agree with Objective-C

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarVerificationManagerSwiftTests {

        private typealias Helpers = RadarVerificationManagerSwiftTestHelpers

        /// The four `isLastTokenValid` inputs, plus the boundary cases of the
        /// 1609 m / `expiresIn` comparisons.
        static let tokenCases: [(name: String, passed: Bool, expiresIn: TimeInterval, distance: Double?, elapsed: TimeInterval)] = [
            ("valid token", true, 90, 5000, 0),
            ("expired token", true, 90, 5000, 120),
            ("token that did not pass", false, 90, 5000, 0),
            ("token inside the state border buffer", true, 90, 1000, 0),
            ("token exactly on the border buffer", true, 90, 1609, 0),
            ("token with no state", true, 90, nil, 0),
            ("token with a zero lifetime", true, 0, 5000, 0),
        ]

        // MARK: isLastTokenValid

        @Test("isLastTokenValid matches the ObjC implementation", arguments: tokenCases)
        func isLastTokenValidMatchesObjC(
            testCase: (name: String, passed: Bool, expiresIn: TimeInterval, distance: Double?, elapsed: TimeInterval)
        ) throws {
            try Helpers.withRestoredObjCState { objcManager in
                let token = Helpers.makeToken(
                    passed: testCase.passed,
                    expiresIn: testCase.expiresIn,
                    distanceToStateBorder: testCase.distance
                )
                let uptime = ProcessInfo.processInfo.systemUptime - testCase.elapsed

                let host = StubRadarVerificationManagerHost()
                host.lastToken = token
                host.lastTokenSystemUptime = uptime
                let swiftManager = Helpers.makeSwiftManager(host: host)

                Helpers.enableSwiftVerificationManager(false)
                objcManager.lastToken = token
                objcManager.lastTokenSystemUptime = uptime

                #expect(
                    swiftManager.isLastTokenValid() == objcManager.isLastTokenValid(),
                    "\(testCase.name): Swift and ObjC disagreed"
                )
            }
        }

        @Test("isLastTokenValid is false with no token, on both implementations")
        func isLastTokenValidWithoutToken() throws {
            try Helpers.withRestoredObjCState { objcManager in
                Helpers.enableSwiftVerificationManager(false)
                objcManager.lastToken = nil

                let swiftManager = Helpers.makeSwiftManager(host: StubRadarVerificationManagerHost())

                #expect(swiftManager.isLastTokenValid() == false)
                #expect(objcManager.isLastTokenValid() == false)
            }
        }

        // MARK: clearVerifiedLocationToken

        @Test("clearVerifiedLocationToken clears the token on both implementations")
        func clearVerifiedLocationTokenMatchesObjC() throws {
            try Helpers.withRestoredObjCState { objcManager in
                Helpers.enableSwiftVerificationManager(false)

                let host = StubRadarVerificationManagerHost()
                host.lastToken = Helpers.makeToken()
                let swiftManager = Helpers.makeSwiftManager(host: host)

                swiftManager.clearVerifiedLocationToken()
                #expect(host.lastToken == nil)
                #expect(swiftManager.isLastTokenValid() == false)

                objcManager.lastToken = Helpers.makeToken()
                objcManager.clearVerifiedLocationToken()
                #expect(objcManager.lastToken == nil)
                #expect(objcManager.isLastTokenValid() == false)
            }
        }

        // MARK: setExpectedJurisdiction

        @Test("setExpectedJurisdiction stores both codes on both implementations")
        func setExpectedJurisdictionMatchesObjC() throws {
            try Helpers.withRestoredObjCState { objcManager in
                Helpers.enableSwiftVerificationManager(false)

                let host = StubRadarVerificationManagerHost()
                let swiftManager = Helpers.makeSwiftManager(host: host)

                swiftManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NY")
                #expect(host.expectedCountryCode == "US")
                #expect(host.expectedStateCode == "NY")

                objcManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NY")
                #expect(objcManager.expectedCountryCode == host.expectedCountryCode)
                #expect(objcManager.expectedStateCode == host.expectedStateCode)
            }
        }

        // MARK: isSharing / clearSharing

        @Test("isSharing returns the same answer as the ObjC implementation")
        func isSharingMatchesObjC() throws {
            try Helpers.withRestoredObjCState { objcManager in
                Helpers.enableSwiftVerificationManager(false)

                let swiftManager = Helpers.makeSwiftManager(host: StubRadarVerificationManagerHost())

                #expect(swiftManager.isSharing() == objcManager.isSharing())
            }
        }

        @Test("clearSharing runs on both implementations and leaves isSharing agreeing")
        func clearSharingMatchesObjC() throws {
            try Helpers.withRestoredObjCState { objcManager in
                Helpers.enableSwiftVerificationManager(false)

                let swiftManager = Helpers.makeSwiftManager(host: StubRadarVerificationManagerHost())

                swiftManager.clearSharing()
                objcManager.clearSharing()

                #expect(swiftManager.isSharing() == objcManager.isSharing())
            }
        }

        // MARK: Not-yet-ported methods

        @Test("the unported methods are callable and report failure instead of crashing")
        func unportedMethodsAreSafeToCall() async {
            let host = StubRadarVerificationManagerHost()
            let swiftManager = Helpers.makeSwiftManager(host: host)

            let (status, token) = await swiftManager.trackVerified()
            #expect(status == .errorUnknown)
            #expect(token == nil)

            let (statusWithOptions, tokenWithOptions) = await swiftManager.trackVerified(
                beacons: true,
                desiredAccuracy: .high,
                reason: "test",
                transactionId: "test-transaction-id"
            )
            #expect(statusWithOptions == .errorUnknown)
            #expect(tokenWithOptions == nil)

            await #expect(swiftManager.getVerifiedLocationToken(beacons: false, desiredAccuracy: .medium) == nil)

            // No-ops today; the assertion is that they neither crash nor touch host state.
            swiftManager.startTrackingVerified(interval: 60)
            swiftManager.updateMonitoringState()
            swiftManager.stopTrackingVerified()

            #expect(host.startedInterval == 0)
            #expect(host.intervalTimer == nil)
            #expect(host.monitor == nil)
        }
    }
}

// MARK: - 2. The flag routes the ObjC call into Swift, which writes ObjC state

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarVerificationManagerSwiftSeamTests {

        private typealias Helpers = RadarVerificationManagerSwiftTestHelpers

        /// Touching the Swift singleton is what installs `swiftInstance` on the
        /// Objective-C singleton, which is the other half of the seam's condition.
        private func installedSwiftSingleton(
            on objcManager: ObjCVerificationManager
        ) throws -> RadarVerificationManager {
            let swiftManager = RadarVerificationManager.shared
            let installed = try #require(
                objcManager.swiftInstance,
                "RadarVerificationManager.swiftInstance was never installed, so the ObjC seam can never fire"
            )
            #expect(installed === swiftManager)
            return swiftManager
        }

        @Test("with the flag on, the ObjC jurisdiction setter routes through Swift and still sets the ObjC properties")
        func objcSetExpectedJurisdictionRoutesThroughSwift() throws {
            try Helpers.withRestoredObjCState { objcManager in
                _ = try installedSwiftSingleton(on: objcManager)

                objcManager.expectedCountryCode = nil
                objcManager.expectedStateCode = nil
                Helpers.enableSwiftVerificationManager(true)

                objcManager.setExpectedJurisdiction(countryCode: "CA", stateCode: "ON")

                #expect(objcManager.expectedCountryCode == "CA")
                #expect(objcManager.expectedStateCode == "ON")
            }
        }

        @Test("with the flag on, the Swift singleton writes the jurisdiction straight onto the ObjC instance")
        func swiftSingletonWritesThroughToObjC() throws {
            try Helpers.withRestoredObjCState { objcManager in
                let swiftManager = try installedSwiftSingleton(on: objcManager)
                Helpers.enableSwiftVerificationManager(true)

                swiftManager.setExpectedJurisdiction(countryCode: "MX", stateCode: "JAL")

                #expect(objcManager.expectedCountryCode == "MX")
                #expect(objcManager.expectedStateCode == "JAL")
            }
        }

        @Test("with the flag on, clearVerifiedLocationToken on the Swift singleton clears the ObjC token")
        func swiftSingletonClearsObjCToken() throws {
            try Helpers.withRestoredObjCState { objcManager in
                let swiftManager = try installedSwiftSingleton(on: objcManager)
                Helpers.enableSwiftVerificationManager(true)

                objcManager.lastToken = Helpers.makeToken()
                swiftManager.clearVerifiedLocationToken()

                #expect(objcManager.lastToken == nil)
            }
        }

        @Test("with the flag on, the ObjC sharing calls route through Swift without changing the answer")
        func objcSharingCallsRouteThroughSwift() throws {
            try Helpers.withRestoredObjCState { objcManager in
                let swiftManager = try installedSwiftSingleton(on: objcManager)

                Helpers.enableSwiftVerificationManager(false)
                let objcSharing = objcManager.isSharing()

                Helpers.enableSwiftVerificationManager(true)
                #expect(objcManager.isSharing() == objcSharing)
                #expect(swiftManager.isSharing() == objcSharing)

                objcManager.clearSharing()
                #expect(objcManager.isSharing() == swiftManager.isSharing())
            }
        }
    }
}

// MARK: - 3. Swift sees ObjC state written before the flag was turned on

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarVerificationManagerSwiftBackedStateTests {

        private typealias Helpers = RadarVerificationManagerSwiftTestHelpers

        @Test("the Swift singleton reads a token that ObjC stored before the flag was enabled")
        func swiftReadsTokenStoredBeforeFlagEnabled() throws {
            try Helpers.withRestoredObjCState { objcManager in
                let swiftManager = RadarVerificationManager.shared
                try #require(objcManager.swiftInstance != nil)

                // Flag off: the ObjC instance owns the state.
                Helpers.enableSwiftVerificationManager(false)
                objcManager.lastToken = Helpers.makeToken()
                objcManager.lastTokenSystemUptime = ProcessInfo.processInfo.systemUptime
                #expect(objcManager.isLastTokenValid() == true)

                // Flag on: the Swift twin must observe the same state, not a stale copy.
                Helpers.enableSwiftVerificationManager(true)
                #expect(swiftManager.isLastTokenValid() == true)

                // And a subsequent ObjC write is picked up on the next Swift read.
                objcManager.lastToken = Helpers.makeToken(passed: false)
                #expect(swiftManager.isLastTokenValid() == false)
            }
        }

        @Test("the Swift singleton overwrites a jurisdiction that ObjC stored before the flag was enabled")
        func swiftOverwritesJurisdictionStoredBeforeFlagEnabled() throws {
            try Helpers.withRestoredObjCState { objcManager in
                let swiftManager = RadarVerificationManager.shared
                try #require(objcManager.swiftInstance != nil)

                Helpers.enableSwiftVerificationManager(false)
                objcManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NJ")
                #expect(objcManager.expectedCountryCode == "US")
                #expect(objcManager.expectedStateCode == "NJ")

                Helpers.enableSwiftVerificationManager(true)
                swiftManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NY")

                #expect(objcManager.expectedCountryCode == "US")
                #expect(objcManager.expectedStateCode == "NY")
            }
        }
    }
}
