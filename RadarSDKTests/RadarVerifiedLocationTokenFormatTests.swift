//
//  RadarVerifiedLocationTokenFormatTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/11/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarVerifiedLocationToken formats")
struct RadarVerifiedLocationTokenFormatTests {
    private func jweObject() -> [String: Any] {
        [
            "format": "jwe",
            "_id": "evaluation-id",
            "token": "opaque-token",
            "expiresAt": "2026-11-11T12:00:00.000Z",
            "expiresIn": 90,
            "passed": true,
            "meta": ["code": 200],
        ]
    }

    private func legacyObject() -> [String: Any] {
        [
            "_id": "evaluation-id",
            "token": "signed-token",
            "expiresAt": "2026-11-11T12:00:00.000Z",
            "expiresIn": 90,
            "passed": true,
            "user": [
                "_id": "user-id",
                "location": ["coordinates": [-73.9, 40.7]],
            ],
            "events": [],
            "failureReasons": [],
            "extra": "preserved",
        ]
    }

    @Test(arguments: [false, true])
    func parsesLegacyAndExplicitJWS(explicitFormat: Bool) throws {
        var object = legacyObject()
        if explicitFormat {
            object["format"] = "jws"
        }

        let token = try #require(RadarVerifiedLocationToken(object: object))

        #expect(token.format == .jws)
        #expect(token.user?._id == "user-id")
        #expect(token.events?.isEmpty == true)
        #expect(token.token == "signed-token")
        #expect(NSDictionary(dictionary: token.dictionaryValue()).isEqual(to: object))
    }

    @Test
    func parsesJWEWithoutSensitiveFields() throws {
        let object = jweObject()
        let token = try #require(RadarVerifiedLocationToken(object: object))

        #expect(token.format == .jwe)
        #expect(token._id == "evaluation-id")
        #expect(token.token == "opaque-token")
        #expect(
            token.expiresAt
                == ISO8601DateFormatter().date(from: "2026-11-11T12:00:00Z")
        )
        #expect(token.expiresIn == 90)
        #expect(token.passed)
        #expect(token.user == nil)
        #expect(token.events == nil)
        #expect(token.failureReasons == nil)
        #expect(NSDictionary(dictionary: token.dictionaryValue()).isEqual(to: object))
    }

    @Test(arguments: ["_id", "token", "expiresAt", "expiresIn", "passed"])
    func rejectsMissingJWEFields(key: String) {
        var object = jweObject()
        object[key] = nil

        #expect(RadarVerifiedLocationToken(object: object) == nil)
    }

    @Test
    func rejectsMalformedJWEFields() {
        let cases: [(String, [Any])] = [
            ("_id", [NSNull(), 1, ""]),
            ("token", [NSNull(), 1, ""]),
            ("expiresAt", [NSNull(), 1, "", "not a date"]),
            ("expiresIn", [NSNull(), "90", true, Double.nan, Double.infinity]),
            ("passed", [NSNull(), "true", 0, 1]),
        ]

        for (key, values) in cases {
            for value in values {
                var object = jweObject()
                object[key] = value

                #expect(
                    RadarVerifiedLocationToken(object: object) == nil,
                    "Accepted malformed \(key): \(value)"
                )
            }
        }
    }

    @Test(arguments: [
        "2026-11-11T12:00:00.000Z",
        "2026-11-11T12:00:00Z",
        "2026-11-11T07:00:00-05:00",
    ])
    func parsesJWEDates(value: String) throws {
        var object = jweObject()
        object["expiresAt"] = value

        let token = try #require(RadarVerifiedLocationToken(object: object))

        #expect(
            token.expiresAt
                == ISO8601DateFormatter().date(from: "2026-11-11T12:00:00Z")
        )
    }

    @Test
    func parsesFailedAndExpiredEvaluations() throws {
        var object = jweObject()
        object["passed"] = false
        object["expiresIn"] = 0
        object["expiresAt"] = "2020-01-01T00:00:00Z"

        let token = try #require(RadarVerifiedLocationToken(object: object))

        #expect(token.format == .jwe)
        #expect(!token.passed)
        #expect(token.expiresIn == 0)
        #expect(
            token.expiresAt
                == ISO8601DateFormatter().date(from: "2020-01-01T00:00:00Z")
        )
    }

    @Test
    func stripsUnapprovedJWEFields() throws {
        var object = jweObject()
        object["user"] = ["_id": "unexpected-user"]
        object["events"] = ["unexpected-event"]
        object["failureReasons"] = ["unexpected-reason"]
        object["warningReasons"] = ["unexpected-warning"]
        object["distanceToBorder"] = 5_000

        let token = try #require(RadarVerifiedLocationToken(object: object))
        let dictionary = token.dictionaryValue()

        #expect(token.user == nil)
        #expect(token.events == nil)
        #expect(token.failureReasons == nil)
        #expect(NSDictionary(dictionary: dictionary).isEqual(to: jweObject()))
        #expect(
            NSDictionary(dictionary: try #require(token.fullDict))
                .isEqual(to: jweObject())
        )
    }

    @Test
    func parsesIDWithoutTokenOrVerdict() throws {
        let object: [String: Any] = [
            "format": "id",
            "_id": "lookup-id",
            "meta": ["code": 200],
        ]
        let token = try #require(RadarVerifiedLocationToken(object: object))

        #expect(token.format == .id)
        #expect(token._id == "lookup-id")
        #expect(token.token == nil)
        #expect(token.expiresAt == nil)
        #expect(token.expiresIn == 0)
        #expect(!token.passed)
        #expect(token.user == nil)
        #expect(token.events == nil)
        #expect(token.failureReasons == nil)
        #expect(NSDictionary(dictionary: token.dictionaryValue()).isEqual(to: object))
    }

    @Test
    func rejectsMissingOrMalformedID() {
        for value in [nil, NSNull(), "", 1] as [Any?] {
            var object: [String: Any] = ["format": "id"]
            object["_id"] = value

            #expect(RadarVerifiedLocationToken(object: object) == nil)
        }
    }

    @Test
    func IDIgnoresFieldsFromOtherFormats() throws {
        var object = legacyObject()
        object["format"] = "id"

        let token = try #require(RadarVerifiedLocationToken(object: object))

        #expect(token.token == nil)
        #expect(token.expiresAt == nil)
        #expect(token.expiresIn == 0)
        #expect(!token.passed)
        #expect(token.user == nil)
        #expect(token.events == nil)
        #expect(token.failureReasons == nil)
        #expect(
            NSDictionary(dictionary: token.dictionaryValue()).isEqual(to: [
                "format": "id",
                "_id": "evaluation-id",
            ])
        )
    }

    @Test
    func rejectsUnknownOrMalformedFormats() {
        for format in ["unknown", "", NSNull(), true, 1] as [Any] {
            var object = legacyObject()
            object["format"] = format

            #expect(RadarVerifiedLocationToken(object: object) == nil)
        }
    }

    @Test
    func declaredFormatsDoNotFallBackToLegacyParsing() {
        for format in ["jwe", "id"] {
            var object = legacyObject()
            object["format"] = format
            object["_id"] = nil

            #expect(RadarVerifiedLocationToken(object: object) == nil)
        }
    }

    @Test
    func emptyTokenDefaultsToLegacyFormat() {
        #expect(RadarVerifiedLocationToken().format == .jws)
    }

    @Test
    func exposesFormatToObjectiveC() throws {
        let token = try #require(RadarVerifiedLocationToken(object: jweObject()))

        #expect(
            RadarVerifiedLocationToken.instancesRespond(
                to: NSSelectorFromString("format")
            )
        )
        #expect(
            (token.value(forKey: "format") as? NSNumber)?.intValue
                == RadarResponseFormat.jwe.rawValue
        )
    }
}
