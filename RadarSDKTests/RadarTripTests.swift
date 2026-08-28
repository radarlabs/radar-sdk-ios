//
//  RadarTripTests.swift
//  RadarSDKTests
//
//  Created by Alan Charles on 8/28/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTripTests")
struct RadarTripTests {

    // MARK: - Validation

    @Test("rejects a non-dictionary object")
    func rejectsNonDictionary() {
        #expect(RadarTrip(object: "trip") == nil)
        #expect(RadarTrip(object: []) == nil)
        #expect(RadarTrip(object: NSNull()) == nil)
    }

    @Test("requires a string external ID")
    func requiresExternalId() {
        var missingExternalId = RadarTripTestFixtures.trip()
        missingExternalId.removeValue(forKey: "externalId")

        var invalidExternalId = RadarTripTestFixtures.trip()
        invalidExternalId["externalId"] = 123

        #expect(RadarTrip(object: missingExternalId) == nil)
        #expect(RadarTrip(object: invalidExternalId) == nil)
    }

    @Test("does not require a trip ID")
    func doesNotRequireTripId() {
        var dictionary = RadarTripTestFixtures.trip()
        dictionary.removeValue(forKey: "_id")

        #expect(RadarTrip(object: dictionary) != nil)
    }

    // MARK: - Parsing

    @Test("parses a complete trip")
    func parsesCompleteTrip() throws {
        let trip = try #require(RadarTrip(object: RadarTripTestFixtures.trip()))

        #expect(trip._id == "trip_abc123")
        #expect(trip.externalId == "order-456")
        #expect(trip.metadata?["driver"] as? String == "testDriver")
        #expect(trip.destinationGeofenceTag == "store")
        #expect(trip.destinationGeofenceExternalId == "store-1")
        #expect(trip.mode == .car)
        #expect(trip.etaDistance == 5_000)
        #expect(trip.etaDuration == 12.5)
        #expect(trip.status == .started)

        let destination = try #require(trip.destinationLocation)
        #expect(abs(destination.coordinate.latitude - 40.783825) < 0.000_001)
        #expect(abs(destination.coordinate.longitude - -73.975365) < 0.000_001)
    }

    @Test("maps every recognized route mode")
    func parsesRouteModes() throws {
        let cases: [(String, RadarRouteMode)] = [
            ("car", .car),
            ("foot", .foot),
            ("bike", .bike),
            ("truck", .truck),
            ("motorbike", .motorbike),
        ]

        for (value, expected) in cases {
            var dictionary = RadarTripTestFixtures.trip()
            dictionary["mode"] = value

            let trip = try #require(RadarTrip(object: dictionary))
            #expect(trip.mode == expected)
        }
    }

    @Test("defaults unknown and malformed route modes to car")
    func defaultsRouteModeToCar() throws {
        let values: [Any] = ["spaceship", "", 123, NSNull()]

        for value in values {
            var dictionary = RadarTripTestFixtures.trip()
            dictionary["mode"] = value

            let trip = try #require(RadarTrip(object: dictionary))
            #expect(trip.mode == .car)
        }

        var missingMode = RadarTripTestFixtures.trip()
        missingMode.removeValue(forKey: "mode")

        let trip = try #require(RadarTrip(object: missingMode))
        #expect(trip.mode == .car)
    }

    @Test("maps every recognized trip status")
    func parsesStatuses() throws {
        let cases: [(String, RadarTripStatus)] = [
            ("started", .started),
            ("approaching", .approaching),
            ("arrived", .arrived),
            ("expired", .expired),
            ("completed", .completed),
            ("canceled", .canceled),
        ]

        for (value, expected) in cases {
            var dictionary = RadarTripTestFixtures.trip()
            dictionary["status"] = value

            let trip = try #require(RadarTrip(object: dictionary))
            #expect(trip.status == expected)
        }
    }

    @Test("defaults unknown and malformed statuses to unknown")
    func defaultsStatusToUnknown() throws {
        let values: [Any] = ["pending", "", 123, NSNull()]

        for value in values {
            var dictionary = RadarTripTestFixtures.trip()
            dictionary["status"] = value

            let trip = try #require(RadarTrip(object: dictionary))
            #expect(trip.status == .unknown)
        }

        var missingStatus = RadarTripTestFixtures.trip()
        missingStatus.removeValue(forKey: "status")

        let trip = try #require(RadarTrip(object: missingStatus))
        #expect(trip.status == .unknown)
    }

    @Test("defaults missing and malformed ETA values to zero")
    func defaultsEtaValuesToZero() throws {
        var missingEta = RadarTripTestFixtures.trip()
        missingEta.removeValue(forKey: "eta")

        let tripWithoutEta = try #require(RadarTrip(object: missingEta))
        #expect(tripWithoutEta.etaDistance == 0)
        #expect(tripWithoutEta.etaDuration == 0)

        var malformedEta = RadarTripTestFixtures.trip()
        malformedEta["eta"] = [
            "distance": "far",
            "duration": NSNull(),
        ]

        let tripWithMalformedEta = try #require(RadarTrip(object: malformedEta))
        #expect(tripWithMalformedEta.etaDistance == 0)
        #expect(tripWithMalformedEta.etaDuration == 0)
    }

    @Test("ignores malformed optional fields")
    func ignoresMalformedOptionalFields() throws {
        var dictionary = RadarTripTestFixtures.trip()
        dictionary["metadata"] = "metadata"
        dictionary["destinationGeofenceTag"] = 123
        dictionary["destinationGeofenceExternalId"] = false
        dictionary["destinationLocation"] = "location"

        let trip = try #require(RadarTrip(object: dictionary))

        #expect(trip.metadata == nil)
        #expect(trip.destinationGeofenceTag == nil)
        #expect(trip.destinationGeofenceExternalId == nil)
        #expect(trip.destinationLocation == nil)
    }

    @Test("rejects malformed destination coordinates")
    func rejectsMalformedDestinationCoordinates() {
        let malformedLocations: [[String: Any]] = [
            [:],
            ["coordinates": []],
            ["coordinates": [-73.975365]],
            ["coordinates": [-73.975365, 40.783825, 10]],
            ["coordinates": ["west", 40.783825]],
            ["coordinates": [-73.975365, "north"]],
        ]

        for location in malformedLocations {
            var dictionary = RadarTripTestFixtures.trip()
            dictionary["destinationLocation"] = location

            #expect(RadarTrip(object: dictionary) == nil)
        }
    }

    // MARK: - Serialization

    @Test("serializes a complete trip using the existing wire format")
    func serializesCompleteTrip() throws {
        let trip = try #require(RadarTrip(object: RadarTripTestFixtures.trip()))
        let dictionary = trip.dictionaryValue()

        #expect(dictionary["_id"] as? String == "trip_abc123")
        #expect(dictionary["externalId"] as? String == "order-456")
        #expect(dictionary["destinationGeofenceTag"] as? String == "store")
        #expect(dictionary["destinationGeofenceExternalId"] as? String == "store-1")
        #expect(dictionary["mode"] as? String == "car")
        #expect(dictionary["status"] as? String == "started")

        let metadata = try #require(dictionary["metadata"] as? [String: Any])
        #expect(metadata["driver"] as? String == "testDriver")

        let eta = try #require(dictionary["eta"] as? [String: Any])
        #expect((eta["distance"] as? NSNumber)?.doubleValue == 5_000)
        #expect((eta["duration"] as? NSNumber)?.doubleValue == 12.5)

        let destination = try #require(
            dictionary["destinationLocation"] as? [String: Any]
        )
        #expect(destination["type"] as? String == "Point")

        let coordinates = try #require(
            destination["coordinates"] as? [NSNumber]
        )
        #expect(coordinates.count == 2)
        #expect(
            abs(coordinates[0].doubleValue - -73.975365) < 0.000_001
        )
        #expect(
            abs(coordinates[1].doubleValue - 40.783825) < 0.000_001
        )
    }

    @Test("omits absent optional and collection fields")
    func omitsAbsentFields() throws {
        var input = RadarTripTestFixtures.trip()
        input.removeValue(forKey: "metadata")
        input.removeValue(forKey: "destinationGeofenceTag")
        input.removeValue(forKey: "destinationGeofenceExternalId")
        input.removeValue(forKey: "destinationLocation")
        input.removeValue(forKey: "eta")

        let trip = try #require(RadarTrip(object: input))
        let dictionary = trip.dictionaryValue()

        #expect(dictionary["metadata"] == nil)
        #expect(dictionary["destinationGeofenceTag"] == nil)
        #expect(dictionary["destinationGeofenceExternalId"] == nil)
        #expect(dictionary["destinationLocation"] == nil)
        #expect(dictionary["orders"] == nil)
        #expect(dictionary["legs"] == nil)
        #expect(dictionary["currentLeg"] == nil)

        let eta = try #require(dictionary["eta"] as? [String: Any])
        #expect((eta["distance"] as? NSNumber)?.doubleValue == 0)
        #expect((eta["duration"] as? NSNumber)?.doubleValue == 0)
    }

    @Test("round-trips through dictionaryValue")
    func dictionaryRoundTrip() throws {
        let original = try #require(RadarTrip(object: RadarTripTestFixtures.trip()))
        let restored = try #require(RadarTrip(object: original.dictionaryValue()))

        #expect(restored._id == original._id)
        #expect(restored.externalId == original.externalId)
        #expect(restored.destinationGeofenceTag == original.destinationGeofenceTag)
        #expect(
            restored.destinationGeofenceExternalId
                == original.destinationGeofenceExternalId
        )
        #expect(restored.mode == original.mode)
        #expect(restored.etaDistance == original.etaDistance)
        #expect(restored.etaDuration == original.etaDuration)
        #expect(restored.status == original.status)

        let restoredLocation = try #require(restored.destinationLocation)
        let originalLocation = try #require(original.destinationLocation)

        #expect(
            restoredLocation.coordinate.latitude
                == originalLocation.coordinate.latitude
        )
        #expect(
            restoredLocation.coordinate.longitude
                == originalLocation.coordinate.longitude
        )
    }
}
