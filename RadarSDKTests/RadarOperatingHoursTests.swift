//
//  RadarOperatingHoursTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarOperatingHoursTests")
struct RadarOperatingHoursTests {

    private func decode(_ json: String) throws -> RadarOperatingHoursSwift {
        try JSONDecoder().decode(RadarOperatingHoursSwift.self, from: Data(json.utf8))
    }

    private func encodeToDictionary(_ operatingHours: RadarOperatingHoursSwift) throws -> [String: [[String]]] {
        let data = try JSONEncoder().encode(operatingHours)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: [[String]]])
    }

    private func objcHours(_ dictionary: [String: Any]) throws -> [String: [[String]]] {
        let parsed = try #require(RadarOperatingHours(dictionary: dictionary))
        return try #require(parsed.hours as? [String: [[String]]])
    }

    // MARK: - Decoding

    @Test("decodes each day's ranges")
    func decodesRanges() throws {
        let operatingHours = try decode(#"{"mon": [["09:00", "17:00"]], "tue": [["08:00", "12:00"], ["13:00", "20:00"]]}"#)

        #expect(
            operatingHours
                == RadarOperatingHoursSwift(hours: [
                    "mon": [["09:00", "17:00"]],
                    "tue": [["08:00", "12:00"], ["13:00", "20:00"]],
                ]))
    }

    @Test("decodes an empty payload to no days")
    func decodesEmptyPayload() throws {
        #expect(try decode("{}").hours.isEmpty)
    }

    @Test("drops a day whose value is not an array")
    func dropsNonArrayDay() throws {
        let operatingHours = try decode(#"{"mon": [["09:00", "17:00"]], "tue": "closed", "wed": null, "thu": {"open": true}}"#)

        #expect(operatingHours.hours == ["mon": [["09:00", "17:00"]]])
    }

    @Test(
        "drops a malformed range but keeps the rest of its day",
        arguments: [
            #"["09:00"]"#,  // too few elements
            #"["09:00", "17:00", "21:00"]"#,  // too many elements
            #"["09:00", 17]"#,  // non-string element
            #""09:00-17:00""#,  // not an array
            "null",
        ]
    )
    func dropsMalformedRange(malformed: String) throws {
        let operatingHours = try decode(#"{"mon": [\#(malformed), ["09:00", "17:00"]]}"#)

        #expect(operatingHours.hours == ["mon": [["09:00", "17:00"]]])
    }

    @Test("keeps a day whose ranges were all dropped as an empty day")
    func keepsEmptiedDay() throws {
        let operatingHours = try decode(#"{"mon": [["09:00"]], "tue": []}"#)

        #expect(operatingHours.hours == ["mon": [], "tue": []])
    }

    @Test("a non-object payload fails to decode")
    func nonObjectThrows() {
        #expect(throws: (any Error).self) {
            try decode("[]")
        }
    }

    // MARK: - Encoding

    @Test("encodes days and ranges under the wire keys")
    func encodesRanges() throws {
        let dictionary = try encodeToDictionary(RadarOperatingHoursSwift(hours: ["mon": [["09:00", "17:00"]]]))

        #expect(dictionary == ["mon": [["09:00", "17:00"]]])
    }

    @Test("round-trips through JSON")
    func roundTrips() throws {
        let original = RadarOperatingHoursSwift(hours: [
            "mon": [["09:00", "17:00"]],
            "sat": [],
        ])
        let data = try JSONEncoder().encode(original)

        #expect(try JSONDecoder().decode(RadarOperatingHoursSwift.self, from: data) == original)
    }

    // MARK: - Parity with the legacy ObjC RadarOperatingHours

    @Test("matches ObjC parsing of a valid payload")
    func parityOnValidPayload() throws {
        let dictionary: [String: Any] = [
            "mon": [["09:00", "17:00"]],
            "tue": [["08:00", "12:00"], ["13:00", "20:00"]],
        ]
        let swift = try decode(#"{"mon": [["09:00", "17:00"]], "tue": [["08:00", "12:00"], ["13:00", "20:00"]]}"#)

        #expect(try objcHours(dictionary) == swift.hours)
    }

    @Test("matches ObjC on a payload with malformed days and ranges")
    func parityOnMalformedPayload() throws {
        let dictionary: [String: Any] = [
            "mon": [["09:00", "17:00"], ["18:00"], ["19:00", 20]],
            "tue": "closed",
            "wed": [],
        ]
        let swift = try decode(#"{"mon": [["09:00", "17:00"], ["18:00"], ["19:00", 20]], "tue": "closed", "wed": []}"#)

        #expect(try objcHours(dictionary) == ["mon": [["09:00", "17:00"]], "wed": []])
        #expect(try objcHours(dictionary) == swift.hours)
    }

    @Test("matches ObjC on an empty payload")
    func parityOnEmptyPayload() throws {
        #expect(try objcHours([:]) == (try decode("{}")).hours)
    }
}
