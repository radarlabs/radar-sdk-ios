//
//  RadarVerifiedLocationTokenTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

private let expiresAtString = "2026-01-02T03:04:05.000Z"

private func userObject() -> [String: Any] {
    [
        "_id": "test-user-id",
        "userId": "test-user",
        "location": ["type": "Point", "coordinates": [-73.9, 40.7]],
    ]
}

private func eventObject(id: String) -> [String: Any] {
    [
        "_id": id,
        "createdAt": expiresAtString,
        "actualCreatedAt": expiresAtString,
        "live": true,
        "type": "user.entered_geofence",
        "location": ["type": "Point", "coordinates": [-73.9, 40.7]],
    ]
}

// A `/track` response with `verified: true`, with no events so parsing doesn't use the bridge.
private func tokenObject() -> [String: Any] {
    [
        "token": "test-jwt",
        "expiresAt": expiresAtString,
        "expiresIn": 90,
        "passed": true,
        "failureReasons": ["fraud_mocked_from_mock_provider"],
        "_id": "test-token-id",
        "user": userObject(),
        "events": [],
        "extra": ["nested": true],
    ]
}

private func tokenObject(removing key: String) -> [String: Any] {
    var object = tokenObject()
    object[key] = nil
    return object
}

@Suite("RadarVerifiedLocationToken")
struct RadarVerifiedLocationTokenTests {

    // MARK: - initWithObject:

    @Test
    func parsesEveryField() throws {
        let token = try #require(RadarVerifiedLocationToken(object: tokenObject()))

        #expect(token.token == "test-jwt")
        #expect(token.expiresAt == RadarUtils.isoDateFormatter.date(from: expiresAtString))
        #expect(token.expiresIn == 90)
        #expect(token.passed)
        #expect(token.failureReasons == ["fraud_mocked_from_mock_provider"])
        #expect(token._id == "test-token-id")
        #expect(token.user?._id == "test-user-id")
        #expect(token.user?.userId == "test-user")
        #expect(token.events?.isEmpty == true)
    }

    @Test
    func optionalFieldsFallBackToDefaults() throws {
        let object = ["passed", "expiresIn", "failureReasons", "_id"].reduce(tokenObject()) { object, key in
            var object = object
            object[key] = nil
            return object
        }

        let token = try #require(RadarVerifiedLocationToken(object: object))

        #expect(token.expiresIn == 0)
        #expect(!token.passed)
        #expect(token.failureReasons == [])
        #expect(token._id == nil)
    }

    @Test
    func readsExpiresInAtFloatPrecision() throws {
        var object = tokenObject()
        object["expiresIn"] = 90.1

        let token = try #require(RadarVerifiedLocationToken(object: object))

        #expect(token.expiresIn == TimeInterval(Float(90.1)))
    }

    @Test(arguments: ["token", "expiresAt", "user", "events"])
    func requiredFieldMissingReturnsNil(key: String) {
        #expect(RadarVerifiedLocationToken(object: tokenObject(removing: key)) == nil)
    }

    @Test
    func malformedRequiredFieldReturnsNil() {
        let cases: [(String, Any)] = [
            ("token", 1),
            ("expiresAt", "not a date"),
            ("expiresAt", 1_700_000_000),
            ("user", "not a user"),
            ("events", ["not": "an array"]),
        ]
        for (key, value) in cases {
            var object = tokenObject()
            object[key] = value
            #expect(RadarVerifiedLocationToken(object: object) == nil, "\(key) = \(value)")
        }
    }

    @Test
    func malformedOptionalFieldsFallBackToDefaults() throws {
        var object = tokenObject()
        object["expiresIn"] = "90"
        object["passed"] = "true"
        object["failureReasons"] = "fraud"
        object["_id"] = 1

        let token = try #require(RadarVerifiedLocationToken(object: object))

        #expect(token.expiresIn == 0)
        #expect(!token.passed)
        #expect(token.failureReasons == [])
        #expect(token._id == nil)
    }

    @Test
    func nonDictionaryReturnsNil() {
        #expect(RadarVerifiedLocationToken(object: "not a dict") == nil)
        #expect(RadarVerifiedLocationToken(object: [tokenObject()]) == nil)
    }

    // MARK: - dictionaryValue

    @Test
    func dictionaryValueReturnsTheFullResponse() throws {
        let object = tokenObject()
        let token = try #require(RadarVerifiedLocationToken(object: object))

        let dictionary = token.dictionaryValue()

        #expect(NSDictionary(dictionary: dictionary).isEqual(to: object))
        #expect(NSDictionary(dictionary: try #require(token.fullDict)).isEqual(to: object))
    }

    @Test
    func emptyTokenHasNoValues() {
        let token = RadarVerifiedLocationToken()

        #expect(token.user == nil)
        #expect(token.events == nil)
        #expect(token.token == nil)
        #expect(token.expiresAt == nil)
        #expect(token.expiresIn == 0)
        #expect(!token.passed)
        #expect(token.failureReasons == nil)
        #expect(token._id == nil)
        #expect(token.fullDict == nil)
        #expect(token.dictionaryValue().isEmpty)
    }

    // MARK: - Objective-C compatibility

    @Test
    func keepsTheObjectiveCRuntimeName() {
        #expect(NSClassFromString("RadarVerifiedLocationToken") == RadarVerifiedLocationToken.self)
    }

    @Test(arguments: [
        "initWithObject:",
        "initWithUser:events:token:expiresAt:expiresIn:passed:failureReasons:_id:fullDict:",
        "user", "events", "token", "expiresAt", "expiresIn", "passed", "failureReasons", "_id", "fullDict",
        "dictionaryValue",
    ])
    func respondsToObjectiveCSelectors(selector: String) {
        #expect(RadarVerifiedLocationToken.instancesRespond(to: NSSelectorFromString(selector)))
    }

    @Test
    func exposesPropertiesThroughKeyValueCoding() throws {
        let token = try #require(RadarVerifiedLocationToken(object: tokenObject()))

        #expect(token.value(forKey: "token") as? String == "test-jwt")
        #expect(token.value(forKey: "passed") as? Bool == true)
        #expect(token.value(forKey: "expiresIn") as? Double == 90)
        #expect(token.value(forKey: "_id") as? String == "test-token-id")
        #expect(token.value(forKeyPath: "user._id") as? String == "test-user-id")
    }

    @Test
    func memberwiseInitializerStoresValues() throws {
        let user = try #require(RadarUser(object: userObject()))
        let expiresAt = Date(timeIntervalSince1970: 1_700_000_000)

        let token = RadarVerifiedLocationToken(
            user: user,
            events: [],
            token: "test-jwt",
            expiresAt: expiresAt,
            expiresIn: 60,
            passed: false,
            failureReasons: ["reason"],
            _id: nil,
            fullDict: ["token": "test-jwt"]
        )

        #expect(token.user === user)
        #expect(token.events?.isEmpty == true)
        #expect(token.token == "test-jwt")
        #expect(token.expiresAt == expiresAt)
        #expect(token.expiresIn == 60)
        #expect(!token.passed)
        #expect(token.failureReasons == ["reason"])
        #expect(token._id == nil)
        #expect(token.dictionaryValue() as? [String: String] == ["token": "test-jwt"])
    }
}

// Event parsing goes through `RadarSwift.bridge`, so these tests swap the global bridge.
extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarVerifiedLocationTokenEventTests {

        private func withBridge<T>(_ bridge: RadarSwiftBridgeProtocol?, _ body: () throws -> T) rethrows -> T {
            let original = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer { RadarSwift.bridge = original }
            return try body()
        }

        private func eventBridge() -> MockRadarSwiftBridge {
            let bridge = MockRadarSwiftBridge()
            bridge.createEventHandler = { RadarEvent(object: $0) }
            return bridge
        }

        @Test
        func parsesEventsInOrder() throws {
            var object = tokenObject()
            object["events"] = [eventObject(id: "event-1"), eventObject(id: "event-2")]

            let token = try #require(withBridge(eventBridge()) { RadarVerifiedLocationToken(object: object) })

            #expect(token.events?.map(\._id) == ["event-1", "event-2"])
            #expect(token.events?.first?.type == .userEnteredGeofence)
        }

        @Test
        func anyUnparseableEventReturnsNil() {
            var object = tokenObject()
            object["events"] = [eventObject(id: "event-1"), "not an event"]

            #expect(withBridge(eventBridge()) { RadarVerifiedLocationToken(object: object) } == nil)
        }

        @Test
        func eventRejectedByTheBridgeReturnsNil() {
            var object = tokenObject()
            object["events"] = [eventObject(id: "event-1")]

            #expect(withBridge(MockRadarSwiftBridge()) { RadarVerifiedLocationToken(object: object) } == nil)
        }

        @Test
        func emptyEventsDoNotNeedTheBridge() {
            #expect(withBridge(nil) { RadarVerifiedLocationToken(object: tokenObject()) } != nil)
        }
    }
}
