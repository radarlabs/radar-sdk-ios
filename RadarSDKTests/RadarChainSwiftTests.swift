//
//  RadarChainSwiftTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

/// Covers `RadarChainSwift`, the Swift value type that replaces the ObjC `RadarChain`'s
/// `initWithObject:` / `dictionaryValue` JSON handling. The legacy `RadarChain.m` is still on
/// disk and still parses `/places` responses, so several tests assert *parity* against it —
/// the two must agree on what a payload means before any caller can be moved over.
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

    @Test("Rejects a payload missing slug, matching the ObjC parser")
    func rejectsMissingSlug() {
        let json = #"{"name": "Starbucks"}"#

        #expect(throws: DecodingError.self) { try Self.decode(json) }
        #expect(RadarChain(object: ["name": "Starbucks"]) == nil)
    }

    @Test("Rejects a payload missing name, matching the ObjC parser")
    func rejectsMissingName() {
        let json = #"{"slug": "starbucks"}"#

        #expect(throws: DecodingError.self) { try Self.decode(json) }
        #expect(RadarChain(object: ["slug": "starbucks"]) == nil)
    }

    @Test("Rejects a non-string slug, matching the ObjC parser")
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

    @Test("Omits nil fields when encoding, matching dictionaryValue")
    func encodeOmitsNilFields() throws {
        let dict = try Self.encodeToDictionary(RadarChainSwift(slug: "starbucks", name: "Starbucks"))

        #expect(dict.keys.sorted() == ["name", "slug"])

        // `dictionaryValue` uses `setValue:forKey:`, which drops nil values the same way.
        let objcChain = try #require(RadarChain(object: ["slug": "starbucks", "name": "Starbucks"]))
        #expect(objcChain.dictionaryValue().keys.compactMap { $0 as? String }.sorted() == ["name", "slug"])
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

    @Test("Agrees with the ObjC parser on a real /places chain payload")
    func matchesObjCParserOnPlacesPayload() throws {
        let payload: [String: Any] = [
            "slug": "starbucks",
            "name": "Starbucks",
            "externalId": "123",
            "metadata": ["customFlag": true],
        ]

        let swiftChain = try JSONDecoder().decode(
            RadarChainSwift.self, from: JSONSerialization.data(withJSONObject: payload))
        let objcChain = try #require(RadarChain(object: payload))

        #expect(swiftChain.slug == objcChain.slug)
        #expect(swiftChain.name == objcChain.name)
        #expect(swiftChain.externalId == objcChain.externalId)
        #expect(
            swiftChain.metadata?["customFlag"]?.anyValue as? Bool
                == objcChain.metadata?["customFlag"] as? Bool
        )
    }

    @Test("Ignores unrecognized keys the ObjC parser also drops")
    func ignoresUnknownKeys() throws {
        let chain = try Self.decode(
            #"{"slug": "starbucks", "name": "Starbucks", "unexpected": "value"}"#)

        #expect(chain.slug == "starbucks")
        #expect(try Self.encodeToDictionary(chain).keys.sorted() == ["name", "slug"])
    }
}
