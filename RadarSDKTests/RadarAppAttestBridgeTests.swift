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

    @Test("Asserting adds a fresh App Attest assertion over each sealed attempt")
    func assertRequestAddsAssertionHeaders() async throws {
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
            let sealed = try prepared.prepareRequest(request)
            let sent = await prepared.assertRequest(sealed)
            let payload = try #require(sealed.httpBody.flatMap { String(bytes: $0, encoding: .utf8) })
            let assertOptions = try #require(instance.capturedAssertOptions.last)
            #expect(assertOptions["payload"] as? String == payload)
            #expect(assertOptions["method"] as? String == "POST")
            #expect(assertOptions["canonicalRoute"] as? String == "/v1/track")
            #expect(sent.httpBody == sealed.httpBody)
            #expect(sent.value(forHTTPHeaderField: "X-Radar-App-Attest-Key-Id") == "test-key-id")
            #expect(sent.value(forHTTPHeaderField: "X-Radar-App-Attest-Assertion") == "assertion-\(payload)")
            assertions.append(try #require(sent.value(forHTTPHeaderField: "X-Radar-App-Attest-Assertion")))
        }
        #expect(Set(assertions).count == 2)
        #expect(request.value(forHTTPHeaderField: "X-Radar-App-Attest-Assertion") == nil)
    }

    @Test(
        "Asserting returns the sealed request unchanged when the fraud SDK has no assertion",
        arguments: [
            [:],
            ["appAttestError": "Assertion failed"],
            ["appAttestKeyId": "test-key-id"],
            ["appAttestAssertion": "test-assertion"],
        ] as [[String: String]]
    )
    func assertRequestOmitsIncompleteAssertion(assertion: [String: String]) async throws {
        let instance = MockPreparedFraudPayloadInstance(
            result: ["payload": MockFraudEnvelope.payload],
            assertionForOptions: { _ in assertion }
        )
        let prepared = try #require(RadarPreparedFraudPayload(instance: instance))
        let sealed = try prepared.prepareRequest(try Self.assertionRequest())

        let sent = await prepared.assertRequest(sealed)

        #expect(sent == sealed)
        #expect(instance.capturedAssertOptions.count == 1)
    }

    @Test("Asserting returns the sealed request unchanged when the fraud SDK cannot assert")
    func assertRequestWithoutAssertionSupport() async throws {
        let instance = MockPreparedFraudPayloadInstance(result: ["payload": MockFraudEnvelope.payload])
        #expect(!instance.responds(to: NSSelectorFromString("assertWithOptions:completionHandler:")))
        let prepared = try #require(RadarPreparedFraudPayload(instance: instance))
        let sealed = try prepared.prepareRequest(try Self.assertionRequest())

        let sent = await prepared.assertRequest(sealed)

        #expect(sent == sealed)
        #expect(instance.capturedAssertOptions.isEmpty)
    }
}
