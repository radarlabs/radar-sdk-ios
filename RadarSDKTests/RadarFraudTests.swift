//
//  RadarFraudTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarFraudTests")
struct RadarFraudTests {

    /// Every flag set, so a field read from the wrong key shows up as a `false`.
    private static let allTrueJSON = """
        {
            "passed": true,
            "bypassed": true,
            "verified": true,
            "proxy": true,
            "mocked": true,
            "compromised": true,
            "jumped": true,
            "inaccurate": true,
            "sharing": true,
            "blocked": true
        }
        """

    private func fraud(from json: String) throws -> RadarFraud {
        let object = try JSONSerialization.jsonObject(with: Data(json.utf8))
        return try #require(RadarFraud(object: object))
    }

    // MARK: - Decoding

    @Test("decodes every field")
    func decodesAllFields() throws {
        let fraud = try fraud(from: Self.allTrueJSON)

        #expect(fraud.passed)
        #expect(fraud.bypassed)
        #expect(fraud.verified)
        #expect(fraud.proxy)
        #expect(fraud.mocked)
        #expect(fraud.compromised)
        #expect(fraud.jumped)
        #expect(fraud.inaccurate)
        #expect(fraud.sharing)
        #expect(fraud.blocked)
    }

    @Test("decodes each flag independently of the others")
    func decodesFlagsIndependently() throws {
        let fraud = try fraud(from: #"{"passed": true, "blocked": true}"#)

        #expect(fraud.passed)
        #expect(fraud.blocked)
        #expect(!fraud.bypassed)
        #expect(!fraud.verified)
        #expect(!fraud.proxy)
        #expect(!fraud.mocked)
        #expect(!fraud.compromised)
        #expect(!fraud.jumped)
        #expect(!fraud.inaccurate)
        #expect(!fraud.sharing)
    }

    @Test("missing flags default to false")
    func missingFlagsDefaultToFalse() throws {
        let fraud = try fraud(from: "{}")

        #expect(!fraud.passed)
        #expect(!fraud.blocked)
    }

    @Test("non-boolean values read as false")
    func nonBooleanValuesReadAsFalse() throws {
        let fraud = try fraud(from: #"{"passed": "true", "mocked": null, "proxy": {"a": 1}}"#)

        #expect(!fraud.passed)
        #expect(!fraud.mocked)
        #expect(!fraud.proxy)
    }

    @Test("non-zero numbers read as true")
    func nonZeroNumbersReadAsTrue() throws {
        let fraud = try fraud(from: #"{"passed": 1, "mocked": 0}"#)

        #expect(fraud.passed)
        #expect(!fraud.mocked)
    }

    @Test("rejects objects that are not dictionaries")
    func rejectsNonDictionaries() {
        #expect(RadarFraud(object: ["passed", "blocked"]) == nil)
        #expect(RadarFraud(object: "passed") == nil)
        #expect(RadarFraud(object: NSNull()) == nil)
    }

    // MARK: - Encoding

    @Test("dictionaryValue round-trips through initWithObject")
    func dictionaryValueRoundTrips() throws {
        let original = try fraud(from: #"{"passed": true, "jumped": true, "sharing": true}"#)

        let restored = try #require(RadarFraud(object: original.dictionaryValue()))

        #expect(restored.passed)
        #expect(restored.jumped)
        #expect(restored.sharing)
        #expect(!restored.bypassed)
        #expect(!restored.blocked)
    }

    @Test("dictionaryValue emits all ten keys as JSON booleans")
    func dictionaryValueEmitsBooleans() throws {
        let dictionary = try fraud(from: Self.allTrueJSON).dictionaryValue()

        #expect(dictionary.count == 10)

        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let json = try #require(String(bytes: data, encoding: .utf8))

        // NSNumber-wrapped booleans must serialize as `true`, not `1`.
        #expect(json.contains("true"))
        #expect(!json.contains(":1"))
    }

    // MARK: - Memberwise initializer

    @Test("memberwise initializer stores each flag")
    func memberwiseInitializerStoresFlags() {
        let fraud = RadarFraud(
            passed: true,
            bypassed: false,
            verified: true,
            proxy: false,
            mocked: true,
            compromised: false,
            jumped: true,
            inaccurate: false,
            sharing: true,
            blocked: false
        )

        #expect(fraud.passed)
        #expect(!fraud.bypassed)
        #expect(fraud.verified)
        #expect(!fraud.proxy)
        #expect(fraud.mocked)
        #expect(!fraud.compromised)
        #expect(fraud.jumped)
        #expect(!fraud.inaccurate)
        #expect(fraud.sharing)
        #expect(!fraud.blocked)
    }

    @Test("default initializer leaves every flag false")
    func defaultInitializerIsAllFalse() {
        let dictionary = RadarFraud().dictionaryValue()

        for (key, value) in dictionary {
            #expect((value as? NSNumber)?.boolValue == false, "\(key) should default to false")
        }
    }
}
