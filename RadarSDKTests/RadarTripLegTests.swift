//
//  RadarTripLegTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

// swiftlint:disable file_length

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTripLegTests")
struct RadarTripLegTests { // swiftlint:disable:this type_body_length

    // MARK: - Default State

    @Test("initializes with default values")
    func initializesWithDefaults() {
        let leg = RadarTripLeg()

        #expect(leg._id == nil)
        #expect(leg.destinationGeofenceTag == nil)
        #expect(leg.destinationGeofenceExternalId == nil)
        #expect(leg.destinationGeofenceId == nil)
        #expect(leg.address == nil)
        #expect(leg.metadata == nil)
        #expect(leg.createdAt == nil)
        #expect(leg.updatedAt == nil)
        #expect(leg.hasCoordinates == false)
        #expect(leg.status == .unknown)
        #expect(leg.destinationType == .unknown)
        #expect(leg.etaDuration == 0)
        #expect(leg.etaDistance == 0)
        #expect(leg.stopDuration == 0)
        #expect(leg.arrivalRadius == 0)
    }

    // MARK: - Initializers

    @Test("initializes with a geofence tag and external ID")
    func initializesWithGeofenceTagAndExternalId() {
        let leg = RadarTripLeg(
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )

        #expect(leg.destinationGeofenceTag == "store")
        #expect(leg.destinationGeofenceExternalId == "store-1")
        #expect(leg.destinationGeofenceId == nil)
        #expect(leg.hasCoordinates == false)
        #expect(leg.status == .unknown)
        #expect(leg.destinationType == .geofence)
    }

    @Test("initializes with a geofence ID")
    func initializesWithGeofenceId() {
        let leg = RadarTripLeg(
            destinationGeofenceId: "geofence_abc"
        )

        #expect(leg.destinationGeofenceId == "geofence_abc")
        #expect(leg.destinationGeofenceTag == nil)
        #expect(leg.destinationGeofenceExternalId == nil)
        #expect(leg.hasCoordinates == false)
        #expect(leg.destinationType == .geofence)
    }

    @Test("initializes with an address")
    func initializesWithAddress() {
        let leg = RadarTripLeg(
            address: "123 Main St, New York, NY"
        )

        #expect(leg.address == "123 Main St, New York, NY")
        #expect(leg.destinationGeofenceTag == nil)
        #expect(leg.hasCoordinates == false)
        #expect(leg.destinationType == .address)
    }

    @Test("initializes with coordinates")
    func initializesWithCoordinates() {
        let coordinates = CLLocationCoordinate2D(
            latitude: 40.783825,
            longitude: -73.975365
        )
        let leg = RadarTripLeg(coordinates: coordinates)

        #expect(leg.hasCoordinates)
        #expect(leg.coordinates.latitude == 40.783825)
        #expect(leg.coordinates.longitude == -73.975365)
        #expect(leg.arrivalRadius == 0)
        #expect(leg.destinationType == .coordinates)
    }

    @Test("allows an arrival radius to be set after initialization")
    func setsArrivalRadius() {
        let coordinates = CLLocationCoordinate2D(
            latitude: 40.783825,
            longitude: -73.975365
        )
        let leg = RadarTripLeg(coordinates: coordinates)

        leg.arrivalRadius = 150

        #expect(leg.hasCoordinates)
        #expect(leg.coordinates.latitude == 40.783825)
        #expect(leg.coordinates.longitude == -73.975365)
        #expect(leg.arrivalRadius == 150)
    }

    // MARK: - Destination Type

    @Test("geofence tag initializer sets the destination type")
    func geofenceTagDestinationType() {
        let leg = RadarTripLeg(
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )

        #expect(leg.destinationType == .geofence)
    }

    @Test("geofence ID initializer sets the destination type")
    func geofenceIdDestinationType() {
        let leg = RadarTripLeg(destinationGeofenceId: "geofence_abc")

        #expect(leg.destinationType == .geofence)
    }

    @Test("address initializer sets the destination type")
    func addressDestinationType() {
        let leg = RadarTripLeg(address: "123 Main St")

        #expect(leg.destinationType == .address)
    }

    @Test("coordinate initializer sets the destination type")
    func coordinateDestinationType() {
        let leg = RadarTripLeg(
            coordinates: CLLocationCoordinate2D(
                latitude: 40,
                longitude: -74
            )
        )

        #expect(leg.destinationType == .coordinates)
    }

    @Test("default initializer has an unknown destination type")
    func unknownDestinationType() {
        let leg = RadarTripLeg()

        #expect(leg.destinationType == .unknown)
    }

    @Test("geofence destination type remains when other fields are set")
    func geofenceDestinationTypeTakesPriority() {
        let leg = RadarTripLeg(
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )

        leg.address = "123 Main St"
        leg.coordinates = CLLocationCoordinate2D(
            latitude: 40,
            longitude: -74
        )

        #expect(leg.destinationType == .geofence)
    }

    @Test("address destination type remains when coordinates are set")
    func addressDestinationTypeTakesPriority() {
        let leg = RadarTripLeg(address: "123 Main St")

        leg.coordinates = CLLocationCoordinate2D(
            latitude: 40,
            longitude: -74
        )

        #expect(leg.destinationType == .address)
    }

    // MARK: - Destination Type From Server Response

    @Test("parses a geofence destination type from a server response")
    func parsesGeofenceDestinationType() throws {
        let leg = try #require(
            RadarTripLeg(
                from: [
                    "destination": [
                        "type": "geofence",
                        "source": [
                            "geofence": "geofence_001",
                            "data": [
                                "tag": "store",
                                "externalId": "store-1",
                            ],
                        ],
                        "address": "123 Main St",
                        "location": [
                            "coordinates": [-74.0, 40.0]
                        ],
                    ]
                ]
            )
        )

        #expect(leg.destinationType == .geofence)
    }

    @Test("parses an address destination type from a server response")
    func parsesAddressDestinationType() throws {
        let leg = try #require(
            RadarTripLeg(
                from: [
                    "destination": [
                        "type": "address",
                        "source": [
                            "data": "456 Oak Ave"
                        ],
                        "location": [
                            "coordinates": [-74.0, 40.0]
                        ],
                        "arrivalRadius": 25,
                    ]
                ]
            )
        )

        #expect(leg.destinationType == .address)
        #expect(leg.address == "456 Oak Ave")
        #expect(leg.hasCoordinates)
        #expect(leg.arrivalRadius == 25)
    }

    @Test("parses a coordinate destination type from a server response")
    func parsesCoordinateDestinationType() throws {
        let leg = try #require(
            RadarTripLeg(
                from: [
                    "destination": [
                        "type": "coordinates",
                        "location": [
                            "coordinates": [-74.0, 40.0]
                        ],
                        "arrivalRadius": 100,
                    ]
                ]
            )
        )

        #expect(leg.destinationType == .coordinates)
    }

    // MARK: - Destination Type String Conversion

    @Test("serializes every destination type")
    func serializesDestinationTypes() {
        let cases: [(RadarTripLegDestinationType, String)] = [
            (.unknown, "unknown"),
            (.geofence, "geofence"),
            (.address, "address"),
            (.coordinates, "coordinates"),
        ]

        for (destinationType, expected) in cases {
            #expect(
                RadarTripLeg.string(for: destinationType) == expected
            )
        }
    }

    @Test("parses recognized and unknown destination types")
    func parsesDestinationTypes() {
        let cases: [(String, RadarTripLegDestinationType)] = [
            ("geofence", .geofence),
            ("address", .address),
            ("coordinates", .coordinates),
            ("unknown", .unknown),
            ("invalid_garbage", .unknown),
            ("", .unknown),
        ]

        for (value, expected) in cases {
            #expect(
                RadarTripLeg.destinationType(for: value) == expected
            )
        }
    }

    // MARK: - Status String Conversion

    @Test("serializes every trip leg status")
    func serializesStatuses() {
        let cases: [(RadarTripLegStatus, String)] = [
            (.unknown, "unknown"),
            (.pending, "pending"),
            (.started, "started"),
            (.approaching, "approaching"),
            (.arrived, "arrived"),
            (.completed, "completed"),
            (.canceled, "canceled"),
            (.expired, "expired"),
        ]

        for (status, expected) in cases {
            #expect(RadarTripLeg.string(for: status) == expected)
        }
    }

    @Test("parses recognized and unknown trip leg statuses")
    func parsesStatuses() {
        let cases: [(String, RadarTripLegStatus)] = [
            ("pending", .pending),
            ("started", .started),
            ("approaching", .approaching),
            ("arrived", .arrived),
            ("completed", .completed),
            ("canceled", .canceled),
            ("expired", .expired),
            ("unknown", .unknown),
            ("invalid_garbage", .unknown),
            ("", .unknown),
        ]

        for (value, expected) in cases {
            #expect(RadarTripLeg.status(for: value) == expected)
        }
    }

    // MARK: - Request-Format Parsing

    @Test("parses a geofence tag and external ID request")
    func parsesGeofenceTagRequest() throws {
        let leg = try #require(
            RadarTripLeg(
                from: [
                    "destination": [
                        "destinationGeofenceTag": "store",
                        "destinationGeofenceExternalId": "store-1",
                    ],
                    "stopDuration": 10,
                    "metadata": [
                        "package": "small"
                    ],
                ]
            )
        )

        #expect(leg.destinationGeofenceTag == "store")
        #expect(leg.destinationGeofenceExternalId == "store-1")
        #expect(leg.destinationType == .geofence)
        #expect(leg.stopDuration == 10)
        #expect(leg.metadata?["package"] as? String == "small")
    }

    @Test("parses a geofence ID request")
    func parsesGeofenceIdRequest() throws {
        let leg = try #require(
            RadarTripLeg(
                from: [
                    "destination": [
                        "destinationGeofenceId": "geofence_abc"
                    ]
                ]
            )
        )

        #expect(leg.destinationGeofenceId == "geofence_abc")
        #expect(leg.destinationType == .geofence)
    }

    @Test("parses a coordinate request")
    func parsesCoordinateRequest() throws {
        let leg = try #require(
            RadarTripLeg(
                from: [
                    "destination": [
                        "coordinates": [-73.975365, 40.783825],
                        "arrivalRadius": 200,
                    ]
                ]
            )
        )

        #expect(leg.hasCoordinates)
        #expect(leg.destinationType == .coordinates)
        #expect(
            abs(leg.coordinates.latitude - 40.783825) < 0.0001
        )
        #expect(
            abs(leg.coordinates.longitude - -73.975365) < 0.0001
        )
        #expect(leg.arrivalRadius == 200)
    }

    @Test("parses an address request")
    func parsesAddressRequest() throws {
        let leg = try #require(
            RadarTripLeg(
                from: [
                    "destination": [
                        "address": "456 Oak Ave"
                    ]
                ]
            )
        )

        #expect(leg.address == "456 Oak Ave")
        #expect(leg.destinationType == .address)
    }

    // MARK: - Invalid Input

    @Test("rejects a nil dictionary")
    func rejectsNilDictionary() {
        #expect(RadarTripLeg(from: nil) == nil)
    }

    @Test("rejects a non-dictionary through the Objective-C selector")
    func rejectsNonDictionary() {
        let result = RadarTripLeg.perform(
            NSSelectorFromString("legFromDictionary:"),
            with: "not a dictionary"
        )

        #expect(result == nil)
    }

    // MARK: - Response-Format Parsing

    @Test("parses a complete geofence response")
    func parsesGeofenceResponse() throws {
        let leg = try #require(
            RadarTripLeg(
                from: RadarTripTestFixtures.leg(
                    id: "leg_001",
                    status: "started",
                    tag: "store",
                    externalId: "store-1"
                )
            )
        )

        #expect(leg._id == "leg_001")
        #expect(leg.status == .started)
        #expect(leg.destinationType == .geofence)
        #expect(leg.createdAt != nil)
        #expect(leg.updatedAt != nil)
        #expect(leg.etaDuration == 5)
        #expect(leg.etaDistance == 2_000)
        #expect(leg.destinationGeofenceId == "geofence_leg_001")
        #expect(leg.destinationGeofenceTag == "store")
        #expect(leg.destinationGeofenceExternalId == "store-1")
        #expect(leg.hasCoordinates)
        #expect(
            abs(leg.coordinates.latitude - 40.783825) < 0.0001
        )
        #expect(
            abs(leg.coordinates.longitude - -73.975365) < 0.0001
        )
        #expect(leg.stopDuration == 10)
        #expect(leg.metadata?["package"] as? String == "small")
    }

    @Test("parses a complete address response")
    func parsesAddressResponse() throws {
        let leg = try #require(
            RadarTripLeg(
                from: [
                    "_id": "leg_002",
                    "status": "pending",
                    "destination": [
                        "type": "address",
                        "source": [
                            "data": "401 Broadway, New York, NY"
                        ],
                        "location": [
                            "coordinates": [-73.9851, 40.7589]
                        ],
                        "arrivalRadius": 25,
                    ],
                ]
            )
        )

        #expect(leg._id == "leg_002")
        #expect(leg.status == .pending)
        #expect(leg.destinationType == .address)
        #expect(leg.address == "401 Broadway, New York, NY")
        #expect(leg.hasCoordinates)
        #expect(
            abs(leg.coordinates.latitude - 40.7589) < 0.0001
        )
        #expect(
            abs(leg.coordinates.longitude - -73.9851) < 0.0001
        )
        #expect(leg.arrivalRadius == 25)
    }

    @Test("parses a complete coordinate response")
    func parsesCoordinateResponse() throws {
        let leg = try #require(
            RadarTripLeg(
                from: [
                    "_id": "leg_003",
                    "status": "pending",
                    "destination": [
                        "type": "coordinates",
                        "source": [
                            "data": [40.7484, -73.9857]
                        ],
                        "location": [
                            "coordinates": [-73.9857, 40.7484]
                        ],
                        "arrivalRadius": 100,
                    ],
                ]
            )
        )

        #expect(leg._id == "leg_003")
        #expect(leg.status == .pending)
        #expect(leg.destinationType == .coordinates)
        #expect(leg.hasCoordinates)
        #expect(
            abs(leg.coordinates.latitude - 40.7484) < 0.0001
        )
        #expect(
            abs(leg.coordinates.longitude - -73.9857) < 0.0001
        )
        #expect(leg.arrivalRadius == 100)
    }

    // MARK: - Dictionary Serialization

    @Test("serializes a geofence leg")
    func serializesGeofenceLeg() throws {
        let leg = RadarTripLeg(
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )
        leg.stopDuration = 10
        leg.metadata = ["key": "value"]

        let dictionary = leg.dictionaryValue()
        let destination = try #require(
            dictionary["destination"] as? [String: Any]
        )

        #expect(
            destination["destinationGeofenceTag"] as? String == "store"
        )
        #expect(
            destination["destinationGeofenceExternalId"] as? String
                == "store-1"
        )
        #expect(dictionary["stopDuration"] as? Int == 10)
        #expect(
            (dictionary["metadata"] as? [String: String])?["key"]
                == "value"
        )
        #expect(dictionary["_id"] == nil)
        #expect(dictionary["status"] == nil)
    }

    @Test("serializes a coordinate leg")
    func serializesCoordinateLeg() throws {
        let leg = RadarTripLeg(
            coordinates: CLLocationCoordinate2D(
                latitude: 40.783825,
                longitude: -73.975365
            )
        )
        leg.arrivalRadius = 200

        let dictionary = leg.dictionaryValue()
        let destination = try #require(
            dictionary["destination"] as? [String: Any]
        )
        let coordinates = try #require(
            destination["coordinates"] as? [NSNumber]
        )

        #expect(coordinates.count == 2)
        #expect(coordinates[0].doubleValue == -73.975365)
        #expect(coordinates[1].doubleValue == 40.783825)
        #expect(destination["arrivalRadius"] as? Int == 200)
    }

    @Test("serializes response fields and ETA")
    func serializesResponseFields() throws {
        let leg = try #require(
            RadarTripLeg(
                from: RadarTripTestFixtures.leg(
                    id: "leg_001",
                    status: "arrived",
                    tag: "store",
                    externalId: "store-1"
                )
            )
        )

        let dictionary = leg.dictionaryValue()

        #expect(dictionary["_id"] as? String == "leg_001")
        #expect(dictionary["status"] as? String == "arrived")
        #expect(
            dictionary["createdAt"] as? String
                == "2026-02-24T12:00:00.000+0000"
        )
        #expect(
            dictionary["updatedAt"] as? String
                == "2026-02-24T12:05:00.000+0000"
        )

        let eta = try #require(
            dictionary["eta"] as? [String: Any]
        )

        #expect((eta["duration"] as? NSNumber)?.floatValue == 5)
        #expect((eta["distance"] as? NSNumber)?.floatValue == 2_000)
    }

    // MARK: - Collection Parsing

    @Test("parses an array of legs")
    func parsesLegArray() throws {
        let legs = try #require(
            RadarTripLeg.legs(
                from: [
                    [
                        "destination": [
                            "destinationGeofenceTag": "store",
                            "destinationGeofenceExternalId": "store-1",
                        ]
                    ],
                    [
                        "destination": [
                            "destinationGeofenceTag": "warehouse",
                            "destinationGeofenceExternalId": "warehouse-1",
                        ]
                    ],
                ]
            )
        )

        #expect(legs.count == 2)
        #expect(legs[0].destinationGeofenceTag == "store")
        #expect(legs[1].destinationGeofenceTag == "warehouse")
    }

    @Test("returns nil for nil and empty leg arrays")
    func rejectsNilAndEmptyLegArrays() {
        #expect(RadarTripLeg.legs(from: nil) == nil)
        #expect(RadarTripLeg.legs(from: []) == nil)
    }

    // MARK: - Collection Serialization

    @Test("serializes an array of legs")
    func serializesLegArray() throws {
        let first = RadarTripLeg(
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )
        let second = RadarTripLeg(address: "456 Oak Ave")

        let array = try #require(
            RadarTripLeg.array(for: [first, second])
        )

        #expect(array.count == 2)
    }

    @Test("returns nil when serializing nil or empty leg arrays")
    func rejectsNilAndEmptyLegSerialization() {
        #expect(RadarTripLeg.array(for: nil) == nil)
        #expect(RadarTripLeg.array(for: []) == nil)
    }

    // MARK: - Round-Trip Serialization

    @Test("round-trips a geofence leg")
    func roundTripsGeofenceLeg() throws {
        let original = RadarTripLeg(
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )
        original.stopDuration = 15
        original.metadata = ["key": "value"]

        let restored = try #require(
            RadarTripLeg(from: original.dictionaryValue())
        )

        #expect(original.isEqual(restored))
    }

    @Test("round-trips a coordinate leg")
    func roundTripsCoordinateLeg() throws {
        let original = RadarTripLeg(
            coordinates: CLLocationCoordinate2D(
                latitude: 40.783825,
                longitude: -73.975365
            )
        )
        original.arrivalRadius = 100
        original.stopDuration = 5

        let restored = try #require(
            RadarTripLeg(from: original.dictionaryValue())
        )

        #expect(original.isEqual(restored))
    }

    // MARK: - Equality

    @Test("legs with matching values are equal")
    func matchingLegsAreEqual() {
        let first = RadarTripLeg(
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )
        first.stopDuration = 10
        first.metadata = ["key": "value"]

        let second = RadarTripLeg(
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )
        second.stopDuration = 10
        second.metadata = ["key": "value"]

        #expect(first.isEqual(second))
    }

    @Test("legs with different geofence tags are not equal")
    func differentGeofenceTagsAreNotEqual() {
        let first = RadarTripLeg(
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )
        let second = RadarTripLeg(
            destinationGeofenceTag: "warehouse",
            destinationGeofenceExternalId: "store-1"
        )

        #expect(first.isEqual(second) == false)
    }

    @Test("legs with different destination types are not equal")
    func differentDestinationTypesAreNotEqual() {
        let first = RadarTripLeg(address: "123 Main St")
        let second = RadarTripLeg(
            coordinates: CLLocationCoordinate2D(
                latitude: 40,
                longitude: -74
            )
        )

        #expect(first.isEqual(second) == false)
    }

    @Test("legs with different stop durations are not equal")
    func differentStopDurationsAreNotEqual() {
        let first = RadarTripLeg(address: "123 Main St")
        first.stopDuration = 10

        let second = RadarTripLeg(address: "123 Main St")
        second.stopDuration = 20

        #expect(first.isEqual(second) == false)
    }

    @Test("a leg is not equal to nil or another type")
    func nilAndWrongTypesAreNotEqual() {
        let leg = RadarTripLeg(address: "123 Main St")

        #expect(leg.isEqual(nil) == false)
        #expect(leg.isEqual("not a leg") == false)
    }

    @Test("a leg is equal to itself")
    func legIsEqualToItself() {
        let leg = RadarTripLeg(address: "123 Main St")

        #expect(leg.isEqual(leg))
    }

    // MARK: - Coordinate Mutation

    @Test("setting valid coordinates updates coordinate state")
    func setsValidCoordinates() {
        let leg = RadarTripLeg()

        #expect(leg.hasCoordinates == false)

        leg.coordinates = CLLocationCoordinate2D(
            latitude: 40,
            longitude: -74
        )

        #expect(leg.hasCoordinates)
        #expect(leg.coordinates.latitude == 40)
        #expect(leg.coordinates.longitude == -74)
    }

    @Test("setting invalid coordinates clears coordinate state")
    func setsInvalidCoordinates() {
        let leg = RadarTripLeg()

        leg.coordinates = kCLLocationCoordinate2DInvalid

        #expect(leg.hasCoordinates == false)
    }
}
