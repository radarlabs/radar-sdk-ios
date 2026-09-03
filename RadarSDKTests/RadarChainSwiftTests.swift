//
//  RadarChainSwiftTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

/// Covers the Swift value type and the Objective-C-compatible `RadarChain` facade.
struct RadarChainSwiftTests {

    private static func decode(_ json: String) throws -> RadarChainSwift {
        try JSONDecoder().decode(RadarChainSwift.self, from: Data(json.utf8))
    }

    private static func encodeToDictionary(_ chain: RadarChainSwift) throws -> [String: Any] {
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
        #expect(chain.metadata?["customFlag"] == .bool(true))
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
        #expect(metadata["aString"] == .string("x"))
        #expect(metadata["anInt"] == .int(7))
        #expect(metadata["aDouble"] == .double(1.5))
        #expect(metadata["aBool"] == .bool(false))
    }

    @Test("Rejects a payload missing slug")
    func rejectsMissingSlug() {
        let json = #"{"name": "Starbucks"}"#

        #expect(throws: DecodingError.self) { try Self.decode(json) }
        #expect(RadarChain(object: ["name": "Starbucks"]) == nil)
    }

    @Test("Rejects a payload missing name")
    func rejectsMissingName() {
        let json = #"{"slug": "starbucks"}"#

        #expect(throws: DecodingError.self) { try Self.decode(json) }
        #expect(RadarChain(object: ["slug": "starbucks"]) == nil)
    }

    @Test("Rejects a non-string slug")
    func rejectsNonStringSlug() {
        let json = #"{"slug": 1, "name": "Starbucks"}"#

        #expect(throws: DecodingError.self) { try Self.decode(json) }
        #expect(RadarChain(object: ["slug": 1, "name": "Starbucks"]) == nil)
    }

    @Test("Encodes every populated field")
    func encodesFullChain() throws {
        let dict = try Self.encodeToDictionary(
            RadarChainSwift(
                slug: "starbucks",
                name: "Starbucks",
                externalId: "123",
                metadata: ["customFlag": .bool(true)]
            ))

        #expect(dict["slug"] as? String == "starbucks")
        #expect(dict["name"] as? String == "Starbucks")
        #expect(dict["externalId"] as? String == "123")
        #expect((dict["metadata"] as? [String: Any])?["customFlag"] as? Bool == true)
    }

    @Test("Omits nil fields when encoding")
    func encodeOmitsNilFields() throws {
        let dict = try Self.encodeToDictionary(RadarChainSwift(slug: "starbucks", name: "Starbucks"))

        #expect(dict.keys.sorted() == ["name", "slug"])

        let compatibilityChain = try #require(RadarChain(object: ["slug": "starbucks", "name": "Starbucks"]))
        #expect(compatibilityChain.dictionaryValue().keys.sorted() == ["name", "slug"])
    }

    @Test("Round-trips through encode and decode without losing fields")
    func roundTripsThroughJSON() throws {
        let original = RadarChainSwift(
            slug: "starbucks",
            name: "Starbucks",
            externalId: "123",
            metadata: ["aString": .string("x"), "anInt": .int(7)]
        )

        let decoded = try JSONDecoder().decode(RadarChainSwift.self, from: JSONEncoder().encode(original))

        #expect(decoded.slug == original.slug)
        #expect(decoded.name == original.name)
        #expect(decoded.externalId == original.externalId)
        #expect(decoded.metadata == original.metadata)
    }

    @Test("Parses a real /places chain payload")
    func parsesPlacesPayload() throws {
        let payload: [String: Any] = [
            "slug": "starbucks",
            "name": "Starbucks",
            "externalId": "123",
            "metadata": ["customFlag": true],
        ]

        let swiftChain = try JSONDecoder().decode(
            RadarChainSwift.self, from: JSONSerialization.data(withJSONObject: payload))
        let compatibilityChain = try #require(RadarChain(object: payload))

        #expect(swiftChain.slug == compatibilityChain.slug)
        #expect(swiftChain.name == compatibilityChain.name)
        #expect(swiftChain.externalId == compatibilityChain.externalId)
        #expect(
            swiftChain.metadata?["customFlag"]?.anyValue as? Bool
                == compatibilityChain.metadata?["customFlag"] as? Bool
        )
    }

    @Test("Ignores unrecognized keys")
    func ignoresUnknownKeys() throws {
        let chain = try Self.decode(
            #"{"slug": "starbucks", "name": "Starbucks", "unexpected": "value"}"#)

        #expect(chain.slug == "starbucks")
        #expect(try Self.encodeToDictionary(chain).keys.sorted() == ["name", "slug"])
    }

    // MARK: - Objective-C compatibility

    @Test("The Objective-C facade preserves all fields")
    func compatibilityFacadePreservesFields() throws {
        let metadata: NSDictionary = ["customFlag": true]
        let chain = RadarChain(
            slug: "starbucks",
            name: "Starbucks",
            externalId: "123",
            metadata: metadata
        )

        #expect(chain.slug == "starbucks")
        #expect(chain.name == "Starbucks")
        #expect(chain.externalId == "123")
        #expect(chain.metadata == metadata)
        #expect(
            chain.dictionaryValue() as NSDictionary == [
                "slug": "starbucks",
                "name": "Starbucks",
                "externalId": "123",
                "metadata": metadata,
            ])
    }

    @Test("The Objective-C facade serializes chain arrays")
    func compatibilityFacadeSerializesArrays() throws {
        let chain = RadarChain(slug: "starbucks", name: "Starbucks", externalId: nil, metadata: nil)

        #expect(RadarChain.arrayForChains([chain]) as NSArray? == [["slug": "starbucks", "name": "Starbucks"]])
        #expect(RadarChain.arrayForChains(nil) == nil)
    }

    @Test("The Objective-C facade rejects non-dictionary payloads")
    func compatibilityFacadeRejectsNonDictionaryPayloads() {
        #expect(RadarChain(object: []) == nil)
        #expect(RadarChain(object: "not a dictionary") == nil)
    }
}
