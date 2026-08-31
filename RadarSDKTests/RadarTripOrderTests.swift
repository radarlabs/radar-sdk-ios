//
//  RadarTripOrderTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTripOrderTests")
struct RadarTripOrderTests {

    @Test("rejects invalid objects and missing required fields")
    func rejectsInvalidObjects() {
        #expect(RadarTripOrder(object: "order") == nil)

        var missingId = RadarTripTestFixtures.order(id: "order_001")
        missingId.removeValue(forKey: "id")

        var invalidId = RadarTripTestFixtures.order(id: "order_001")
        invalidId["id"] = 123

        var missingUpdatedAt = RadarTripTestFixtures.order(id: "order_001")
        missingUpdatedAt.removeValue(forKey: "updatedAt")

        var invalidUpdatedAt = RadarTripTestFixtures.order(id: "order_001")
        invalidUpdatedAt["updatedAt"] = "not-a-date"

        #expect(RadarTripOrder(object: missingId) == nil)
        #expect(RadarTripOrder(object: invalidId) == nil)
        #expect(RadarTripOrder(object: missingUpdatedAt) == nil)
        #expect(RadarTripOrder(object: invalidUpdatedAt) == nil)
    }

    @Test("parses a complete order")
    func parsesCompleteOrder() throws {
        let order = try #require(
            RadarTripOrder(
                object: RadarTripTestFixtures.order(id: "order_001")
            )
        )

        #expect(order._id == "order_001")
        #expect(order.guid == "guid-order_001")
        #expect(order.handoffMode == "manual")
        #expect(order.status == .fired)
        #expect(order.firedAttempts?.intValue == 2)
        #expect(order.firedReason == "driver-arrived")

        let firedAt = try #require(order.firedAt)
        #expect(order.updatedAt.timeIntervalSince(firedAt) == 60)
    }

    @Test("maps every recognized order status")
    func mapsStatuses() throws {
        let cases: [(String, RadarTripOrderStatus)] = [
            ("pending", .pending),
            ("fired", .fired),
            ("canceled", .canceled),
            ("completed", .completed),
        ]

        for (value, expected) in cases {
            let order = try #require(
                RadarTripOrder(
                    object: RadarTripTestFixtures.order(
                        id: "order_001",
                        status: value
                    )
                )
            )

            #expect(order.status == expected)
        }
    }

    @Test("defaults unknown and malformed statuses to unknown")
    func defaultsStatusesToUnknown() throws {
        let values: [Any] = ["unknown-status", "", 123, NSNull()]

        for value in values {
            var dictionary = RadarTripTestFixtures.order(id: "order_001")
            dictionary["status"] = value

            let order = try #require(RadarTripOrder(object: dictionary))
            #expect(order.status == .unknown)
        }

        var missingStatus = RadarTripTestFixtures.order(id: "order_001")
        missingStatus.removeValue(forKey: "status")

        let order = try #require(RadarTripOrder(object: missingStatus))
        #expect(order.status == .unknown)
    }

    @Test("ignores malformed optional fields")
    func ignoresMalformedOptionalFields() throws {
        var dictionary = RadarTripTestFixtures.order(id: "order_001")
        dictionary["guid"] = 123
        dictionary["handoffMode"] = false
        dictionary["firedAt"] = "not-a-date"
        dictionary["firedAttempts"] = "two"
        dictionary["firedReason"] = 456

        let order = try #require(RadarTripOrder(object: dictionary))

        #expect(order.guid == nil)
        #expect(order.handoffMode == nil)
        #expect(order.firedAt == nil)
        #expect(order.firedAttempts == nil)
        #expect(order.firedReason == nil)
    }

    @Test("serializes a complete order using the existing wire format")
    func serializesCompleteOrder() throws {
        let order = try #require(
            RadarTripOrder(
                object: RadarTripTestFixtures.order(id: "order_001")
            )
        )

        let dictionary = order.dictionaryValue()

        #expect(dictionary["id"] as? String == "order_001")
        #expect(dictionary["guid"] as? String == "guid-order_001")
        #expect(dictionary["handoffMode"] as? String == "manual")
        #expect(dictionary["status"] as? String == "fired")
        #expect(
            dictionary["firedAt"] as? String
                == "2026-02-24T12:04:00.000+0000"
        )
        #expect(
            (dictionary["firedAttempts"] as? NSNumber)?.intValue == 2
        )
        #expect(dictionary["firedReason"] as? String == "driver-arrived")
        #expect(
            dictionary["updatedAt"] as? String
                == "2026-02-24T12:05:00.000+0000"
        )
    }

    @Test("omits absent optional fields when serializing")
    func omitsAbsentOptionalFields() throws {
        var input = RadarTripTestFixtures.order(id: "order_001")
        input.removeValue(forKey: "guid")
        input.removeValue(forKey: "handoffMode")
        input.removeValue(forKey: "status")
        input.removeValue(forKey: "firedAt")
        input.removeValue(forKey: "firedAttempts")
        input.removeValue(forKey: "firedReason")

        let order = try #require(RadarTripOrder(object: input))
        let dictionary = order.dictionaryValue()

        #expect(dictionary["id"] as? String == "order_001")
        #expect(dictionary["status"] as? String == "unknown")
        #expect(dictionary["guid"] == nil)
        #expect(dictionary["handoffMode"] == nil)
        #expect(dictionary["firedAt"] == nil)
        #expect(dictionary["firedAttempts"] == nil)
        #expect(dictionary["firedReason"] == nil)
        #expect(
            dictionary["updatedAt"] as? String
                == "2026-02-24T12:05:00.000+0000"
        )
    }

    @Test("parses order collections atomically")
    func parsesOrderCollectionsAtomically() throws {
        let validOrders = try #require(
            RadarTripOrder.orders(
                from: [
                    RadarTripTestFixtures.order(id: "order_001"),
                    RadarTripTestFixtures.order(id: "order_002"),
                ]
            )
        )

        #expect(validOrders.count == 2)
        #expect(validOrders[0]._id == "order_001")
        #expect(validOrders[1]._id == "order_002")

        let emptyOrders = try #require(
            RadarTripOrder.orders(from: [])
        )
        #expect(emptyOrders.isEmpty)

        #expect(RadarTripOrder.orders(from: "not-an-array") == nil)
        #expect(
            RadarTripOrder.orders(
                from: [
                    RadarTripTestFixtures.order(id: "order_001"),
                    ["id": "order_002"],
                ]
            ) == nil
        )
    }
}
