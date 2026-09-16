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
            "Body preparation rejects unsuccessful or unusable payloads",
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
                _ = try await preparer.prepareBody(
                    ["installId": "test-install"],
                    method: "POST",
                    canonicalRoute: route,
                    headers: [:]
                )
                Issue.record("Expected preparation to reject \(scenario)")
            } catch let error as RadarError {
                #expect(error.status == .errorUnknown)
            }

            #expect(instance.recordedOptions().count == 1)
        }

        @Test(
            "Invalid context is rejected before invoking the fraud library",
            arguments: [
                "wrong-method",
                "missing-install-id",
                "wrong-install-id-type",
            ]
        )
        func rejectsInvalidContext(scenario: String) async throws {
            let instance = MockEncryptedFraudInstance(
                result: ["payload": "must-not-be-used"]
            )
            let fraudSDK = try #require(RadarSDKFraud(instance: instance))
            let preparer = RadarFraudPayloadPreparer(
                fraudSDK: fraudSDK,
                options: [:]
            )

            let method = scenario == "wrong-method" ? "GET" : "POST"
            var body: [String: Any] = ["installId": "test-install"]
            if scenario == "missing-install-id" {
                body.removeValue(forKey: "installId")
            } else if scenario == "wrong-install-id-type" {
                body["installId"] = 123
            }

            do {
                _ = try await preparer.prepareBody(
                    body,
                    method: method,
                    canonicalRoute: "/v1/track",
                    headers: [:]
                )
                Issue.record("Expected preparation to reject \(scenario)")
            } catch let error as RadarError {
                #expect(error.status == .errorUnknown)
                #expect(error.message == "Invalid fraud encryption request")
            }

            #expect(instance.recordedOptions().isEmpty)
        }
    }
}
