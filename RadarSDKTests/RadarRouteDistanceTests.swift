//
//  RadarRouteDistanceTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarRouteDistanceTests")
struct RadarRouteDistanceTests {

    @Test("Stores the values passed to the designated initializer")
    func storesInitializerValues() {
        let distance = RadarRouteDistance(value: 1234.5, text: "1234.5 ft")

        #expect(distance.value == 1234.5)
        #expect(distance.text == "1234.5 ft")
    }

    @Test("Parses a fully populated dictionary")
    func parsesFullDictionary() throws {
        let distance = try #require(RadarRouteDistance(object: ["value": 1000, "text": "1000 ft"]))

        #expect(distance.value == 1000)
        #expect(distance.text == "1000 ft")
    }

    @Test("Defaults value to 0 when it is missing or not a number")
    func defaultsMissingValue() throws {
        #expect(try #require(RadarRouteDistance(object: ["text": "0 ft"])).value == 0)
        #expect(try #require(RadarRouteDistance(object: ["value": "1000", "text": "0 ft"])).value == 0)
        #expect(try #require(RadarRouteDistance(object: ["value": NSNull(), "text": "0 ft"])).value == 0)
    }

    @Test("Rejects a payload without a string text")
    func rejectsMissingText() {
        #expect(RadarRouteDistance(object: ["value": 1000]) == nil)
        #expect(RadarRouteDistance(object: ["value": 1000, "text": 5]) == nil)
        #expect(RadarRouteDistance(object: ["value": 1000, "text": NSNull()]) == nil)
    }

    @Test("Rejects non-dictionary payloads")
    func rejectsNonDictionaryPayloads() {
        #expect(RadarRouteDistance(object: []) == nil)
        #expect(RadarRouteDistance(object: "not a dictionary") == nil)
        #expect(RadarRouteDistance(object: NSNull()) == nil)
    }

    @Test("Serializes both fields to the wire dictionary")
    func serializesDictionaryValue() {
        let dictionary = RadarRouteDistance(value: 1234.5, text: "1234.5 ft").dictionaryValue()

        #expect(dictionary.keys.sorted() == ["text", "value"])
        #expect(dictionary["value"] as? Double == 1234.5)
        #expect(dictionary["text"] as? String == "1234.5 ft")
    }

    @Test("Round-trips a parsed distance back through dictionaryValue")
    func roundTripsThroughDictionary() throws {
        let original = try #require(RadarRouteDistance(object: ["value": 42.5, "text": "42.5 ft"]))
        let reparsed = try #require(RadarRouteDistance(object: original.dictionaryValue()))

        #expect(reparsed.value == original.value)
        #expect(reparsed.text == original.text)
    }

    @Test("Keeps the Objective-C runtime name and selectors")
    func keepsObjectiveCContract() throws {
        let distance = try #require(RadarRouteDistance(object: ["value": 1000, "text": "1000 ft"]))

        #expect(NSStringFromClass(RadarRouteDistance.self) == "RadarRouteDistance")
        #expect(distance.responds(to: NSSelectorFromString("value")))
        #expect(distance.responds(to: NSSelectorFromString("text")))
        #expect(distance.responds(to: NSSelectorFromString("dictionaryValue")))

        // Read back through KVC to prove the Objective-C property and method names survived.
        let asNSObject: NSObject = distance
        #expect((asNSObject.value(forKey: "value") as? NSNumber)?.doubleValue == 1000)
        #expect(asNSObject.value(forKey: "text") as? String == "1000 ft")
    }
}
