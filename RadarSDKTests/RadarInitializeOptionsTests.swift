//
//  RadarInitializeOptionsTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarInitializeOptionsTests")
struct RadarInitializeOptionsTests {

    // MARK: - Defaults

    @Test("A fresh instance uses the documented defaults")
    func defaults() {
        let options = RadarInitializeOptions()

        #expect(options.autoLogNotificationConversions == false)
        #expect(options.autoHandleNotificationDeepLinks == false)
        #expect(options.silentPush == false)
        #expect(options.trackVerifiedAutoFailover == false)
        #expect(options.networkTimeoutInterval == 10)
        #expect(options.ipChangeDebounceInterval == 10)
    }

    @Test("An empty dictionary decodes to the defaults")
    func emptyDictionary() {
        let options = RadarInitializeOptions(dict: [:])

        #expect(options.autoLogNotificationConversions == false)
        #expect(options.autoHandleNotificationDeepLinks == false)
        #expect(options.silentPush == false)
        #expect(options.trackVerifiedAutoFailover == false)
        #expect(options.networkTimeoutInterval == 10)
        #expect(options.ipChangeDebounceInterval == 10)
    }

    @Test("A nil dictionary decodes to the defaults")
    func nilDictionary() {
        let options = RadarInitializeOptions(dict: nil)

        #expect(options.networkTimeoutInterval == 10)
        #expect(options.ipChangeDebounceInterval == 10)
        #expect(options.silentPush == false)
    }

    // MARK: - Dictionary round trip

    @Test("Every property survives a dictionary round trip")
    func roundTrip() {
        let options = RadarInitializeOptions()
        options.autoLogNotificationConversions = true
        options.autoHandleNotificationDeepLinks = true
        options.silentPush = true
        options.trackVerifiedAutoFailover = true
        options.networkTimeoutInterval = 45
        options.ipChangeDebounceInterval = 2.5

        let restored = RadarInitializeOptions(dict: options.dictionaryValue())

        #expect(restored.autoLogNotificationConversions)
        #expect(restored.autoHandleNotificationDeepLinks)
        #expect(restored.silentPush)
        #expect(restored.trackVerifiedAutoFailover)
        #expect(restored.networkTimeoutInterval == 45)
        #expect(restored.ipChangeDebounceInterval == 2.5)
    }

    @Test("dictionaryValue emits values Objective-C and UserDefaults can read back")
    func dictionaryValueBridgesToNSNumber() throws {
        let options = RadarInitializeOptions()
        options.silentPush = true
        options.networkTimeoutInterval = 30

        let dict = options.dictionaryValue()

        #expect(dict["silentPush"] as? NSNumber == NSNumber(value: true))
        #expect(dict["autoLogNotificationConversions"] as? NSNumber == NSNumber(value: false))
        let timeout = try #require(dict["networkTimeoutInterval"] as? NSNumber)
        #expect(timeout.doubleValue == 30)
    }

    @Test("A round trip through a property list preserves the values")
    func roundTripThroughPropertyList() throws {
        let options = RadarInitializeOptions()
        options.trackVerifiedAutoFailover = true
        options.networkTimeoutInterval = 12.5
        options.ipChangeDebounceInterval = 0

        let data = try PropertyListSerialization.data(
            fromPropertyList: options.dictionaryValue(), format: .binary, options: 0)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        let restored = RadarInitializeOptions(dict: try #require(plist as? [String: Any]))

        #expect(restored.trackVerifiedAutoFailover)
        #expect(restored.networkTimeoutInterval == 12.5)
        #expect(restored.ipChangeDebounceInterval == 0)
    }

    // MARK: - networkTimeoutInterval validation

    @Test(
        "Invalid network timeouts fall back to 10",
        arguments: [0, -1, Double.nan, Double.infinity, -Double.infinity])
    func invalidNetworkTimeoutFallsBack(value: Double) {
        let options = RadarInitializeOptions(dict: ["networkTimeoutInterval": value])

        #expect(options.networkTimeoutInterval == 10)
    }

    @Test("A valid network timeout is kept as-is and is not clamped by the model")
    func validNetworkTimeoutIsKept() {
        #expect(RadarInitializeOptions(dict: ["networkTimeoutInterval": 0.5]).networkTimeoutInterval == 0.5)
        #expect(RadarInitializeOptions(dict: ["networkTimeoutInterval": 600]).networkTimeoutInterval == 600)
    }

    @Test("A numeric string network timeout parses, an unparseable one falls back to 10")
    func stringNetworkTimeout() {
        #expect(RadarInitializeOptions(dict: ["networkTimeoutInterval": "45"]).networkTimeoutInterval == 45)
        #expect(RadarInitializeOptions(dict: ["networkTimeoutInterval": "abc"]).networkTimeoutInterval == 10)
    }

    @Test("An unsupported value type falls back to 10")
    func unsupportedTypeFallsBack() {
        #expect(RadarInitializeOptions(dict: ["networkTimeoutInterval": NSNull()]).networkTimeoutInterval == 10)
    }

    // MARK: - ipChangeDebounceInterval validation

    @Test("Zero disables debounce rather than falling back to the default")
    func zeroDebounceIsPreserved() {
        #expect(RadarInitializeOptions(dict: ["ipChangeDebounceInterval": 0]).ipChangeDebounceInterval == 0)
    }

    @Test(
        "Invalid debounce intervals fall back to 10",
        arguments: [-1, Double.nan, Double.infinity, -Double.infinity])
    func invalidDebounceFallsBack(value: Double) {
        let options = RadarInitializeOptions(dict: ["ipChangeDebounceInterval": value])

        #expect(options.ipChangeDebounceInterval == 10)
    }

    // MARK: - Boolean decoding

    @Test("Booleans decode from the NSNumber representations Objective-C writes")
    func booleansDecodeFromNSNumber() {
        let options = RadarInitializeOptions(dict: [
            "autoLogNotificationConversions": NSNumber(value: true),
            "autoHandleNotificationDeepLinks": NSNumber(value: 1),
            "silentPush": NSNumber(value: 0),
        ])

        #expect(options.autoLogNotificationConversions)
        #expect(options.autoHandleNotificationDeepLinks)
        #expect(options.silentPush == false)
    }

    @Test("Booleans decode from string representations")
    func booleansDecodeFromStrings() {
        let options = RadarInitializeOptions(dict: ["silentPush": "true", "trackVerifiedAutoFailover": "false"])

        #expect(options.silentPush)
        #expect(options.trackVerifiedAutoFailover == false)
    }
}
