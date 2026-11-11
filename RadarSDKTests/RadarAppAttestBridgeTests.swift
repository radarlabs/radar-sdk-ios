//
//  RadarAppAttestBridgeTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests.RadarFraudBridgeTests {
    private static func assertionRequest() throws -> URLRequest {
        var request = URLRequest(url: try #require(URL(string: "https://example.test/v1/track")))
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"installId":"test-install"}"#.utf8)
        return request
    }

    @Test("Request preparation adds a fresh App Attest assertion on every attempt")
    func requestPreparationAddsAssertionHeaders() async throws {
        let instance = MockPreparedFraudPayloadInstance(
            result: nil,
            resultForOptions: { MockFraudEnvelope.result(for: $0) },
            assertionForOptions: { options in
                [
                    "appAttestKeyId": "test-key-id",
                    "appAttestAssertion": "assertion-\(options["payload"] as? String ?? "")",
                ]
            }
        )
        let prepared = try #require(RadarPreparedFraudPayload(instance: instance))
        let request = try Self.assertionRequest()

        var assertions: [String] = []
        for _ in 0..<2 {
            let sent = try await prepared.prepareRequest(request)
            let options = try #require(instance.capturedOptions.last)
            let payload = try #require(MockFraudEnvelope.result(for: options)["payload"] as? String)
            let assertOptions = try #require(instance.capturedAssertOptions.last)
            #expect(assertOptions["payload"] as? String == payload)
            #expect(assertOptions["method"] as? String == "POST")
            #expect(assertOptions["canonicalRoute"] as? String == "/v1/track")
            #expect(sent.httpBody == Data(payload.utf8))
            #expect(sent.value(forHTTPHeaderField: "X-Radar-App-Attest-Key-Id") == "test-key-id")
            #expect(sent.value(forHTTPHeaderField: "X-Radar-App-Attest-Assertion") == "assertion-\(payload)")
            assertions.append(try #require(sent.value(forHTTPHeaderField: "X-Radar-App-Attest-Assertion")))
        }
        #expect(Set(assertions).count == 2)
        #expect(instance.capturedOptions.count == 2)
        #expect(request.value(forHTTPHeaderField: "X-Radar-App-Attest-Assertion") == nil)
    }

    @Test(
        "Request preparation sends no App Attest headers when the fraud SDK cannot assert",
        arguments: [
            [:],
            ["appAttestError": "Assertion failed"],
            ["appAttestKeyId": "test-key-id"],
            ["appAttestAssertion": "test-assertion"],
        ] as [[String: String]]
    )
    func requestPreparationOmitsIncompleteAssertion(assertion: [String: String]) async throws {
        let instance = MockPreparedFraudPayloadInstance(
            result: ["payload": MockFraudEnvelope.payload],
            assertionForOptions: { _ in assertion }
        )
        let prepared = try #require(RadarPreparedFraudPayload(instance: instance))

        let sent = try await prepared.prepareRequest(try Self.assertionRequest())

        #expect(sent.httpBody == Data(MockFraudEnvelope.payload.utf8))
        #expect(sent.value(forHTTPHeaderField: "X-Radar-App-Attest-Key-Id") == nil)
        #expect(sent.value(forHTTPHeaderField: "X-Radar-App-Attest-Assertion") == nil)
        #expect(instance.capturedOptions.count == 1)
        #expect(instance.capturedAssertOptions.count == 1)
    }

    @Test("Request preparation only seals when the fraud SDK cannot assert")
    func requestPreparationSealsWithoutAssertionSupport() async throws {
        let instance = MockPreparedFraudPayloadInstance(result: ["payload": MockFraudEnvelope.payload])
        #expect(!instance.responds(to: NSSelectorFromString("assertWithOptions:completionHandler:")))
        let prepared = try #require(RadarPreparedFraudPayload(instance: instance))

        let sent = try await prepared.prepareRequest(try Self.assertionRequest())

        #expect(sent.httpBody == Data(MockFraudEnvelope.payload.utf8))
        #expect(sent.value(forHTTPHeaderField: "X-Radar-App-Attest-Key-Id") == nil)
        #expect(sent.value(forHTTPHeaderField: "X-Radar-App-Attest-Assertion") == nil)
    }

    @Test("Sealing failures throw without asserting or returning a plaintext request")
    func requestPreparationPropagatesSealFailure() async throws {
        for result in [[:], ["error": "Seal failed"], ["payload": ""]] as [[String: Any]] {
            let instance = MockPreparedFraudPayloadInstance(
                result: result,
                assertionForOptions: { _ in ["appAttestKeyId": "test-key-id", "appAttestAssertion": "test-assertion"] }
            )
            let prepared = try #require(RadarPreparedFraudPayload(instance: instance))
            await #expect {
                try await prepared.prepareRequest(try Self.assertionRequest())
            } throws: { error in
                let radarError = error as? RadarError
                return radarError?.status == .errorBadRequest
                    && radarError?.message == "Failed to encrypt request body"
            }
            #expect(instance.capturedAssertOptions.isEmpty)
        }
    }
}
