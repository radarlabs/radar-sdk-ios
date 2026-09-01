//
//  RadarTripCollectionTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/28/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTripCollectionTests")
struct RadarTripCollectionTests {

    // MARK: - Multi-leg Trips

    @Test("parses multi-leg trips and the current leg")
    func parsesMultiLegTrip() throws {
        var dictionary = RadarTripTestFixtures.trip()
        dictionary["currentLeg"] = "leg_001"
        dictionary["legs"] = [
            RadarTripTestFixtures.leg(
                id: "leg_001",
                status: "started",
                tag: "store",
                externalId: "store-1"
            ),
            RadarTripTestFixtures.leg(
                id: "leg_002",
                status: "pending",
                tag: "warehouse",
                externalId: "warehouse-1"
            ),
        ]

        let trip = try #require(RadarTrip(object: dictionary))
        let legs = try #require(trip.legs)

        #expect(trip.currentLegId == "leg_001")
        #expect(legs.count == 2)

        #expect(legs[0]._id == "leg_001")
        #expect(legs[0].status == .started)
        #expect(legs[0].destinationType == .geofence)
        #expect(legs[0].destinationGeofenceId == "geofence_leg_001")
        #expect(legs[0].destinationGeofenceTag == "store")
        #expect(legs[0].destinationGeofenceExternalId == "store-1")

        #expect(legs[1]._id == "leg_002")
        #expect(legs[1].status == .pending)
        #expect(legs[1].destinationGeofenceTag == "warehouse")
        #expect(legs[1].destinationGeofenceExternalId == "warehouse-1")
    }

    @Test("serializes legs and the current leg")
    func serializesMultiLegTrip() throws {
        var input = RadarTripTestFixtures.trip()
        input["currentLeg"] = "leg_001"
        input["legs"] = [
            RadarTripTestFixtures.leg(
                id: "leg_001",
                status: "started",
                tag: "store",
                externalId: "store-1"
            )
        ]

        let trip = try #require(RadarTrip(object: input))
        let dictionary = trip.dictionaryValue()

        #expect(dictionary["currentLeg"] as? String == "leg_001")

        let legs = try #require(dictionary["legs"] as? [[String: Any]])
        #expect(legs.count == 1)
        #expect(legs[0]["_id"] as? String == "leg_001")
        #expect(legs[0]["status"] as? String == "started")

        let destination = try #require(
            legs[0]["destination"] as? [String: Any]
        )
        #expect(destination["destinationGeofenceId"] as? String == "geofence_leg_001")
        #expect(destination["destinationGeofenceTag"] as? String == "store")
        #expect(
            destination["destinationGeofenceExternalId"] as? String == "store-1"
        )
    }

    @Test("drops malformed legs but preserves valid legs")
    func dropsMalformedLegs() throws {
        var mixedDictionary = RadarTripTestFixtures.trip()
        mixedDictionary["legs"] = [
            "not-a-leg",
            RadarTripTestFixtures.leg(
                id: "leg_001",
                status: "started",
                tag: "store",
                externalId: "store-1"
            ),
            NSNull(),
        ]

        let mixedTrip = try #require(RadarTrip(object: mixedDictionary))
        let validLegs = try #require(mixedTrip.legs)

        #expect(validLegs.count == 1)
        #expect(validLegs[0]._id == "leg_001")

        var malformedDictionary = RadarTripTestFixtures.trip()
        malformedDictionary["legs"] = ["not-a-leg", NSNull()]

        let malformedTrip = try #require(
            RadarTrip(object: malformedDictionary)
        )
        #expect(malformedTrip.legs == nil)

        var nonArrayDictionary = RadarTripTestFixtures.trip()
        nonArrayDictionary["legs"] = "not-an-array"
        nonArrayDictionary["currentLeg"] = 123

        let nonArrayTrip = try #require(
            RadarTrip(object: nonArrayDictionary)
        )
        #expect(nonArrayTrip.legs == nil)
        #expect(nonArrayTrip.currentLegId == nil)
    }

    // MARK: - Orders

    @Test("parses and serializes trip orders")
    func parsesAndSerializesOrders() throws {
        var input = RadarTripTestFixtures.trip()
        input["orders"] = [
            RadarTripTestFixtures.order(id: "order_001")
        ]

        let trip = try #require(RadarTrip(object: input))
        let orders = try #require(trip.orders)

        #expect(orders.count == 1)

        let order = orders[0]
        #expect(order._id == "order_001")
        #expect(order.guid == "guid-order_001")
        #expect(order.handoffMode == "manual")
        #expect(order.status == .fired)
        #expect(order.firedAttempts?.intValue == 2)
        #expect(order.firedReason == "driver-arrived")

        let firedAt = try #require(order.firedAt)
        #expect(order.updatedAt.timeIntervalSince(firedAt) == 60)

        let dictionary = trip.dictionaryValue()
        let serializedOrders = try #require(
            dictionary["orders"] as? [[String: Any]]
        )

        #expect(serializedOrders.count == 1)
        #expect(serializedOrders[0]["id"] as? String == "order_001")
        #expect(serializedOrders[0]["guid"] as? String == "guid-order_001")
        #expect(serializedOrders[0]["handoffMode"] as? String == "manual")
        #expect(serializedOrders[0]["status"] as? String == "fired")
        #expect(
            (serializedOrders[0]["firedAttempts"] as? NSNumber)?.intValue == 2
        )
        #expect(
            serializedOrders[0]["firedReason"] as? String == "driver-arrived"
        )
    }

    @Test("an invalid order invalidates the complete orders collection")
    func invalidOrderInvalidatesCollection() throws {
        var input = RadarTripTestFixtures.trip()
        input["orders"] = [
            RadarTripTestFixtures.order(id: "order_001"),
            [
                "id": "order_002"
                    // updatedAt is required.
            ],
        ]

        let trip = try #require(RadarTrip(object: input))

        #expect(trip.orders == nil)
        #expect(trip.dictionaryValue()["orders"] == nil)
    }

    @Test("preserves an empty orders array in memory but omits it when serializing")
    func preservesEmptyOrdersArray() throws {
        var input = RadarTripTestFixtures.trip()
        input["orders"] = []

        let trip = try #require(RadarTrip(object: input))
        let orders = try #require(trip.orders)

        #expect(orders.isEmpty)
        #expect(trip.dictionaryValue()["orders"] == nil)
    }

    @Test("ignores a non-array orders value")
    func ignoresNonArrayOrders() throws {
        var input = RadarTripTestFixtures.trip()
        input["orders"] = "not-an-array"

        let trip = try #require(RadarTrip(object: input))

        #expect(trip.orders == nil)
    }
}
