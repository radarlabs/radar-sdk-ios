//
//  RadarSegmentTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarSegmentTests")
struct RadarSegmentTests {

    private func decode(_ json: String) throws -> RadarSegmentSwift {
        try JSONDecoder().decode(RadarSegmentSwift.self, from: Data(json.utf8))
    }

    private func encodeToDictionary(_ segment: RadarSegmentSwift) throws -> [String: String] {
        let data = try JSONEncoder().encode(segment)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: String])
    }

    // MARK: - Decoding

    @Test("decodes description and externalId")
    func decodesBothFields() throws {
        let segment = try decode(#"{"description": "Starbucks Visitors", "externalId": "starbucks-visitors"}"#)

        #expect(segment.description == "Starbucks Visitors")
        #expect(segment.externalId == "starbucks-visitors")
    }

    @Test("ignores unknown keys")
    func ignoresUnknownKeys() throws {
        let segment = try decode(#"{"description": "d", "externalId": "e", "unexpected": 1}"#)

        #expect(segment == RadarSegmentSwift(description: "d", externalId: "e"))
    }

    @Test("missing description fails to decode")
    func missingDescriptionThrows() {
        #expect(throws: (any Error).self) {
            try decode(#"{"externalId": "e"}"#)
        }
    }

    @Test("missing externalId fails to decode")
    func missingExternalIdThrows() {
        #expect(throws: (any Error).self) {
            try decode(#"{"description": "d"}"#)
        }
    }

    @Test("non-string values fail to decode")
    func wrongTypeThrows() {
        #expect(throws: (any Error).self) {
            try decode(#"{"description": 1, "externalId": "e"}"#)
        }
    }

    // MARK: - Encoding

    @Test("encodes both fields under the wire keys")
    func encodesBothFields() throws {
        let dict = try encodeToDictionary(RadarSegmentSwift(description: "d", externalId: "e"))

        #expect(dict == ["description": "d", "externalId": "e"])
    }

    @Test("round-trips through JSON")
    func roundTrips() throws {
        let original = RadarSegmentSwift(description: "Starbucks Visitors", externalId: "starbucks-visitors")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RadarSegmentSwift.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Parity with the legacy ObjC RadarSegment

    @Test("matches ObjC parsing of a valid payload")
    func parityOnValidPayload() throws {
        let dict: [String: Any] = ["description": "Starbucks Visitors", "externalId": "starbucks-visitors"]
        let objc = try #require(RadarSegment(object: dict))
        let swift = try decode(#"{"description": "Starbucks Visitors", "externalId": "starbucks-visitors"}"#)

        #expect(objc.__description == swift.description)
        #expect(objc.externalId == swift.externalId)
    }

    @Test("matches ObjC serialization of a valid payload")
    func parityOnSerialization() throws {
        let swift = RadarSegmentSwift(description: "d", externalId: "e")
        let objc = try #require(RadarSegment(object: ["description": "d", "externalId": "e"]))

        let objcDict = try #require(objc.dictionaryValue() as? [String: String])

        #expect(try encodeToDictionary(swift) == objcDict)
    }

    @Test(
        "rejects the same payloads ObjC rejects",
        arguments: [
            #"{"externalId": "e"}"#,
            #"{"description": "d"}"#,
            #"{"description": 1, "externalId": "e"}"#,
            "{}",
        ]
    )
    func parityOnRejectedPayloads(json: String) throws {
        let dict = try #require(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])

        #expect(RadarSegment(object: dict) == nil)
        #expect(throws: (any Error).self) {
            try decode(json)
        }
    }
}
