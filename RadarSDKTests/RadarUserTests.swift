//
//  RadarUserTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

private func geofenceObject(id: String) -> [String: Any] {
    [
        "_id": id,
        "description": "Geofence \(id)",
        "tag": "store",
        "externalId": "external-\(id)",
        "type": "circle",
        "geometryRadius": 100,
        "geometryCenter": ["type": "Point", "coordinates": [-73.9, 40.7]],
    ]
}

private func beaconObject(id: String) -> [String: Any] {
    [
        "_id": id,
        "description": "Beacon \(id)",
        "tag": "store",
        "externalId": "external-\(id)",
        "uuid": "b9407f30-f5f8-466e-aff9-25556b57fe6d",
        "major": "100",
        "minor": "1",
        "geometry": ["type": "Point", "coordinates": [-73.9, 40.7]],
    ]
}

private func placeObject() -> [String: Any] {
    [
        "_id": "place-id",
        "name": "Place",
        "categories": ["food-beverage"],
        "location": ["type": "Point", "coordinates": [-73.9, 40.7]],
    ]
}

private func regionObject(id: String, type: String) -> [String: Any] {
    [
        "_id": id,
        "name": "Region \(id)",
        "code": id.uppercased(),
        "type": type,
    ]
}

private func baseUserObject() -> [String: Any] {
    [
        "_id": "user-id",
        "location": ["type": "Point", "coordinates": [-73.9906, 40.7356]],
    ]
}

private func fullUserObject() -> [String: Any] {
    var object = baseUserObject()
    object["userId"] = "customer-user-id"
    object["deviceId"] = "device-id"
    object["description"] = "Test user"
    object["metadata"] = ["tier": "gold"]
    object["location"] = ["type": "Point", "coordinates": [-73.9906, 40.7356, 12.5]]
    object["locationAccuracy"] = 8
    object["activityType"] = "car"
    object["geofences"] = [geofenceObject(id: "geofence-1"), geofenceObject(id: "geofence-2")]
    object["place"] = placeObject()
    object["beacons"] = [beaconObject(id: "beacon-1")]
    object["stopped"] = true
    object["foreground"] = true
    object["country"] = regionObject(id: "us", type: "country")
    object["state"] = regionObject(id: "ny", type: "state")
    object["dma"] = regionObject(id: "501", type: "dma")
    object["postalCode"] = regionObject(id: "10003", type: "postalCode")
    object["nearbyPlaceChains"] = [["slug": "chain", "name": "Chain"], "not-a-chain"]
    object["segments"] = [["description": "Segment", "externalId": "segment-1"], "not-a-segment"]
    object["topChains"] = [["slug": "top", "name": "Top"]]
    object["source"] = "GEOFENCE_ENTER"
    object["trip"] = ["_id": "trip-id", "externalId": "trip-external-id", "status": "started"]
    object["debug"] = true
    object["fraud"] = ["passed": true, "proxy": false]
    object["locationInsights"] = ["atHome": true, "atWork": false, "traveling": true]
    object["altitude"] = 42.5
    object["expectedAddress"] = ["expectedAddress": "111 5th Ave, NY", "atAddress": true, "confidence": "high"]
    return object
}

// Geofences, beacons, places, and segments are built by `RadarSwift.modelFactory`, not
// `RadarSwift.bridge`. These tests clear the global bridge, as before `Radar.initialize`, to check
// that parsing doesn't depend on it.
extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarUserTests {

        private func withoutBridge<T>(_ body: () throws -> T) rethrows -> T {
            let original = RadarSwift.bridge
            RadarSwift.bridge = nil
            defer { RadarSwift.bridge = original }
            return try body()
        }

        @Test("Parses every field")
        func parsesEveryField() throws {
            let user = try withoutBridge { try #require(RadarUser(object: fullUserObject())) }

            #expect(user._id == "user-id")
            #expect(user.userId == "customer-user-id")
            #expect(user.deviceId == "device-id")
            #expect(user.__description == "Test user")
            #expect(user.metadata?["tier"] as? String == "gold")
            #expect(user.location.coordinate.latitude == 40.7356)
            #expect(user.location.coordinate.longitude == -73.9906)
            #expect(user.location.altitude == 12.5)
            #expect(user.location.horizontalAccuracy == 8)
            #expect(user.location.verticalAccuracy == -1)
            #expect(user.activityType == .car)
            #expect(user.geofences?.map(\._id) == ["geofence-1", "geofence-2"])
            #expect(user.place?._id == "place-id")
            #expect(user.beacons?.map(\._id) == ["beacon-1"])
            #expect(user.stopped)
            #expect(user.foreground)
            #expect(user.country?.code == "US")
            #expect(user.state?.code == "NY")
            #expect(user.dma?.code == "501")
            #expect(user.postalCode?.code == "10003")
            #expect(user.nearbyPlaceChains?.map(\.slug) == ["chain"])
            #expect(user.segments?.map(\.externalId) == ["segment-1"])
            #expect(user.topChains?.map(\.slug) == ["top"])
            #expect(user.source == .geofenceEnter)
            #expect(user.trip?.externalId == "trip-external-id")
            #expect(user.debug)
            #expect(user.fraud?.passed == true)
            #expect(user.locationInsights?.atHome == true)
            #expect(user.locationInsights?.commuting == nil)
            #expect(user.altitude == 42.5)
            #expect(user.expectedAddress?.expectedAddress == "111 5th Ave, NY")
        }

        @Test("Defaults optional fields when only _id and location are present")
        func defaultsOptionalFields() throws {
            let user = try withoutBridge { try #require(RadarUser(object: baseUserObject())) }

            #expect(user.userId == nil)
            #expect(user.deviceId == nil)
            #expect(user.__description == nil)
            #expect(user.metadata == nil)
            #expect(user.location.altitude == -1)
            #expect(user.location.horizontalAccuracy == -1)
            #expect(user.activityType == .unknown)
            #expect(user.geofences == nil)
            #expect(user.place == nil)
            #expect(user.beacons == nil)
            #expect(!user.stopped)
            #expect(!user.foreground)
            #expect(user.country == nil)
            #expect(user.nearbyPlaceChains == nil)
            #expect(user.segments == nil)
            #expect(user.topChains == nil)
            #expect(user.source == .unknown)
            #expect(user.trip == nil)
            #expect(!user.debug)
            #expect(user.fraud == nil)
            #expect(user.locationInsights == nil)
            #expect(user.altitude.isNaN)
            #expect(user.expectedAddress == nil)
        }

        @Test("Returns nil without a valid _id or location")
        func rejectsMissingRequiredFields() {
            let objects: [[String: Any]] = [
                ["location": ["coordinates": [-73.9, 40.7]]],
                ["_id": 1, "location": ["coordinates": [-73.9, 40.7]]],
                ["_id": "user-id"],
                ["_id": "user-id", "location": "40.7,-73.9"],
                ["_id": "user-id", "location": ["coordinates": [-73.9]]],
                ["_id": "user-id", "location": ["coordinates": [-73.9, 40.7, 1, 2]]],
                ["_id": "user-id", "location": ["coordinates": ["-73.9", 40.7]]],
                ["_id": "user-id", "location": ["type": "Point"]],
            ]
            for object in objects {
                #expect(RadarUser(object: object) == nil, "\(object)")
            }
        }

        @Test("Ignores wrongly typed optional fields")
        func ignoresWronglyTypedFields() throws {
            var object = baseUserObject()
            object["userId"] = 7
            object["metadata"] = "metadata"
            object["location"] = ["coordinates": [-73.9, 40.7, "high"]]
            object["locationAccuracy"] = "8"
            object["activityType"] = "teleport"
            object["stopped"] = "yes"
            object["place"] = "place"
            object["source"] = "BEACON_ENTER"
            object["altitude"] = "high"
            object["barometricAltitude"] = 3.25
            object["nearbyPlaceChains"] = "chains"

            let user = try withoutBridge { try #require(RadarUser(object: object)) }

            #expect(user.userId == nil)
            #expect(user.metadata == nil)
            #expect(user.location.altitude == -1)
            #expect(user.location.horizontalAccuracy == -1)
            #expect(user.activityType == .unknown)
            #expect(!user.stopped)
            #expect(user.place == nil)
            // The Objective-C parser only recognized eight sources.
            #expect(user.source == .unknown)
            // A non-numeric altitude falls back to barometricAltitude.
            #expect(user.altitude == 3.25)
            #expect(user.nearbyPlaceChains == nil)
        }

        @Test("Prefers altitude over barometricAltitude")
        func prefersAltitude() throws {
            var object = baseUserObject()
            object["barometricAltitude"] = 3.25
            object["altitude"] = 9.5

            let user = try #require(RadarUser(object: object))

            #expect(user.altitude == 9.5)
        }

        @Test("Drops all geofences or beacons when any element fails to parse")
        func dropsInvalidArrays() throws {
            var object = baseUserObject()
            object["geofences"] = [geofenceObject(id: "geofence-1"), "not-a-geofence"]
            object["beacons"] = [beaconObject(id: "beacon-1"), "not-a-beacon"]

            let user = try withoutBridge { try #require(RadarUser(object: object)) }

            #expect(user.geofences == nil)
            #expect(user.beacons == nil)
        }

        @Test("Keeps empty geofence and beacon arrays")
        func keepsEmptyArrays() throws {
            var object = baseUserObject()
            object["geofences"] = [] as [Any]
            object["beacons"] = [] as [Any]

            let user = try withoutBridge { try #require(RadarUser(object: object)) }

            #expect(user.geofences?.isEmpty == true)
            #expect(user.beacons?.isEmpty == true)
        }

        @Test("Serializes every field")
        func serializesEveryField() throws {
            let user = try withoutBridge { try #require(RadarUser(object: fullUserObject())) }
            let dict = user.dictionaryValue()

            #expect(dict["_id"] as? String == "user-id")
            #expect(dict["userId"] as? String == "customer-user-id")
            #expect(dict["deviceId"] as? String == "device-id")
            #expect(dict["description"] as? String == "Test user")
            #expect((dict["metadata"] as? [AnyHashable: Any])?["tier"] as? String == "gold")
            let location = try #require(dict["location"] as? [String: Any])
            #expect(location["type"] as? String == "Point")
            #expect(
                location["coordinates"] as? [Double]
                    == [user.location.coordinate.longitude, user.location.coordinate.latitude])
            #expect(dict["activityType"] as? String == "car")
            #expect((dict["geofences"] as? [[AnyHashable: Any]])?.count == 2)
            #expect((dict["place"] as? [AnyHashable: Any])?["_id"] as? String == "place-id")
            #expect((dict["beacons"] as? [[AnyHashable: Any]])?.count == 1)
            #expect(dict["stopped"] as? Bool == true)
            #expect(dict["foreground"] as? Bool == true)
            #expect((dict["country"] as? [AnyHashable: Any])?["code"] as? String == "US")
            #expect((dict["state"] as? [AnyHashable: Any])?["code"] as? String == "NY")
            #expect((dict["dma"] as? [AnyHashable: Any])?["code"] as? String == "501")
            #expect((dict["postalCode"] as? [AnyHashable: Any])?["code"] as? String == "10003")
            #expect((dict["nearbyPlaceChains"] as? [[AnyHashable: Any]])?.first?["slug"] as? String == "chain")
            #expect((dict["segments"] as? [[AnyHashable: Any]])?.first?["externalId"] as? String == "segment-1")
            #expect((dict["topChains"] as? [[AnyHashable: Any]])?.first?["slug"] as? String == "top")
            #expect(dict["source"] as? String == "GEOFENCE_ENTER")
            #expect((dict["trip"] as? [AnyHashable: Any])?["externalId"] as? String == "trip-external-id")
            #expect(dict["debug"] as? Bool == true)
            #expect((dict["fraud"] as? [AnyHashable: Any])?["passed"] as? Bool == true)
            #expect((dict["locationInsights"] as? [AnyHashable: Any])?["atHome"] as? Bool == true)
            #expect(dict["altitude"] as? Double == 42.5)
            #expect((dict["expectedAddress"] as? [AnyHashable: Any])?["confidence"] as? String == "high")
        }

        @Test("Omits absent optional fields when serializing")
        func serializesMinimalUser() throws {
            let user = try #require(RadarUser(object: baseUserObject()))
            let dict = user.dictionaryValue()

            #expect(dict["_id"] as? String == "user-id")
            #expect(dict["location"] != nil)
            #expect(dict["activityType"] as? String == "unknown")
            #expect(dict["source"] as? String == "UNKNOWN")
            #expect(dict["stopped"] as? Bool == false)
            #expect(dict["foreground"] as? Bool == false)
            #expect(dict["debug"] as? Bool == false)
            for key in [
                "userId", "deviceId", "description", "metadata", "geofences", "place", "beacons", "country",
                "state", "dma", "postalCode", "nearbyPlaceChains", "segments", "topChains", "trip", "fraud",
                "locationInsights", "altitude", "expectedAddress",
            ] {
                #expect(dict[key] == nil, "\(key) should be omitted")
            }
        }

        @Test("Round-trips through dictionaryValue")
        func roundTrips() throws {
            try withoutBridge {
                let user = try #require(RadarUser(object: fullUserObject()))
                let reparsed = try #require(RadarUser(object: user.dictionaryValue()))

                #expect(reparsed._id == user._id)
                #expect(reparsed.userId == user.userId)
                #expect(reparsed.location.coordinate.latitude == user.location.coordinate.latitude)
                #expect(reparsed.activityType == user.activityType)
                #expect(reparsed.geofences?.map(\._id) == user.geofences?.map(\._id))
                #expect(reparsed.beacons?.map(\._id) == user.beacons?.map(\._id))
                #expect(reparsed.place?._id == user.place?._id)
                #expect(reparsed.segments?.map(\.externalId) == user.segments?.map(\.externalId))
                #expect(reparsed.source == user.source)
                #expect(reparsed.altitude == user.altitude)
            }
        }

        @Test("Installs the model factory when the framework loads")
        func installsModelFactory() {
            #expect(RadarSwift.modelFactory != nil)
        }
    }
}
