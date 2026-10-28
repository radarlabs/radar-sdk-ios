//
//  RadarRegionTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarRegionTests")
struct RadarRegionTests {

    private static func decode(_ json: String) throws -> RadarRegion {
        let object = try JSONSerialization.jsonObject(with: Data(json.utf8))
        return try #require(RadarRegion(object: object))
    }

    private static func dictionary(_ region: RadarRegion) throws -> [String: Any] {
        try #require(region.dictionaryValue() as? [String: Any])
    }

    @Test("Decodes a fully populated region")
    func decodesFullRegion() throws {
        let region = try Self.decode(
            """
            {
                "_id": "5c0e3e3b1d3b3b0012345678",
                "name": "United States",
                "code": "US",
                "type": "country",
                "flag": "🇺🇸",
                "allowed": true,
                "passed": true,
                "inExclusionZone": true,
                "inBufferZone": true,
                "distanceToBorder": 1234.5,
                "expected": true
            }
            """)

        #expect(region._id == "5c0e3e3b1d3b3b0012345678")
        #expect(region.name == "United States")
        #expect(region.code == "US")
        #expect(region.type == "country")
        #expect(region.flag == "🇺🇸")
        #expect(region.allowed)
        #expect(region.passed)
        #expect(region.inExclusionZone)
        #expect(region.inBufferZone)
        #expect(region.distanceToBorder == 1234.5)
        #expect(region.expected)
    }

    @Test("An empty dictionary produces a region with default values")
    func emptyDictionaryUsesDefaults() throws {
        let region = try #require(RadarRegion(object: [String: Any]()))

        #expect(region._id == "")
        #expect(region.name == "")
        #expect(region.code == "")
        #expect(region.type == "")
        // Matches the Objective-C parser, which defaulted a missing flag to an empty string.
        #expect(region.flag == "")
        #expect(!region.allowed)
        #expect(!region.passed)
        #expect(!region.inExclusionZone)
        #expect(!region.inBufferZone)
        #expect(region.distanceToBorder == 0)
        #expect(!region.expected)
    }

    @Test("Wrongly typed fields fall back to defaults")
    func wronglyTypedFieldsUseDefaults() throws {
        let region = try Self.decode(
            """
            {
                "_id": 1,
                "name": ["United States"],
                "code": null,
                "type": {},
                "flag": false,
                "allowed": "true",
                "passed": "yes",
                "inExclusionZone": [],
                "inBufferZone": {},
                "distanceToBorder": "12",
                "expected": null
            }
            """)

        #expect(region._id == "")
        #expect(region.name == "")
        #expect(region.code == "")
        #expect(region.type == "")
        #expect(region.flag == "")
        #expect(!region.allowed)
        #expect(!region.passed)
        #expect(!region.inExclusionZone)
        #expect(!region.inBufferZone)
        #expect(region.distanceToBorder == 0)
        #expect(!region.expected)
    }

    @Test("Numeric booleans are read like NSNumber boolValue")
    func numericBooleans() throws {
        let region = try Self.decode(#"{"allowed": 1, "passed": 0, "distanceToBorder": 7}"#)

        #expect(region.allowed)
        #expect(!region.passed)
        #expect(region.distanceToBorder == 7)
    }

    @Test("Non-dictionary input returns nil")
    func nonDictionaryReturnsNil() {
        #expect(RadarRegion(object: nil) == nil)
        #expect(RadarRegion(object: "US") == nil)
        #expect(RadarRegion(object: [1, 2, 3]) == nil)
        #expect(RadarRegion(object: NSNull()) == nil)
    }

    @Test("dictionaryValue serializes every field and round-trips")
    func dictionaryValueRoundTrips() throws {
        let region = RadarRegion(
            id: "id", name: "New York", code: "NY", type: "state", flag: "flag", allowed: true, passed: false,
            inExclusionZone: true, inBufferZone: false, distanceToBorder: 42, expected: true)
        let dict = try Self.dictionary(region)

        #expect(
            Set(dict.keys) == [
                "_id", "name", "code", "type", "flag", "allowed", "passed", "inExclusionZone", "inBufferZone",
                "distanceToBorder", "expected",
            ])
        #expect(dict["_id"] as? String == "id")
        #expect(dict["name"] as? String == "New York")
        #expect(dict["code"] as? String == "NY")
        #expect(dict["type"] as? String == "state")
        #expect(dict["flag"] as? String == "flag")
        #expect(dict["allowed"] as? Bool == true)
        #expect(dict["passed"] as? Bool == false)
        #expect(dict["inExclusionZone"] as? Bool == true)
        #expect(dict["inBufferZone"] as? Bool == false)
        #expect(dict["distanceToBorder"] as? Double == 42)
        #expect(dict["expected"] as? Bool == true)

        let reparsed = try #require(RadarRegion(object: dict))
        #expect(reparsed.dictionaryValue() as NSDictionary == dict as NSDictionary)
    }

    @Test("dictionaryValue omits a nil flag")
    func dictionaryValueOmitsNilFlag() throws {
        let region = RadarRegion(
            id: "id", name: "n", code: "c", type: "t", flag: nil, allowed: false, passed: false,
            inExclusionZone: false, inBufferZone: false, distanceToBorder: 0, expected: false)

        #expect(region.flag == nil)
        #expect(try Self.dictionary(region)["flag"] == nil)
        #expect(try Self.dictionary(region).count == 10)
    }

    @Test("Objective-C runtime name, selectors, and default initializer are preserved")
    func objectiveCCompatibility() throws {
        #expect(NSStringFromClass(RadarRegion.self) == "RadarRegion")
        #expect(NSClassFromString("RadarRegion") === RadarRegion.self)
        #expect(RadarRegion.instancesRespond(to: NSSelectorFromString("initWithObject:")))
        #expect(
            RadarRegion.instancesRespond(
                to: NSSelectorFromString(
                    "initWithId:name:code:type:flag:allowed:passed:inExclusionZone:inBufferZone:distanceToBorder:expected:"
                )))
        for selector in [
            "_id", "name", "code", "type", "flag", "allowed", "passed", "inExclusionZone", "inBufferZone",
            "distanceToBorder", "expected", "dictionaryValue",
        ] {
            #expect(RadarRegion.instancesRespond(to: NSSelectorFromString(selector)), "\(selector)")
        }

        let region = RadarRegion()
        #expect(region._id == "")
        #expect(region.flag == nil)
        #expect(region.value(forKey: "code") as? String == "")
        #expect(region.value(forKey: "allowed") as? Bool == false)
    }
}
