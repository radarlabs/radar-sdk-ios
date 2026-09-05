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
        try JSONDecoder().decode(RadarChain.self, from: Data(json.utf8))
    }

    private static func encodeToDictionary(_ chain: RadarChain) throws -> [String: Any] {
        let data = try JSONEncoder().encode(chain)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
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
        #expect(throws: DecodingError.self) {
            try Self.decode(#"{"name": "Starbucks"}"#)
        }
        #expect(RadarChain(object: ["name": "Starbucks"]) == nil)
        #expect(RadarChain(object: ["slug": "starbucks"]) == nil)
    }

    @Test("Rejects a non-string required field")
    func rejectsNonStringRequiredField() {
        #expect(throws: DecodingError.self) {
            try Self.decode(#"{"slug": 1, "name": "Starbucks"}"#)
        }
        #expect(RadarChain(object: ["slug": 1, "name": "Starbucks"]) == nil)
    }

    @Test("Encodes every populated field")
    func encodesFullChain() throws {
        let metadata: NSDictionary = ["customFlag": true]
        let dict = try Self.encodeToDictionary(
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

    @Test("Omits nil fields when encoding")
    func encodeOmitsNilFields() throws {
        let dict = try Self.encodeToDictionary(
            RadarChain(slug: "starbucks", name: "Starbucks", externalId: nil, metadata: nil))

        #expect(dict.keys.sorted() == ["name", "slug"])
    }

    @Test("Round-trips through JSON without losing fields")
    func roundTripsThroughJSON() throws {
        let originalMetadata: NSDictionary = ["aString": "x", "anInt": 7]
        let original = RadarChain(
            slug: "starbucks",
            name: "Starbucks",
            externalId: "123",
            metadata: originalMetadata
        )

        let decoded = try JSONDecoder().decode(
            RadarChain.self, from: JSONEncoder().encode(original))

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
        #expect(try Self.encodeToDictionary(chain).keys.sorted() == ["name", "slug"])
    }

    @Test("Serializes chain arrays")
    func serializesArrays() throws {
        let chain = RadarChain(slug: "starbucks", name: "Starbucks", externalId: nil, metadata: nil)
        let dictionaries = try #require(RadarChain.arrayForChains([chain]))

        #expect(dictionaries.count == 1)
        #expect(dictionaries[0]["slug"] as? String == "starbucks")
        #expect(dictionaries[0]["name"] as? String == "Starbucks")
        #expect(RadarChain.arrayForChains(nil) == nil)
    }

    @Test("Rejects non-dictionary payloads")
    func rejectsNonDictionaryPayloads() {
        #expect(RadarChain(object: []) == nil)
        #expect(RadarChain(object: "not a dictionary") == nil)
    }
}
