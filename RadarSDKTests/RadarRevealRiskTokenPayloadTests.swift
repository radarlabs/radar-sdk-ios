//
//  RadarRevealRiskTokenPayloadTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("Reveal Risk token Swift payload")
struct RadarRevealRiskTokenPayloadTests {
    private func parse(_ object: [String: Any]) throws -> RadarRevealRiskToken {
        let data = try JSONSerialization.data(withJSONObject: object)
        return try #require(RadarRevealRiskToken.fromData(data))
    }

    @Test(arguments: [false, true])
    func jwsPreservesItsFields(explicitFormat: Bool) throws {
        var object = RadarSerializedTests.RadarRevealRiskTests.revealRiskResponse
        if explicitFormat {
            object["format"] = "jws"
        }

        let result = try parse(object)
        let payload = try #require(result.payload)

        guard case let .jws(risk, network, device, token, expiration) = payload else {
            Issue.record("Expected a JWS payload")
            return
        }

        #expect(risk === result.risk)
        #expect(network === result.network)
        #expect(device === result.device)
        #expect(risk.level == .medium)
        #expect(token == "signed-jwt-token")
        #expect(expiration == result.expiresAt)
    }

    @Test(arguments: [false, true])
    func jwsAllowsMissingSigningMetadata(explicitNull: Bool) throws {
        var object = RadarSerializedTests.RadarRevealRiskTests.revealRiskResponse
        for key in ["token", "expiresAt", "expiresIn"] {
            if explicitNull {
                object[key] = NSNull()
            } else {
                object.removeValue(forKey: key)
            }
        }

        let result = try parse(object)
        let payload = try #require(result.payload)

        guard case let .jws(risk, network, device, token, expiration) = payload else {
            Issue.record("Expected a JWS payload")
            return
        }

        #expect(risk === result.risk)
        #expect(network === result.network)
        #expect(device === result.device)
        #expect(token == nil)
        #expect(expiration == nil)
    }

    @Test
    func jweExposesItsOpaqueToken() throws {
        let result = try parse([
            "format": "jwe",
            "_id": "risk-id",
            "token": "opaque-token",
            "expiresAt": "2030-01-01T00:00:00.000Z",
            "expiresIn": 90,
        ])
        let payload = try #require(result.payload)

        guard case let .jwe(token, expiration) = payload else {
            Issue.record("Expected a JWE payload")
            return
        }

        #expect(token == "opaque-token")
        #expect(expiration == result.expiresAt)
        #expect(result._id == "risk-id")
        #expect(result.expiresIn == 90)
        #expect(result.risk == nil)
        #expect(result.network == nil)
        #expect(result.device == nil)
    }

    @Test
    func idExposesTheEvaluationID() throws {
        let result = try parse([
            "format": "id",
            "_id": "lookup-id",
        ])
        let payload = try #require(result.payload)

        guard case let .id(id) = payload else {
            Issue.record("Expected an ID payload")
            return
        }

        #expect(id == "lookup-id")
        #expect(result.token == nil)
        #expect(result.expiresAt == nil)
    }

    @Test
    func payloadIsNotExposedToObjectiveC() {
        #expect(
            !RadarRevealRiskToken.instancesRespond(
                to: NSSelectorFromString("payload")
            )
        )
    }
}
