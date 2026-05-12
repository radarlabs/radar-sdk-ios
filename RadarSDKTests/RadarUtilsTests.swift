//
//  RadarUtilsTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 5/12/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Testing
import Foundation

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

    @Test func dictionaryToJsonReturnsEmptyForNestedNonStringKey() {
        let inner: NSDictionary = [1: "value"]
        let dict: [String: Any] = ["nested": inner]
        #expect(RadarUtils.dictionaryToJson(dict) == "{}")
    }
}
