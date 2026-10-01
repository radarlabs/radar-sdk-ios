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

    private func timeZone(from json: String) throws -> RadarTimeZone {
        let object = try JSONSerialization.jsonObject(with: Data(json.utf8))
        return try #require(RadarTimeZone(object: object))
    }

    // MARK: - Decoding

    @Test("decodes every field")
    func decodesAllFields() throws {
        let timeZone = try timeZone(from: Self.fullJSON)

        #expect(timeZone._id == "America/New_York")
        #expect(timeZone.name == "Eastern Standard Time")
        #expect(timeZone.code == "EST")
        #expect(timeZone.currentTime == Self.fixtureDate)
        #expect(timeZone.utcOffset == -18000)
        #expect(timeZone.dstOffset == 0)
    }

    @Test("reads the id wire key")
    func readsIdKey() throws {
        #expect(try timeZone(from: #"{"id": "UTC"}"#)._id == "UTC")
    }

    @Test("parses currentTime offsets other than the device's")
    func parsesOffsets() throws {
        let timeZone = try timeZone(from: #"{"currentTime": "2024-01-15T20:00:00+05:30"}"#)

        #expect(timeZone.currentTime == Self.fixtureDate)
    }

    @Test("ignores unknown keys")
    func ignoresUnknownKeys() throws {
        #expect(try timeZone(from: #"{"id": "UTC", "unexpected": 1}"#)._id == "UTC")
    }

    @Test("an empty payload uses defaults")
    func emptyPayloadUsesDefaults() throws {
        let timeZone = try timeZone(from: "{}")

        #expect(timeZone._id.isEmpty)
        #expect(timeZone.name.isEmpty)
        #expect(timeZone.code.isEmpty)
        #expect(timeZone.currentTime == Date(timeIntervalSince1970: 0))
        #expect(timeZone.utcOffset == 0)
        #expect(timeZone.dstOffset == 0)
    }

    // The public getters fall back to "" and the epoch, but dictionaryValue only serializes what
    // the API sent, so the defaults never leak into the wire format.
    @Test("dictionaryValue omits keys the payload didn't include")
    func dictionaryValueOmitsMissingKeys() throws {
        let dictionary = try timeZone(from: "{}").dictionaryValue()

        #expect(dictionary["id"] == nil)
        #expect(dictionary["name"] == nil)
        #expect(dictionary["code"] == nil)
        #expect(dictionary["currentTime"] == nil)
        #expect(dictionary["utcOffset"] as? Int32 == 0)
        #expect(dictionary["dstOffset"] as? Int32 == 0)
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
        let timeZone = try timeZone(from: json)

        #expect(timeZone._id.isEmpty)
        #expect(timeZone.name.isEmpty)
        #expect(timeZone.code.isEmpty)
        #expect(timeZone.currentTime == Date(timeIntervalSince1970: 0))
        #expect(timeZone.utcOffset == 0)
        #expect(timeZone.dstOffset == 0)
    }

    @Test("an unparseable currentTime uses the public default")
    func unparseableDateUsesDefault() throws {
        #expect(
            try timeZone(from: #"{"currentTime": "not a date"}"#).currentTime
                == Date(timeIntervalSince1970: 0))
    }

    @Test("a fractional offset truncates toward zero")
    func fractionalOffsetTruncates() throws {
        let timeZone = try timeZone(from: #"{"utcOffset": -18000.75, "dstOffset": 3600.75}"#)

        #expect(timeZone.utcOffset == -18000)
        #expect(timeZone.dstOffset == 3600)
    }

    // MARK: - Dictionary representation

    @Test("serializes every field under the wire keys")
    func serializesEveryField() throws {
        let timeZone = try timeZone(from: Self.fullJSON)
        let dictionary = timeZone.dictionaryValue()

        #expect(dictionary["id"] as? String == "America/New_York")
        #expect(dictionary["name"] as? String == "Eastern Standard Time")
        #expect(dictionary["code"] as? String == "EST")
        #expect(dictionary["currentTime"] is String)
        #expect((dictionary["utcOffset"] as? NSNumber)?.int32Value == -18000)
        #expect((dictionary["dstOffset"] as? NSNumber)?.int32Value == 0)

        let roundTrip = try #require(RadarTimeZone(object: dictionary))
        #expect(roundTrip.currentTime == Self.fixtureDate)
    }

    @Test("omits missing optional fields from the dictionary")
    func omitsMissingOptionalFields() throws {
        let dictionary = try timeZone(from: "{}").dictionaryValue()

        #expect(dictionary["id"] == nil)
        #expect(dictionary["name"] == nil)
        #expect(dictionary["code"] == nil)
        #expect(dictionary["currentTime"] == nil)
        #expect((dictionary["utcOffset"] as? NSNumber)?.int32Value == 0)
        #expect((dictionary["dstOffset"] as? NSNumber)?.int32Value == 0)
    }

    @Test("rejects non-dictionary payloads")
    func rejectsNonDictionaryPayloads() throws {
        let object = try JSONSerialization.jsonObject(with: Data("[]".utf8))
        #expect(RadarTimeZone(object: object) == nil)
        #expect(RadarTimeZone(object: "not a dictionary") == nil)
    }
}
