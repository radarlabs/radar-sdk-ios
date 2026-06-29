//
//  RadarUtilsTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 5/12/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite
struct RadarUtilsTests {

    @Test func dictionaryToJsonReturnsEmptyForNil() {
        #expect(RadarUtils.dictionaryToJson(nil) == "{}")
    }

    @Test func dictionaryToJsonReturnsEmptyForEmptyDict() {
        #expect(RadarUtils.dictionaryToJson([:]) == "{}")
    }

    @Test func dictionaryToJsonEncodesValidDict() {
        let json = RadarUtils.dictionaryToJson(["foo": "bar", "count": 42])
        #expect(json != "{}")
        #expect(json.hasPrefix("{") && json.hasSuffix("}"))
        #expect(json.contains("\"foo\":\"bar\""))
        #expect(json.contains("\"count\":42"))
    }

    @Test func dictionaryToJsonReturnsEmptyforNaNValue() {
        let dict: [String: Any] = ["bad": Double.nan]
        #expect(RadarUtils.dictionaryToJson(dict) == "{}")
    }

    @Test func dictionaryToJsonReturnsEmptyForInfinityValue() {
        let dict: [String: Any] = ["bad": Double.infinity]
        #expect(RadarUtils.dictionaryToJson(dict) == "{}")
    }

    @Test func dictionaryToJsonReturnsEmptyForUnsupportedValueType() {
        let dict: [String: Any] = ["d": NSDate()]
        #expect(RadarUtils.dictionaryToJson(dict) == "{}")
    }

    @Test func dictionaryToJsonDropsNestedNonStringKeysKeepingContainer() throws {
        let inner: NSDictionary = [1: "value"]
        let dict: [String: Any] = ["nested": inner]
        let json = RadarUtils.dictionaryToJson(dict)
        let decoded = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        #expect(decoded?.keys.contains("nested") == true)
        #expect((decoded?["nested"] as? [String: Any])?.isEmpty == true)
    }

    @Test func dictionaryToJsonDropsDataButKeepsSiblings() {
        let dict: [String: Any] = ["foo": "bar", "blob": Data("x".utf8)]
        let json = RadarUtils.dictionaryToJson(dict)
        #expect(json.contains("\"foo\":\"bar\""))
        #expect(!json.contains("blob"))
    }

    @Test func dictionarytoJsonSanitizedNotificationDiffWithData() {
        let params: [String: Any] = [
            "latitude": 1.0,
            "notificationDiff": [["identifier": "radar_x", "registeredAt": 123, "info": Data("y".utf8)]],
        ]
        let json = RadarUtils.dictionaryToJson(params)
        #expect(json.contains("\"identifier\":\"radar_x\""))
        #expect(json.contains("\"latitude\":1"))
        #expect(!json.contains("info"))  // the only thing dropped
    }

    @Test func escapeNonAsciiLeavesAsciiUntouched() {
        #expect(RadarUtils.escapeNonAsciiCharacters("{\"name\":\"Cafe\"}") == "{\"name\":\"Cafe\"}")
    }

    @Test func escapeNonAsciiEscapesAccentedCharacters() {
        #expect(RadarUtils.escapeNonAsciiCharacters("Café") == "Caf\\u00e9")
        #expect(RadarUtils.escapeNonAsciiCharacters("Niño") == "Ni\\u00f1o")
    }

    @Test func escapeNonAsciiResultIsValidJson() throws {
        let json = RadarUtils.escapeNonAsciiCharacters(RadarUtils.dictionaryToJson(["name": "Café"]))
        // Every character is now ASCII.
        #expect(json.allSatisfy { $0.isASCII })
        let decoded = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: String]
        #expect(decoded?["name"] == "Café")
    }

    @Test func escapeNonAsciiHandlesEmojiSurrogatePairs() throws {
        // U+1F600 -> surrogate pair \ud83d\ude00, both valid JSON.
        let escaped = RadarUtils.escapeNonAsciiCharacters("😀")
        #expect(escaped == "\\ud83d\\ude00")
        let decoded = try JSONSerialization.jsonObject(with: Data("\"\(escaped)\"".utf8), options: [.allowFragments]) as? String
        #expect(decoded == "😀")
    }
}
