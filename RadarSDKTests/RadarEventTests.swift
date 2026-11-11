//
//  RadarEventTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import ObjectiveC
import Testing

@testable import RadarSDK

private let createdAtString = "2026-07-20T12:00:00.000Z"
private let actualCreatedAtString = "2026-07-20T12:00:05.000Z"

private func geofenceObject() -> [String: Any] {
    [
        "_id": "geofence-id",
        "description": "Geofence",
        "tag": "store",
        "externalId": "external-geofence",
        "type": "circle",
        "geometryRadius": 100,
        "geometryCenter": ["type": "Point", "coordinates": [-73.9, 40.7]],
    ]
}

private func beaconObject() -> [String: Any] {
    [
        "_id": "beacon-id",
        "description": "Beacon",
        "tag": "store",
        "externalId": "external-beacon",
        "uuid": "b9407f30-f5f8-466e-aff9-25556b57fe6d",
        "major": "100",
        "minor": "1",
        "geometry": ["type": "Point", "coordinates": [-73.9, 40.7]],
    ]
}

private func placeObject(id: String) -> [String: Any] {
    [
        "_id": id,
        "name": "Place \(id)",
        "categories": ["food-beverage"],
        "location": ["type": "Point", "coordinates": [-73.9, 40.7]],
    ]
}

// The fields every event needs: `_id`, `createdAt`, `actualCreatedAt`, and `location`.
private func baseEventObject() -> [String: Any] {
    [
        "_id": "event-id",
        "createdAt": createdAtString,
        "actualCreatedAt": actualCreatedAtString,
        "location": ["type": "Point", "coordinates": [-73.9, 40.7]],
    ]
}

private func fullEventObject() -> [String: Any] {
    var object = baseEventObject()
    object["live"] = true
    object["type"] = "user.entered_place"
    object["geofence"] = geofenceObject()
    object["place"] = placeObject(id: "place-id")
    object["region"] = ["_id": "us", "name": "United States", "code": "US", "type": "country"]
    object["beacon"] = beaconObject()
    object["trip"] = ["_id": "trip-id", "externalId": "trip-external-id", "status": "started"]
    object["fraud"] = ["passed": true, "proxy": false]
    object["alternatePlaces"] = [placeObject(id: "alt-1"), placeObject(id: "alt-2")]
    object["verifiedPlace"] = placeObject(id: "verified-id")
    object["verification"] = 1
    object["confidence"] = 3
    object["duration"] = 12.5
    object["location"] = ["type": "Point", "coordinates": [-73.9906, 40.7356, 12.5]]
    object["locationAccuracy"] = 8
    object["replayed"] = true
    object["metadata"] = ["campaign": "spring"]
    return object
}

@Suite("RadarEventTests")
struct RadarEventTests {

    private func parse(_ object: [String: Any]) throws -> RadarEvent {
        try #require(RadarEvent(object: object))
    }

    @Test("Parses every field")
    func parsesEveryField() throws {
        let event = try parse(fullEventObject())

        #expect(event._id == "event-id")
        #expect(event.createdAt == RadarUtils.isoDateFormatter.date(from: createdAtString))
        #expect(event.actualCreatedAt == RadarUtils.isoDateFormatter.date(from: actualCreatedAtString))
        #expect(event.live)
        #expect(event.type == .userEnteredPlace)
        #expect(event.conversionName == nil)
        #expect(event.geofence?._id == "geofence-id")
        #expect(event.place?._id == "place-id")
        #expect(event.region?._id == "us")
        #expect(event.beacon?._id == "beacon-id")
        #expect(event.trip?._id == "trip-id")
        #expect(event.fraud?.passed == true)
        #expect(event.alternatePlaces?.map(\._id) == ["alt-1", "alt-2"])
        #expect(event.verifiedPlace?._id == "verified-id")
        #expect(event.verification == .accept)
        #expect(event.confidence == .high)
        #expect(event.duration == 12.5)
        #expect(event.location.coordinate.latitude == 40.7356)
        #expect(event.location.coordinate.longitude == -73.9906)
        #expect(event.location.altitude == 12.5)
        #expect(event.location.horizontalAccuracy == 8)
        #expect(event.location.verticalAccuracy == -1)
        #expect(event.location.timestamp == event.createdAt)
        #expect(event.replayed)
        #expect(event.metadata["campaign"] as? String == "spring")
    }

    @Test("Defaults optional fields when only the required fields are present")
    func defaultsOptionalFields() throws {
        let event = try parse(baseEventObject())

        #expect(event.type == .unknown)
        #expect(event.conversionName == nil)
        #expect(!event.live)
        #expect(!event.replayed)
        #expect(event.verification == .unverify)
        #expect(event.confidence == .none)
        #expect(event.duration == 0)
        #expect(event.geofence == nil)
        #expect(event.place == nil)
        #expect(event.region == nil)
        #expect(event.beacon == nil)
        #expect(event.trip == nil)
        #expect(event.fraud == nil)
        #expect(event.alternatePlaces == nil)
        #expect(event.verifiedPlace == nil)
        #expect(event.actualCreatedAt == RadarUtils.isoDateFormatter.date(from: actualCreatedAtString))
        // `metadata` is nonnull, so a missing value is empty instead of nil.
        #expect(event.metadata.isEmpty)
        #expect(event.location.coordinate.latitude == 40.7)
        #expect(event.location.coordinate.longitude == -73.9)
        #expect(event.location.horizontalAccuracy == -1)
    }

    @Test("Returns nil for a non-dictionary, or without _id or a valid createdAt or actualCreatedAt")
    func rejectsMissingRequiredFields() {
        #expect(RadarEvent(object: "event") == nil)
        #expect(RadarEvent(object: nil) == nil)

        for key in ["_id", "createdAt", "actualCreatedAt"] {
            var object = baseEventObject()
            object[key] = nil
            #expect(RadarEvent(object: object) == nil, "missing \(key)")
        }

        var badCreatedAt = baseEventObject()
        badCreatedAt["createdAt"] = "yesterday"
        #expect(RadarEvent(object: badCreatedAt) == nil)

        var badActualCreatedAt = baseEventObject()
        badActualCreatedAt["actualCreatedAt"] = 12
        #expect(RadarEvent(object: badActualCreatedAt) == nil)
    }

    @Test("Returns nil for a missing or non-dictionary location")
    func rejectsMissingLocation() {
        var noLocation = baseEventObject()
        noLocation["location"] = nil
        #expect(RadarEvent(object: noLocation) == nil)

        var stringLocation = baseEventObject()
        stringLocation["location"] = "not-a-dictionary"
        #expect(RadarEvent(object: stringLocation) == nil)
    }

    @Test("Returns nil for a malformed location")
    func rejectsMalformedLocation() {
        let locations: [[String: Any]] = [
            ["type": "Point"],
            ["coordinates": "not-an-array"],
            ["coordinates": [1.0]],
            ["coordinates": [1.0, 2.0, 3.0, 4.0]],
            ["coordinates": ["a", 2.0]],
        ]
        for location in locations {
            var object = baseEventObject()
            object["location"] = location
            #expect(RadarEvent(object: object) == nil, "\(location)")
        }
    }

    @Test("Ignores a non-numeric altitude and location accuracy")
    func lenientLocationFields() throws {
        var object = baseEventObject()
        object["location"] = ["coordinates": [-73.9, 40.7, "high"]]
        object["locationAccuracy"] = "precise"
        let event = try parse(object)
        #expect(event.location.altitude == -1)
        #expect(event.location.horizontalAccuracy == -1)
    }

    @Test("Returns nil if an alternate place fails to parse")
    func rejectsInvalidAlternatePlace() {
        var object = baseEventObject()
        object["alternatePlaces"] = [placeObject(id: "alt-1"), "not-a-place"]
        #expect(RadarEvent(object: object) == nil)
    }

    @Test("Maps every known type string and round-trips it")
    func parsesKnownTypes() throws {
        let types: [RadarEventType] = [
            .userEnteredGeofence, .userExitedGeofence, .userDwelledInGeofence, .userEnteredPlace,
            .userExitedPlace, .userEnteredRegionCountry, .userExitedRegionCountry, .userEnteredRegionDMA,
            .userExitedRegionDMA, .userEnteredRegionState, .userExitedRegionState,
            .userEnteredRegionPostalCode, .userExitedRegionPostalCode, .userNearbyPlaceChain,
            .userEnteredBeacon, .userExitedBeacon, .userStartedTrip, .userUpdatedTrip, .userStoppedTrip,
            .userApproachingTripDestination, .userArrivedAtTripDestination,
            .userArrivedAtWrongTripDestination, .userFailedFraud, .userFiredTripOrders, .userEnteredHome,
            .userExitedHome, .userEnteredWork, .userExitedWork, .userStartedTraveling,
            .userStoppedTraveling, .userStartedCommuting, .userStoppedCommuting,
        ]
        for type in types {
            let string = try #require(RadarEvent.string(for: type))
            #expect(string.hasPrefix("user."))
            var object = baseEventObject()
            object["type"] = string
            let event = try parse(object)
            #expect(event.type == type)
            #expect(event.conversionName == nil)
        }
        #expect(RadarEvent.string(for: .conversion) == "custom")
        #expect(RadarEvent.string(for: .unknown) == "unknown")
    }

    @Test("Treats an unrecognized type string as a conversion")
    func parsesConversion() throws {
        var object = baseEventObject()
        object["type"] = "purchase_completed"
        let event = try parse(object)
        #expect(event.type == .conversion)
        #expect(event.conversionName == "purchase_completed")
        #expect(event.dictionaryValue()["type"] as? String == "custom")
    }

    @Test("Parses verification and confidence values")
    func parsesVerificationAndConfidence() throws {
        let verifications: [(Int, RadarEventVerification)] = [(1, .accept), (0, .unverify), (-1, .reject), (5, .unverify)]
        for (value, expected) in verifications {
            var object = baseEventObject()
            object["verification"] = value
            #expect(try parse(object).verification == expected)
        }

        let confidences: [(Int, RadarEventConfidence)] = [(3, .high), (2, .medium), (1, .low), (0, .none), (7, .none)]
        for (value, expected) in confidences {
            var object = baseEventObject()
            object["confidence"] = value
            #expect(try parse(object).confidence == expected)
        }
    }

    @Test("Parses metadata from a dictionary or a JSON object string")
    func parsesMetadata() throws {
        var object = baseEventObject()
        object["metadata"] = "{\"campaign\":\"spring\"}"
        #expect(try parse(object).metadata["campaign"] as? String == "spring")

        object["metadata"] = "[1, 2]"
        #expect(try parse(object).metadata.isEmpty)

        object["metadata"] = "not json"
        #expect(try parse(object).metadata.isEmpty)

        object["metadata"] = 42
        #expect(try parse(object).metadata.isEmpty)
    }

    @Test("Serializes every field")
    func serializesEveryField() throws {
        let dict = try parse(fullEventObject()).dictionaryValue()

        #expect(dict["_id"] as? String == "event-id")
        #expect(dict["live"] as? Bool == true)
        #expect(dict["type"] as? String == "user.entered_place")
        #expect((dict["geofence"] as? [AnyHashable: Any])?["_id"] as? String == "geofence-id")
        #expect((dict["place"] as? [AnyHashable: Any])?["_id"] as? String == "place-id")
        #expect(dict["confidence"] as? Int == 3)
        #expect(dict["duration"] as? Float == 12.5)
        #expect((dict["region"] as? [AnyHashable: Any])?["_id"] as? String == "us")
        #expect((dict["beacon"] as? [AnyHashable: Any])?["_id"] as? String == "beacon-id")
        #expect((dict["trip"] as? [AnyHashable: Any])?["_id"] as? String == "trip-id")
        #expect(dict["fraud"] is [AnyHashable: Any])
        #expect((dict["alternatePlaces"] as? [[AnyHashable: Any]])?.count == 2)
        let location = try #require(dict["location"] as? [String: Any])
        #expect(location["type"] as? String == "Point")
        #expect(location["coordinates"] as? [Double] == [-73.9906, 40.7356])
        #expect(dict["replayed"] as? Bool == true)
        #expect((dict["metadata"] as? [AnyHashable: Any])?["campaign"] as? String == "spring")
        // `RadarUtils.isoDateFormatter` writes the UTC offset as `+0000`.
        #expect(dict["createdAt"] as? String == "2026-07-20T12:00:00.000+0000")
        #expect(dict["actualCreatedAt"] as? String == "2026-07-20T12:00:05.000+0000")
    }

    @Test("Omits keys the Objective-C serializer omitted")
    func serializationOmitsMissingFields() throws {
        let dict = try parse(baseEventObject()).dictionaryValue()

        for key in [
            "geofence", "place", "duration", "region", "beacon", "trip", "fraud", "alternatePlaces", "metadata",
        ] {
            #expect(dict[key] == nil, "\(key) should be omitted")
        }
        #expect(dict["type"] as? String == "unknown")
        #expect(dict["confidence"] as? Int == 0)
        let location = try #require(dict["location"] as? [String: Any])
        #expect(location["coordinates"] as? [Double] == [-73.9, 40.7])
    }

    @Test("A serialized event parses back to the same values")
    func roundTrips() throws {
        let original = try parse(fullEventObject())
        let reparsed = try parse(try #require(original.dictionaryValue() as? [String: Any]))

        #expect(reparsed._id == original._id)
        #expect(reparsed.createdAt == original.createdAt)
        #expect(reparsed.actualCreatedAt == original.actualCreatedAt)
        #expect(reparsed.type == original.type)
        #expect(reparsed.confidence == original.confidence)
        #expect(reparsed.duration == original.duration)
        #expect(reparsed.location.coordinate.latitude == original.location.coordinate.latitude)
        #expect(reparsed.location.coordinate.longitude == original.location.coordinate.longitude)
        #expect(reparsed.alternatePlaces?.count == 2)
    }

}

// The Objective-C entry points and runtime surface that SDK code and apps call.
@Suite("RadarEventCompatibilityTests")
struct RadarEventCompatibilityTests {

    private func parse(_ object: [String: Any]) throws -> RadarEvent {
        try #require(RadarEvent(object: object))
    }

    @Test("eventsFromObject parses arrays and drops events that fail to parse")
    func parsesEventArrays() throws {
        let events = try #require(RadarEvent.events(from: [baseEventObject(), fullEventObject()]))
        #expect(events.count == 2)

        var noLocation = fullEventObject()
        noLocation["_id"] = "no-location"
        noLocation["location"] = nil
        let kept = try #require(RadarEvent.events(from: [baseEventObject(), noLocation, "not an event"]))
        #expect(kept.map(\._id) == ["event-id"])
        #expect(RadarEvent.events(from: baseEventObject()) == nil)
        #expect(RadarEvent.events(from: nil) == nil)
        #expect(RadarEvent.events(from: [Any]())?.isEmpty == true)
    }

    @Test("arrayForEvents serializes each event and passes nil through")
    func serializesEventArrays() throws {
        let events = [try parse(baseEventObject()), try parse(fullEventObject())]
        let array = try #require(RadarEvent.array(for: events))
        #expect(array.map { $0["_id"] as? String } == ["event-id", "event-id"])
        #expect(RadarEvent.array(for: nil) == nil)
    }

    @Test("The public init builds an empty event")
    func publicInit() {
        let event = RadarEvent()
        #expect(event._id.isEmpty)
        #expect(event.type == .unknown)
        #expect(event.metadata.isEmpty)
        #expect(event.alternatePlaces == nil)
    }

    @Test("Keeps the Objective-C runtime name and selectors")
    func objectiveCSurface() throws {
        #expect(NSStringFromClass(RadarEvent.self) == "RadarEvent")
        let cls: AnyClass = RadarEvent.self
        for selector in [
            "_id", "createdAt", "actualCreatedAt", "live", "type", "conversionName", "geofence", "place",
            "region", "beacon", "trip", "fraud", "alternatePlaces", "verifiedPlace", "verification",
            "confidence", "duration", "location", "replayed", "metadata", "dictionaryValue", "initWithObject:",
        ] {
            #expect(class_getInstanceMethod(cls, NSSelectorFromString(selector)) != nil, "missing -\(selector)")
        }
        for selector in ["stringForType:", "arrayForEvents:", "eventsFromObject:"] {
            #expect(class_getClassMethod(cls, NSSelectorFromString(selector)) != nil, "missing +\(selector)")
        }

        // Objective-C callers go through `-initWithObject:`, which still returns nil on bad input.
        let event = try #require(RadarEvent(object: NSDictionary(dictionary: baseEventObject())))
        #expect(event.responds(to: NSSelectorFromString("dictionaryValue")))
    }
}
