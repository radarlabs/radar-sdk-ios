//
//  RadarFraudPayloadPreparerTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 9/15/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarFraudPayloadPreparerTests {
        @Test(
            "Encrypted payload collection rejects unsuccessful or unusable payloads",
            arguments: [
                "nil-result",
                "missing-payload",
                "empty-payload",
                "wrong-payload-type",
                "error-with-payload",
            ],
            ["/v1/track", "/v1/reveal/risk"]
        )
        func rejectsInvalidPayloads(
            scenario: String,
            route: String
        ) async throws {
            let result: [String: Any]?
            switch scenario {
            case "nil-result":
                result = nil
            case "missing-payload":
                result = [:]
            case "empty-payload":
                result = ["payload": ""]
            case "wrong-payload-type":
                result = ["payload": 123]
            default:
                result = [
                    "error": "Encryption failed",
                    "payload": "must-not-be-sent",
                ]
            }

            let instance = MockEncryptedFraudInstance(result: result)
            let fraudSDK = try #require(RadarSDKFraud(instance: instance))
            let preparer = RadarFraudPayloadPreparer(
                fraudSDK: fraudSDK,
                options: [:]
            )

            do {
                _ = try await preparer.getEncryptedPayload(
                    installId: "test-install",
                    canonicalRoute: route,
                    sdkVersion: "test-version",
                    authorization: "test-key"
                )
                Issue.record("Expected preparation to reject \(scenario)")
            } catch let error as RadarError {
                #expect(error.status == .errorUnknown)
            }

            #expect(instance.recordedOptions().count == 1)
        }
    }
}
