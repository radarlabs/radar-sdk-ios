//
//  RadarVerificationManagerSwiftTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//
//  Covers the Swift twin of `RadarVerificationManager` while the class is
//  mid-migration. Three things are checked:
//
//  1. Every implemented Swift method runs without crashing and returns the same
//     answer as the Objective-C original for the same state.
//  2. Writes through the Swift twin land on the Objective-C properties that back
//     it, including when `useSwiftVerificationManager` routes an Objective-C call
//     into Swift.
//  3. State written on the Objective-C side is visible to the Swift twin
//     afterwards, including state written before the flag was turned on.
//
//  Everything that can own its instances does, so those tests run in parallel.
//  Only the flag-dispatch tests are serialized: the Objective-C dispatcher hops
//  to `[RadarVerificationManagerSwift sharedInstance]` and reads the process-wide
//  `RadarSettings.sdkConfiguration`, so it can only be exercised on the singletons.
//

import Foundation
import Testing

@testable import RadarSDK

private typealias Helpers = RadarVerificationManagerSwiftTestHelpers
@Suite("RadarVerificationManagerSwift")
struct RadarVerificationManagerSwiftTests {

    struct TokenCase: Sendable, CustomStringConvertible {
        let description: String
        let passed: Bool
        let expiresIn: TimeInterval
        let distanceToStateBorder: Double?
        let elapsed: TimeInterval
        let expectedValid: Bool
    }

    /// Cache validity depends on the verdict and lifetime, independent of border distance.
    static let tokenCases: [TokenCase] = [
        TokenCase(
            description: "valid token", passed: true, expiresIn: 90,
            distanceToStateBorder: 5000, elapsed: 0, expectedValid: true
        ),
        TokenCase(
            description: "expired token", passed: true, expiresIn: 90,
            distanceToStateBorder: 5000, elapsed: 120, expectedValid: false
        ),
        TokenCase(
            description: "token that did not pass", passed: false, expiresIn: 90,
            distanceToStateBorder: 5000, elapsed: 0, expectedValid: false
        ),
        TokenCase(
            description: "at the state border", passed: true, expiresIn: 90,
            distanceToStateBorder: 0, elapsed: 0, expectedValid: true
        ),
        TokenCase(
            description: "inside the former state border buffer", passed: true, expiresIn: 90,
            distanceToStateBorder: 1000, elapsed: 0, expectedValid: true
        ),
        TokenCase(
            description: "at the former buffer boundary", passed: true, expiresIn: 90,
            distanceToStateBorder: 1609, elapsed: 0, expectedValid: true
        ),
        TokenCase(
            description: "outside the former buffer boundary", passed: true, expiresIn: 90,
            distanceToStateBorder: 1610, elapsed: 0, expectedValid: true
        ),
        TokenCase(
            description: "no state on the user", passed: true, expiresIn: 90,
            distanceToStateBorder: nil, elapsed: 0, expectedValid: true
        ),
        TokenCase(
            description: "near border but expired", passed: true, expiresIn: 90,
            distanceToStateBorder: 1000, elapsed: 120, expectedValid: false
        ),
        TokenCase(
            description: "near border but did not pass", passed: false, expiresIn: 90,
            distanceToStateBorder: 1000, elapsed: 0, expectedValid: false
        ),
        TokenCase(
            description: "before expiration", passed: true, expiresIn: 90,
            distanceToStateBorder: nil, elapsed: 89, expectedValid: true
        ),
        TokenCase(
            description: "at expiration", passed: true, expiresIn: 90,
            distanceToStateBorder: nil, elapsed: 90, expectedValid: false
        ),
        TokenCase(
            description: "zero lifetime", passed: true, expiresIn: 0,
            distanceToStateBorder: nil, elapsed: 0, expectedValid: false
        ),
        TokenCase(
            description: "negative lifetime", passed: true, expiresIn: -1,
            distanceToStateBorder: nil, elapsed: 0, expectedValid: false
        ),
    ]

    // MARK: Implemented methods run and agree with Objective-C
    //
    // Each test owns a stub host for the Swift side and a throwaway Objective-C
    // instance for the reference answer, so the suite runs in parallel.

    // MARK: isLastTokenValid

    @Test("cache validity uses the verdict and lifetime on both implementations", arguments: tokenCases)
    func isLastTokenValidMatchesObjC(tokenCase: TokenCase) throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())
        let token = Helpers.makeToken(
            passed: tokenCase.passed,
            expiresIn: tokenCase.expiresIn,
            distanceToStateBorder: tokenCase.distanceToStateBorder
        )
        let uptime = ProcessInfo.processInfo.systemUptime - tokenCase.elapsed

        let host = StubRadarVerificationManagerHost()
        host.lastToken = token
        host.lastTokenSystemUptime = uptime
        let swiftManager = Helpers.makeSwiftManager(host: host)

        objcManager.lastToken = token
        objcManager.lastTokenSystemUptime = uptime

        #expect(swiftManager.isLastTokenValid() == tokenCase.expectedValid)
        #expect(objcManager.isLastTokenValid() == tokenCase.expectedValid)
    }

    @Test("isLastTokenValid is false with no token, on both implementations")
    func isLastTokenValidWithoutToken() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())
        let swiftManager = Helpers.makeSwiftManager(host: StubRadarVerificationManagerHost())

        #expect(swiftManager.isLastTokenValid() == false)
        #expect(objcManager.isLastTokenValid() == false)
    }

    @Test("isLastTokenValid does not crash when the Swift twin has no host yet")
    func isLastTokenValidWithoutHost() {
        let swiftManager = Helpers.makeSwiftManager(host: nil)

        #expect(swiftManager.isLastTokenValid() == false)
    }

    // MARK: clearVerifiedLocationToken

    @Test("clearVerifiedLocationToken clears the token on both implementations")
    func clearVerifiedLocationTokenMatchesObjC() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())

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

    // MARK: setExpectedJurisdiction

    @Test("setExpectedJurisdiction stores both codes on both implementations")
    func setExpectedJurisdictionMatchesObjC() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())

        let host = StubRadarVerificationManagerHost()
        let swiftManager = Helpers.makeSwiftManager(host: host)

        swiftManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NY")
        objcManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NY")

        #expect(host.expectedCountryCode == "US")
        #expect(host.expectedStateCode == "NY")
        #expect(objcManager.expectedCountryCode == host.expectedCountryCode)
        #expect(objcManager.expectedStateCode == host.expectedStateCode)
    }

    @Test("setExpectedJurisdiction overwrites a previously stored jurisdiction on both implementations")
    func setExpectedJurisdictionOverwritesMatchesObjC() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())

        let host = StubRadarVerificationManagerHost()
        let swiftManager = Helpers.makeSwiftManager(host: host)

        swiftManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NJ")
        swiftManager.setExpectedJurisdiction(countryCode: "CA", stateCode: "ON")
        objcManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NJ")
        objcManager.setExpectedJurisdiction(countryCode: "CA", stateCode: "ON")

        #expect(host.expectedCountryCode == "CA")
        #expect(host.expectedStateCode == "ON")
        #expect(objcManager.expectedCountryCode == host.expectedCountryCode)
        #expect(objcManager.expectedStateCode == host.expectedStateCode)
    }

    @Test("setExpectedJurisdiction does not crash when the Swift twin has no host yet")
    func setExpectedJurisdictionWithoutHost() {
        let swiftManager = Helpers.makeSwiftManager(host: nil)

        swiftManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NY")
    }

    // MARK: isSharing / clearSharing

    @Test("isSharing returns the same answer as the ObjC implementation")
    func isSharingMatchesObjC() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())
        let swiftManager = Helpers.makeSwiftManager(host: StubRadarVerificationManagerHost())

        #expect(swiftManager.isSharing() == objcManager.isSharing())
    }

    @Test("clearSharing runs on both implementations and leaves isSharing agreeing")
    func clearSharingMatchesObjC() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())
        let swiftManager = Helpers.makeSwiftManager(host: StubRadarVerificationManagerHost())

        swiftManager.clearSharing()
        objcManager.clearSharing()

        #expect(swiftManager.isSharing() == objcManager.isSharing())
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

        let verifiedToken = await swiftManager.getVerifiedLocationToken(beacons: false, desiredAccuracy: .medium)
        #expect(verifiedToken == nil)

        // No-ops today; the assertion is that they neither crash nor touch host state.
        swiftManager.startTrackingVerified(interval: 60)
        swiftManager.updateMonitoringState()
        swiftManager.stopTrackingVerified()

        #expect(host.startedInterval == 0)
        #expect(host.intervalTimer == nil)
        #expect(host.monitor == nil)
    }

    // MARK: The Swift twin reads and writes the Objective-C instance's state
    //
    // The twin holds no state of its own: every property is a pass-through to the
    // host. These tests own both the Swift manager and the Objective-C instance
    // backing it, so they run in parallel and need no flag.

    @Test("the Objective-C instance satisfies the host protocol the Swift twin needs")
    func objcInstanceConformsToHostProtocol() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())

        #expect(
            objcManager.instance is RadarVerificationManagerSwiftHost,
            "RadarVerificationManager must declare <RadarVerificationManagerSwiftHost>, or the Swift twin can never reach its state"
        )
    }

    @Test("a jurisdiction written through the Swift twin lands on the ObjC instance")
    func swiftWritesJurisdictionThroughToObjC() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())
        let host = try #require(objcManager.instance as? RadarVerificationManagerSwiftHost)
        let swiftManager = Helpers.makeSwiftManager(host: host)

        swiftManager.setExpectedJurisdiction(countryCode: "MX", stateCode: "JAL")

        #expect(objcManager.expectedCountryCode == "MX")
        #expect(objcManager.expectedStateCode == "JAL")
    }

    @Test("clearVerifiedLocationToken on the Swift twin clears the ObjC instance's token")
    func swiftClearsObjCToken() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())
        let host = try #require(objcManager.instance as? RadarVerificationManagerSwiftHost)
        let swiftManager = Helpers.makeSwiftManager(host: host)

        objcManager.lastToken = Helpers.makeToken()
        swiftManager.clearVerifiedLocationToken()

        #expect(objcManager.lastToken == nil)
    }

    @Test("the Swift twin reads a token the ObjC instance already held")
    func swiftReadsTokenWrittenByObjC() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())
        let host = try #require(objcManager.instance as? RadarVerificationManagerSwiftHost)

        // Written before the Swift twin exists, the way ObjC owns the state today.
        objcManager.lastToken = Helpers.makeToken()
        objcManager.lastTokenSystemUptime = ProcessInfo.processInfo.systemUptime

        let swiftManager = Helpers.makeSwiftManager(host: host)

        #expect(swiftManager.isLastTokenValid() == objcManager.isLastTokenValid())
        #expect(swiftManager.isLastTokenValid() == true)
    }

    @Test("the Swift twin re-reads the ObjC state on every call rather than caching it")
    func swiftReadsAreNotCached() throws {
        let objcManager = try #require(ObjCVerificationManager.makeFresh())
        let host = try #require(objcManager.instance as? RadarVerificationManagerSwiftHost)
        let swiftManager = Helpers.makeSwiftManager(host: host)

        objcManager.lastToken = Helpers.makeToken()
        objcManager.lastTokenSystemUptime = ProcessInfo.processInfo.systemUptime
        #expect(swiftManager.isLastTokenValid() == true)

        objcManager.lastToken = Helpers.makeToken(passed: false)
        #expect(swiftManager.isLastTokenValid() == false)

        objcManager.lastToken = nil
        #expect(swiftManager.isLastTokenValid() == false)
    }
}

// MARK: - The flag dispatch, which only exists on the singletons
//
// `RadarVerificationManager.m` hops to `[RadarVerificationManagerSwift sharedInstance]`
// and reads the process-wide `RadarSettings.sdkConfiguration`, so unlike everything
// above these tests cannot own their instances and have to be serialized.

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarVerificationManagerSwiftSeamTests {

        /// Hand the singletons to `body` and restore every process-wide value the
        /// test writes. Touching `RadarVerificationManager.shared` is what installs
        /// `swiftInstance` on the Objective-C singleton, the other half of the
        /// dispatch condition.
        private func withSharedManagers(
            _ body: (ObjCVerificationManager, RadarSDK.RadarVerificationManager) throws -> Void
        ) throws {
            try Helpers.withRestoredObjCState { objcManager in
                try body(objcManager, RadarSDK.RadarVerificationManager.shared)
            }
        }

        private func enableSwiftVerificationManager(_ enabled: Bool) {
            Helpers.enableSwiftVerificationManager(enabled)
        }

        @Test("the Swift singleton is installed on the ObjC singleton")
        func swiftSingletonIsInstalled() throws {
            try withSharedManagers { objcManager, swiftManager in
                let installed = try #require(
                    objcManager.swiftInstance,
                    "swiftInstance was never installed, so the ObjC dispatch can never fire"
                )
                let isSameInstance = ObjectIdentifier(installed) == ObjectIdentifier(swiftManager)
                #expect(isSameInstance)
            }
        }

        @Test("with the flag on, the ObjC jurisdiction setter routes through Swift and still sets the ObjC properties")
        func objcSetExpectedJurisdictionRoutesThroughSwift() throws {
            try withSharedManagers { objcManager, _ in
                try #require(objcManager.swiftInstance != nil)
                objcManager.expectedCountryCode = nil
                objcManager.expectedStateCode = nil

                enableSwiftVerificationManager(true)
                objcManager.setExpectedJurisdiction(countryCode: "CA", stateCode: "ON")

                #expect(objcManager.expectedCountryCode == "CA")
                #expect(objcManager.expectedStateCode == "ON")
            }
        }

        @Test("the ObjC jurisdiction setter gives the same result with the flag off and on")
        func objcSetExpectedJurisdictionAgreesAcrossTheFlag() throws {
            try withSharedManagers { objcManager, _ in
                enableSwiftVerificationManager(false)
                objcManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NJ")
                let objcCountryCode = objcManager.expectedCountryCode
                let objcStateCode = objcManager.expectedStateCode

                objcManager.expectedCountryCode = nil
                objcManager.expectedStateCode = nil

                enableSwiftVerificationManager(true)
                objcManager.setExpectedJurisdiction(countryCode: "US", stateCode: "NJ")

                #expect(objcManager.expectedCountryCode == objcCountryCode)
                #expect(objcManager.expectedStateCode == objcStateCode)
            }
        }

        @Test("the Swift singleton sees a token the ObjC singleton stored before the flag was enabled")
        func swiftSingletonReadsTokenStoredBeforeFlagEnabled() throws {
            try withSharedManagers { objcManager, swiftManager in
                try #require(objcManager.swiftInstance != nil)

                // Flag off: the ObjC instance owns the state.
                enableSwiftVerificationManager(false)
                objcManager.lastToken = Helpers.makeToken()
                objcManager.lastTokenSystemUptime = ProcessInfo.processInfo.systemUptime
                #expect(objcManager.isLastTokenValid() == true)

                // Flag on: the Swift twin must observe that same state, not a blank copy.
                enableSwiftVerificationManager(true)
                #expect(swiftManager.isLastTokenValid() == true)

                objcManager.lastToken = Helpers.makeToken(passed: false)
                #expect(swiftManager.isLastTokenValid() == false)
            }
        }

        @Test("the ObjC sharing calls give the same answer with the flag off and on")
        func objcSharingCallsAgreeAcrossTheFlag() throws {
            try withSharedManagers { objcManager, swiftManager in
                try #require(objcManager.swiftInstance != nil)

                enableSwiftVerificationManager(false)
                let objcSharing = objcManager.isSharing()

                enableSwiftVerificationManager(true)
                #expect(objcManager.isSharing() == objcSharing)
                #expect(swiftManager.isSharing() == objcSharing)

                objcManager.clearSharing()
                #expect(objcManager.isSharing() == swiftManager.isSharing())
            }
        }
    }
}
