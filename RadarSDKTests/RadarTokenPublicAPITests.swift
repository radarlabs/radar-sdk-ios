//
//  RadarTokenPublicAPITests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

// Deliberately NOT @testable: this file compiles against the SDK's public interface — the
// hand-written Objective-C headers — not the internal Swift implementations. Those headers are
// the only API customers see, and nothing else keeps them in sync with the implementation.
// The surface checks below fail to compile if the headers drift again: optional chaining and
// nil-coalescing are compile errors on non-optional values, so a field that is nil in JWE mode
// but declared nonnull in the header breaks the build, as does removing `format`.
import RadarSDK

struct RadarTokenPublicAPITests {

    /// Never called — compiling it is the assertion.
    private func revealRiskTokenPublicSurface(token: RadarRevealRiskToken) {
        // the wire format must be exposed publicly
        let format: RadarTokenFormat = token.format
        _ = format

        // nil in JWE mode, so the public header must declare these nullable
        _ = token.risk.reasons?.count
        _ = token.network?.ipAddress?.ip
        _ = token.network?.privacy?.vpn
        _ = token.network?.asn?.name
        _ = token.device?.deviceId
        _ = token.dictionaryValue()?.count

        // always present
        let tokenId: String = token._id
        _ = tokenId
        let risk: RadarRevealRiskTokenRisk = token.risk
        _ = risk.level == .high

        // optional metadata
        _ = token.token?.count
        _ = token.expiresAt?.timeIntervalSince1970
        _ = token.expiresIn?.doubleValue
    }

    /// Never called — compiling it is the assertion.
    private func verifiedLocationTokenPublicSurface(token: RadarVerifiedLocationToken) {
        // the wire format must be exposed publicly
        let format: RadarTokenFormat = token.format
        _ = format

        // nil in JWE mode, so the public header must declare these nullable
        _ = token.user?.userId
        _ = token.events?.count
        _ = token.failureReasons?.count

        _ = token.token?.count
        _ = token.expiresAt?.timeIntervalSince1970
        let expiresIn: TimeInterval = token.expiresIn
        _ = expiresIn
        let passed: Bool = token.passed
        _ = passed
    }

    @Test("RadarTokenFormat exposes stable JWS and JWE cases")
    func tokenFormatEnumIsStable() {
        #expect(RadarTokenFormat.jws.rawValue == 0)
        #expect(RadarTokenFormat.jwe.rawValue == 1)

        // reference the surface checks so they are part of the compiled, linted code paths
        _ = revealRiskTokenPublicSurface(token:)
        _ = verifiedLocationTokenPublicSurface(token:)
    }
}
