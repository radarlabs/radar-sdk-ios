//
//  RadarVerifiedLocationTokenPayloadTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("Verified location token Swift payload")
struct RadarVerifiedLocationTokenPayloadTests {
    @Test(arguments: [true, false])
    func jwsPreservesItsFields(passed: Bool) throws {
        let result = RadarVerificationManagerSwiftTestHelpers.makeToken(
            passed: passed
        )
        let payload = try #require(result.payload)

        guard case let .jws(user, events, token, verdict, reasons, expiration) = payload else {
            Issue.record("Expected a JWS payload")
            return
        }

        #expect(user === result.user)
        #expect(events.isEmpty)
        #expect(token == result.token)
        #expect(verdict == passed)
        #expect(reasons == result.failureReasons)
        #expect(expiration == result.expiresAt)
    }

    @Test(arguments: [true, false])
    func jweExposesItsOpaqueToken(passed: Bool) throws {
        let result = try #require(
            RadarVerifiedLocationToken(object: [
                "format": "jwe",
                "_id": "evaluation-id",
                "token": "opaque-token",
                "expiresAt": "2030-01-01T00:00:00.000Z",
                "expiresIn": 90,
                "passed": passed,
            ]))
        let payload = try #require(result.payload)

        guard case let .jwe(token, expiration) = payload else {
            Issue.record("Expected a JWE payload")
            return
        }

        #expect(token == "opaque-token")
        #expect(expiration == result.expiresAt)
        #expect(result.passed == passed)
        #expect(result.expiresIn == 90)
    }

    @Test
    func idExposesTheEvaluationID() throws {
        let result = try #require(
            RadarVerifiedLocationToken(object: [
                "format": "id",
                "_id": "lookup-id",
            ]))
        let payload = try #require(result.payload)

        guard case let .id(id) = payload else {
            Issue.record("Expected an ID payload")
            return
        }

        #expect(id == "lookup-id")
    }

    @Test
    func emptyModelHasNoPayload() {
        #expect(RadarVerifiedLocationToken().payload == nil)
    }

    @Test
    func payloadIsNotExposedToObjectiveC() {
        #expect(
            !RadarVerifiedLocationToken.instancesRespond(
                to: NSSelectorFromString("payload")
            )
        )
    }
}
