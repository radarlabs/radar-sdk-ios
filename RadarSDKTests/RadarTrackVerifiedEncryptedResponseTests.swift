//
//  RadarTrackVerifiedEncryptedResponseTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/11/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTrackVerifiedEncryptedResponse")
struct RadarTrackVerifiedEncryptedResponseTests {
    @Test
    func storesEveryField() {
        let expiration = Date(timeIntervalSince1970: 1_800_000_000)

        let response = RadarTrackVerifiedEncryptedResponse(
            id: "evaluation-id",
            token: "opaque-token",
            expiresAt: expiration,
            expiresIn: 90,
            passed: true,
            distanceToBorder: 2_000
        )

        #expect(response._id == "evaluation-id")
        #expect(response.token == "opaque-token")
        #expect(response.expiresAt == expiration)
        #expect(response.expiresIn == 90)
        #expect(response.passed?.boolValue == true)
        #expect(response.distanceToBorder?.doubleValue == 2_000)
    }

    @Test
    func preservesMissingHints() {
        let response = RadarTrackVerifiedEncryptedResponse(
            id: "evaluation-id",
            token: "opaque-token",
            expiresAt: Date(timeIntervalSince1970: 1_800_000_000),
            expiresIn: 90,
            passed: nil,
            distanceToBorder: nil
        )

        #expect(response.passed == nil)
        #expect(response.distanceToBorder == nil)
    }

    @Test
    func preservesFalseAndZeroHints() {
        let response = RadarTrackVerifiedEncryptedResponse(
            id: "evaluation-id",
            token: "opaque-token",
            expiresAt: Date(timeIntervalSince1970: 1_800_000_000),
            expiresIn: 90,
            passed: false,
            distanceToBorder: 0
        )

        #expect(response.passed?.boolValue == false)
        #expect(response.distanceToBorder?.doubleValue == 0)
    }

    @Test
    func keepsTheObjectiveCRuntimeName() {
        #expect(
            NSClassFromString("RadarTrackVerifiedEncryptedResponse")
                == RadarTrackVerifiedEncryptedResponse.self
        )
    }

    @Test(arguments: [
        "_id",
        "token",
        "expiresAt",
        "expiresIn",
        "passed",
        "distanceToBorder",
    ])
    func exposesObjectiveCGetters(selector: String) {
        #expect(
            RadarTrackVerifiedEncryptedResponse.instancesRespond(
                to: NSSelectorFromString(selector)
            )
        )
    }
}
