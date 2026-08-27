//
//  RadarTimeZoneTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTimeZoneTests")
struct RadarTimeZoneTests {

    private static let fullJSON = """
        {
            "id": "America/New_York",
            "name": "Eastern Standard Time",
            "code": "EST",
            "currentTime": "2024-01-15T09:30:00-05:00",
            "utcOffset": -18000,
            "dstOffset": 0
        }
        """

    /// The instant the fixture's `currentTime` represents: 2024-01-15T14:30:00Z.
    private static let fixtureDate = Date(timeIntervalSince1970: 1_705_329_000)

    private static let empty = RadarTimeZoneSwift(
        id: "", name: "", code: "", currentTime: nil, utcOffset: 0, dstOffset: 0
    )

    private func decode(_ json: String) throws -> RadarTimeZoneSwift {
        try JSONDecoder().decode(RadarTimeZoneSwift.self, from: Data(json.utf8))
    }

    private func encodeToDictionary(_ timeZone: RadarTimeZoneSwift) throws -> [String: Any] {
        let data = try JSONEncoder().encode(timeZone)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    // MARK: - Decoding

    @Test("decodes every field")
    func decodesAllFields() throws {
        let timeZone = try decode(Self.fullJSON)

        #expect(timeZone.id == "America/New_York")
        #expect(timeZone.name == "Eastern Standard Time")
        #expect(timeZone.code == "EST")
        #expect(timeZone.currentTime == Self.fixtureDate)
        #expect(timeZone.utcOffset == -18000)
        #expect(timeZone.dstOffset == 0)
    }

    @Test("reads the id wire key")
    func readsIdKey() throws {
        #expect(try decode(#"{"id": "UTC"}"#).id == "UTC")
    }

    @Test("ignores the _id key other Radar models use")
    func ignoresUnderscoreIdKey() throws {
        #expect(try decode(#"{"_id": "UTC"}"#).id == "")
    }

    @Test("parses currentTime offsets other than the device's")
    func parsesOffsets() throws {
        let timeZone = try decode(#"{"currentTime": "2024-01-15T20:00:00+05:30"}"#)

        #expect(timeZone.currentTime == Self.fixtureDate)
    }

    @Test("ignores unknown keys")
    func ignoresUnknownKeys() throws {
        #expect(try decode(#"{"id": "UTC", "unexpected": 1}"#).id == "UTC")
    }

    @Test("an empty payload decodes to defaults")
    func emptyPayloadDecodes() throws {
        #expect(try decode("{}") == Self.empty)
    }

    @Test(
        "values of the wrong type fall back to defaults",
        arguments: [
            #"{"id": 1, "name": 2, "code": 3, "currentTime": 4, "utcOffset": "x", "dstOffset": "y"}"#,
            #"{"id": null, "name": null, "code": null, "currentTime": null, "utcOffset": null, "dstOffset": null}"#,
            #"{"id": [], "name": {}, "code": true, "currentTime": [], "utcOffset": {}, "dstOffset": []}"#,
        ]
    )
    func wrongTypesFallBack(json: String) throws {
        #expect(try decode(json) == Self.empty)
    }

    @Test("an unparseable currentTime decodes to nil")
    func unparseableDateIsNil() throws {
        #expect(try decode(#"{"currentTime": "not a date"}"#).currentTime == nil)
    }

    @Test("a fractional offset truncates toward zero")
    func fractionalOffsetTruncates() throws {
        let timeZone = try decode(#"{"utcOffset": -18000.75, "dstOffset": 3600.75}"#)

        #expect(timeZone.utcOffset == -18000)
        #expect(timeZone.dstOffset == 3600)
    }

    @Test("a non-object payload fails to decode")
    func nonObjectPayloadThrows() {
        #expect(throws: (any Error).self) {
            try decode("[]")
        }
    }

    // MARK: - Encoding

    @Test("encodes every field under the wire keys")
    func encodesAllFields() throws {
        let dict = try encodeToDictionary(try decode(Self.fullJSON))

        #expect(dict["id"] as? String == "America/New_York")
        #expect(dict["name"] as? String == "Eastern Standard Time")
        #expect(dict["code"] as? String == "EST")
        #expect(dict["utcOffset"] as? Int == -18000)
        #expect(dict["dstOffset"] as? Int == 0)
        #expect(dict["currentTime"] is String)
    }

    @Test("omits currentTime when it is nil")
    func omitsNilCurrentTime() throws {
        let dict = try encodeToDictionary(
            RadarTimeZoneSwift(id: "UTC", name: "n", code: "c", currentTime: nil, utcOffset: 0, dstOffset: 0)
        )

        #expect(dict["currentTime"] == nil)
        #expect(dict["id"] as? String == "UTC")
    }

    @Test("round-trips through JSON")
    func roundTrips() throws {
        let original = try decode(Self.fullJSON)
        let data = try JSONEncoder().encode(original)

        #expect(try JSONDecoder().decode(RadarTimeZoneSwift.self, from: data) == original)
    }

    // MARK: - Parity with the legacy ObjC RadarTimeZone

    /// The Objective-C properties are declared `nonnull` but its parser leaves them unset on
    /// a partial payload, so parity is read through `dictionaryValue` rather than by touching
    /// the properties from Swift.
    private func objcDictionary(_ json: String) throws -> [String: Any] {
        let object = try #require(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let timeZone = try #require(RadarTimeZone(object: object))
        return try #require(timeZone.dictionaryValue() as? [String: Any])
    }

    @Test("matches ObjC parsing of a full payload")
    func parityOnParsing() throws {
        let object = try #require(JSONSerialization.jsonObject(with: Data(Self.fullJSON.utf8)) as? [String: Any])
        let objc = try #require(RadarTimeZone(object: object))
        let swift = try decode(Self.fullJSON)

        #expect(objc._id == swift.id)
        #expect(objc.name == swift.name)
        #expect(objc.code == swift.code)
        #expect(objc.currentTime == swift.currentTime)
        #expect(Int(objc.utcOffset) == swift.utcOffset)
        #expect(Int(objc.dstOffset) == swift.dstOffset)
    }

    @Test("matches ObjC serialization of a full payload")
    func parityOnSerialization() throws {
        let objcDict = try objcDictionary(Self.fullJSON) as NSDictionary
        let swiftDict = try encodeToDictionary(try decode(Self.fullJSON)) as NSDictionary

        #expect(swiftDict == objcDict)
    }

    @Test(
        "accepts the same lenient payloads ObjC accepts",
        arguments: [
            "{}",
            #"{"id": "UTC"}"#,
            #"{"id": 1, "utcOffset": "x"}"#,
            #"{"currentTime": "not a date"}"#,
            #"{"utcOffset": -18000, "dstOffset": 3600}"#,
        ]
    )
    func parityOnLenientPayloads(json: String) throws {
        let objcDict = try objcDictionary(json)
        let swift = try decode(json)

        // Unset strings are absent from the ObjC dictionary where Swift defaults to empty.
        #expect((objcDict["id"] as? String ?? "") == swift.id)
        #expect((objcDict["name"] as? String ?? "") == swift.name)
        #expect((objcDict["code"] as? String ?? "") == swift.code)
        #expect(objcDict["utcOffset"] as? Int == swift.utcOffset)
        #expect(objcDict["dstOffset"] as? Int == swift.dstOffset)

        let objcCurrentTime = objcDict["currentTime"] as? String
        let swiftCurrentTime = try encodeToDictionary(swift)["currentTime"] as? String
        #expect(objcCurrentTime == swiftCurrentTime)
    }

    @Test("rejects non-dictionary payloads like ObjC does")
    func parityOnNonDictionary() {
        #expect(RadarTimeZone(object: "not a dictionary") == nil)
        #expect(throws: (any Error).self) {
            try decode("[]")
        }
    }
}
