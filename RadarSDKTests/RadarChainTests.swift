//
//  RadarChainTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarChainTests")
struct RadarChainTests {

    private static func decode(_ json: String) throws -> RadarChain {
        let object = try JSONSerialization.jsonObject(with: Data(json.utf8))
        return try #require(RadarChain(object: object))
    }

    private static func dictionary(_ chain: RadarChain) throws -> [String: Any] {
        try #require(chain.dictionaryValue() as? [String: Any])
    }

    @Test("Decodes a fully populated chain")
    func decodesFullChain() throws {
        let chain = try Self.decode(
            """
            {
                "slug": "starbucks",
                "name": "Starbucks",
                "externalId": "123",
                "metadata": {"customFlag": true}
            }
            """)

        #expect(chain.slug == "starbucks")
        #expect(chain.name == "Starbucks")
        #expect(chain.externalId == "123")
        #expect(chain.metadata?["customFlag"] as? Bool == true)
    }

    @Test("Decodes a chain with only the required fields")
    func decodesMinimalChain() throws {
        let chain = try Self.decode(#"{"slug": "starbucks", "name": "Starbucks"}"#)

        #expect(chain.slug == "starbucks")
        #expect(chain.name == "Starbucks")
        #expect(chain.externalId == nil)
        #expect(chain.metadata == nil)
    }

    @Test("Preserves each metadata value type")
    func decodesMixedMetadataValueTypes() throws {
        let chain = try Self.decode(
            """
            {
                "slug": "starbucks",
                "name": "Starbucks",
                "metadata": {"aString": "x", "anInt": 7, "aDouble": 1.5, "aBool": false}
            }
            """)

        let metadata = try #require(chain.metadata)
        #expect(metadata["aString"] as? String == "x")
        #expect((metadata["anInt"] as? NSNumber)?.intValue == 7)
        #expect((metadata["aDouble"] as? NSNumber)?.doubleValue == 1.5)
        #expect((metadata["aBool"] as? NSNumber)?.boolValue == false)
    }

    @Test("Rejects a payload missing a required field")
    func rejectsMissingRequiredField() {
        #expect(RadarChain(object: ["name": "Starbucks"]) == nil)
        #expect(RadarChain(object: ["slug": "starbucks"]) == nil)
    }

    @Test("Rejects a non-string required field")
    func rejectsNonStringRequiredField() {
        #expect(RadarChain(object: ["slug": 1, "name": "Starbucks"]) == nil)
    }

    @Test("Serializes every populated field")
    func serializesFullChain() throws {
        let metadata: NSDictionary = ["customFlag": true]
        let dict = try Self.dictionary(
            RadarChain(
                slug: "starbucks",
                name: "Starbucks",
                externalId: "123",
                metadata: metadata
            ))

        #expect(dict["slug"] as? String == "starbucks")
        #expect(dict["name"] as? String == "Starbucks")
        #expect(dict["externalId"] as? String == "123")
        #expect((dict["metadata"] as? [String: Any])?["customFlag"] as? Bool == true)
    }

    @Test("Omits nil fields when serializing")
    func serializeOmitsNilFields() throws {
        let dict = try Self.dictionary(
            RadarChain(slug: "starbucks", name: "Starbucks", externalId: nil, metadata: nil))

        #expect(dict.keys.sorted() == ["name", "slug"])
    }

    @Test("Round-trips through dictionaryValue without losing fields")
    func roundTripsThroughDictionaryValue() throws {
        let originalMetadata: NSDictionary = ["aString": "x", "anInt": 7]
        let original = RadarChain(
            slug: "starbucks",
            name: "Starbucks",
            externalId: "123",
            metadata: originalMetadata
        )

        let decoded = try #require(RadarChain(object: original.dictionaryValue()))

        #expect(decoded.slug == original.slug)
        #expect(decoded.name == original.name)
        #expect(decoded.externalId == original.externalId)
        #expect(decoded.metadata?["aString"] as? String == "x")
        #expect((decoded.metadata?["anInt"] as? NSNumber)?.intValue == 7)
    }

    @Test("Ignores unrecognized keys")
    func ignoresUnknownKeys() throws {
        let chain = try Self.decode(
            #"{"slug": "starbucks", "name": "Starbucks", "unexpected": "value"}"#)

        #expect(chain.slug == "starbucks")
        #expect(try Self.dictionary(chain).keys.sorted() == ["name", "slug"])
    }

    @Test("Serializes chain arrays")
    func serializesArrays() throws {
        let chain = RadarChain(slug: "starbucks", name: "Starbucks", externalId: nil, metadata: nil)
        let dictionaries = try #require(RadarChain.array(for: [chain]))

        #expect(dictionaries.count == 1)
        #expect(dictionaries[0]["slug"] as? String == "starbucks")
        #expect(dictionaries[0]["name"] as? String == "Starbucks")
        #expect(RadarChain.array(for: nil) == nil)
    }

    @Test("Rejects non-dictionary payloads")
    func rejectsNonDictionaryPayloads() {
        #expect(RadarChain(object: []) == nil)
        #expect(RadarChain(object: "not a dictionary") == nil)
    }
}
