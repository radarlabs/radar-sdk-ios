//
//  RadarContextTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

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
        "allowed": true,
    ]
}

private func contextObject() -> [String: Any] {
    [
        "geofences": [geofenceObject(id: "geofence-1"), geofenceObject(id: "geofence-2")],
        "place": placeObject(),
        "country": regionObject(id: "us", type: "country"),
        "state": regionObject(id: "ny", type: "state"),
        "dma": regionObject(id: "501", type: "dma"),
        "postalCode": regionObject(id: "10003", type: "postalCode"),
    ]
}

@Suite("RadarContext")
struct RadarContextTests {

    @Test
    func nonDictionaryReturnsNil() {
        #expect(RadarContext(object: "not a context") == nil)
        #expect(RadarContext(object: ["geofences"]) == nil)
    }

    @Test
    func emptyObjectHasNoGeofencesAndNoRegions() throws {
        let context = try #require(RadarContext(object: [String: Any]()))

        #expect(context.geofences.isEmpty)
        #expect(context.place == nil)
        #expect(context.country == nil)
        #expect(context.state == nil)
        #expect(context.dma == nil)
        #expect(context.postalCode == nil)
        #expect(context.dictionaryValue().count == 1)
        #expect((context.dictionaryValue()["geofences"] as? [Any])?.isEmpty == true)
    }

    @Test
    func memberwiseInitializerKeepsValues() {
        let country = RadarRegion(object: regionObject(id: "us", type: "country"))
        let context = RadarContext(geofences: [], place: nil, country: country, state: nil, dma: nil, postalCode: nil)

        #expect(context.country === country)
        #expect(context.geofences.isEmpty)
        #expect(context.dictionaryValue().keys.count == 2)
        #expect((context.dictionaryValue()["country"] as? [String: Any])?["code"] as? String == "US")
    }

    @Test
    func objectiveCRuntimeName() {
        #expect(NSStringFromClass(RadarContext.self) == "RadarContext")
        #expect(RadarContext().geofences.isEmpty)
    }
}

// Geofence, place, and region parsing goes through `RadarSwift.bridge`, so these tests swap the global bridge.
extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarContextParsingTests {

        private func withBridge<T>(_ bridge: RadarSwiftBridgeProtocol?, _ body: () throws -> T) rethrows -> T {
            let original = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer { RadarSwift.bridge = original }
            return try body()
        }

        private func modelBridge() -> MockRadarSwiftBridge {
            let bridge = MockRadarSwiftBridge()
            bridge.createGeofenceHandler = { RadarGeofence(object: $0) }
            bridge.createPlaceHandler = { RadarPlace(object: $0) }
            bridge.createRegionHandler = { RadarRegion(object: $0) }
            return bridge
        }

        @Test
        func parsesEveryField() throws {
            let context = try #require(withBridge(modelBridge()) { RadarContext(object: contextObject()) })

            #expect(context.geofences.map(\._id) == ["geofence-1", "geofence-2"])
            #expect(context.place?._id == "place-id")
            #expect(context.place?.name == "Place")
            #expect(context.country?.code == "US")
            #expect(context.state?.code == "NY")
            #expect(context.dma?.code == "501")
            #expect(context.postalCode?.code == "10003")
            #expect(context.postalCode?.type == "postalCode")
        }

        @Test
        func dictionaryValueRoundTrips() throws {
            let context = try #require(withBridge(modelBridge()) { RadarContext(object: contextObject()) })
            let dict = context.dictionaryValue()

            #expect(Set(dict.keys.compactMap { $0 as? String }) == ["geofences", "place", "country", "state", "dma", "postalCode"])
            let geofences = try #require(dict["geofences"] as? [[String: Any]])
            #expect(geofences.map { $0["_id"] as? String } == ["geofence-1", "geofence-2"])
            #expect((dict["place"] as? [String: Any])?["_id"] as? String == "place-id")
            #expect((dict["country"] as? [String: Any])?["code"] as? String == "US")
            #expect((dict["dma"] as? [String: Any])?["type"] as? String == "dma")

            let reparsed = try #require(withBridge(modelBridge()) { RadarContext(object: dict) })
            #expect(reparsed.geofences.map(\._id) == context.geofences.map(\._id))
            #expect(reparsed.place?._id == context.place?._id)
            #expect(reparsed.postalCode?.code == context.postalCode?.code)
        }

        @Test
        func anyUnparseableGeofenceReturnsNil() {
            var object = contextObject()
            object["geofences"] = [geofenceObject(id: "geofence-1"), "not a geofence"]

            #expect(withBridge(modelBridge()) { RadarContext(object: object) } == nil)
        }

        @Test
        func geofenceRejectedByTheBridgeReturnsNil() {
            #expect(withBridge(MockRadarSwiftBridge()) { RadarContext(object: contextObject()) } == nil)
        }

        @Test
        func nonArrayGeofencesAreIgnored() throws {
            var object = contextObject()
            object["geofences"] = "not an array"

            let context = try #require(withBridge(modelBridge()) { RadarContext(object: object) })
            #expect(context.geofences.isEmpty)
            #expect(context.country?.code == "US")
        }

        @Test
        func malformedPlaceAndRegionsBecomeNil() throws {
            var object = contextObject()
            object["place"] = ["name": "Missing ID"]
            object["country"] = "US"
            object["state"] = NSNull()
            object["dma"] = nil

            let context = try #require(withBridge(modelBridge()) { RadarContext(object: object) })
            #expect(context.geofences.count == 2)
            #expect(context.place == nil)
            #expect(context.country == nil)
            #expect(context.state == nil)
            #expect(context.dma == nil)
            #expect(context.postalCode?.code == "10003")

            let dict = context.dictionaryValue()
            #expect(dict["place"] == nil)
            #expect(dict["country"] == nil)
            #expect(dict["postalCode"] != nil)
        }
    }
}
