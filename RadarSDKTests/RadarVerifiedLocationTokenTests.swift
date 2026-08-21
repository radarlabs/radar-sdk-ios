//
//  RadarVerifiedLocationTokenTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

struct RadarVerifiedLocationTokenTests {

    private static var userDict: [String: Any] {
        [
            "_id": "user-123",
            "userId": "verified-user",
            "location": ["type": "Point", "coordinates": [-73.9867, 40.7043]],
            "locationAccuracy": 20,
        ]
    }

    /// A legacy (JWS) verified track response: user and events in plaintext next to the token.
    private static var jwsResponse: [String: Any] {
        [
            "_id": "location-123",
            "user": userDict,
            "events": [],
            "token": "aaa.bbb.ccc",
            "expiresAt": "2026-08-13T12:00:00.000Z",
            "expiresIn": 86400,
            "passed": true,
            "failureReasons": [],
            "format": "JWS",
        ]
    }

    /// A protected (JWE) verified track response: user, events, and failure reasons only exist
    /// inside the encrypted token.
    private static var jweResponse: [String: Any] {
        [
            "_id": "location-456",
            "token": "aaa.bbb.ccc.ddd.eee",
            "expiresAt": "2026-08-13T12:00:00.000Z",
            "expiresIn": 1200,
            "passed": true,
            "format": "JWE",
        ]
    }

    @Test("parses a legacy JWS response with user and events")
    func parsesJwsResponse() {
        let token = RadarVerifiedLocationToken(object: RadarVerifiedLocationTokenTests.jwsResponse)

        #expect(token != nil)
        #expect(token?.format == .jws)
        #expect(token?.user != nil)
        #expect(token?.user?._id == "user-123")
        #expect(token?.events != nil)
        #expect(token?.token == "aaa.bbb.ccc")
        #expect(token?.passed == true)
    }

    @Test("a response without a format field defaults to JWS")
    func missingFormatDefaultsToJws() {
        var response = RadarVerifiedLocationTokenTests.jwsResponse
        response["format"] = nil

        let token = RadarVerifiedLocationToken(object: response)

        #expect(token != nil)
        #expect(token?.format == .jws)
    }

    @Test("parses a protected JWE response without user and events")
    func parsesJweResponse() {
        let token = RadarVerifiedLocationToken(object: RadarVerifiedLocationTokenTests.jweResponse)

        #expect(token != nil)
        #expect(token?.format == .jwe)
        #expect(token?.user == nil)
        #expect(token?.events == nil)
        #expect(token?.failureReasons == nil)
        #expect(token?.token == "aaa.bbb.ccc.ddd.eee")
        #expect(token?.expiresIn == 1200)
        #expect(token?.passed == true)
        #expect(token?._id == "location-456")
    }

    @Test("a failed JWE response keeps failureReasons nil rather than reporting no failures")
    func failedJweResponsePreservesNilFailureReasons() {
        // in protected mode the reasons only exist inside the encrypted token, so a failed
        // check must surface nil (unavailable), not an empty array (no failures)
        var response = RadarVerifiedLocationTokenTests.jweResponse
        response["passed"] = false

        let token = RadarVerifiedLocationToken(object: response)

        #expect(token != nil)
        #expect(token?.format == .jwe)
        #expect(token?.passed == false)
        #expect(token?.failureReasons == nil)
    }

    @Test("a JWS response without failureReasons defaults to an empty array")
    func jwsResponseDefaultsFailureReasonsToEmpty() {
        var response = RadarVerifiedLocationTokenTests.jwsResponse
        response["failureReasons"] = nil

        let token = RadarVerifiedLocationToken(object: response)

        #expect(token != nil)
        #expect(token?.format == .jws)
        #expect(token?.failureReasons == [])
    }

    @Test("the format field is parsed case-insensitively")
    func parsesLowercaseJweFormat() {
        var response = RadarVerifiedLocationTokenTests.jweResponse
        response["format"] = "jwe"

        let token = RadarVerifiedLocationToken(object: response)

        #expect(token != nil)
        #expect(token?.format == .jwe)
    }

    @Test("a JWS response without user and events does not parse")
    func jwsResponseRequiresUserAndEvents() {
        var response = RadarVerifiedLocationTokenTests.jwsResponse
        response["user"] = nil
        response["events"] = nil

        let token = RadarVerifiedLocationToken(object: response)

        #expect(token == nil)
    }

    @Test("a JWE response still requires token and expiresAt")
    func jweResponseRequiresTokenAndExpiresAt() {
        var missingToken = RadarVerifiedLocationTokenTests.jweResponse
        missingToken["token"] = nil
        #expect(RadarVerifiedLocationToken(object: missingToken) == nil)

        var missingExpiresAt = RadarVerifiedLocationTokenTests.jweResponse
        missingExpiresAt["expiresAt"] = nil
        #expect(RadarVerifiedLocationToken(object: missingExpiresAt) == nil)
    }
}
