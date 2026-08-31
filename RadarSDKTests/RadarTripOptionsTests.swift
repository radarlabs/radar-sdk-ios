//
//  RadarTripOptionsTests.swift
//  RadarSDKTests
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

// swiftlint:disable file_length

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarTripOptionsTests")
struct RadarTripOptionsTests {  // swiftlint:disable:this type_body_length

    // MARK: - Initialization

    @Test("default initializer values preserve existing behavior")
    func initializesWithDefaults() {
        let options = RadarTripOptions(
            externalId: "trip-1",
            destinationGeofenceTag: nil,
            destinationGeofenceExternalId: nil
        )

        #expect(options.externalId == "trip-1")
        #expect(options.destinationGeofenceTag == nil)
        #expect(options.destinationGeofenceExternalId == nil)
        #expect(options.metadata == nil)
        #expect(options.scheduledArrivalAt == nil)
        #expect(options.mode == .car)
        #expect(options.approachingThreshold == 0)
        #expect(options.startTracking)
        #expect(options.legs == nil)
    }

    @Test("initializes with a geofence destination")
    func initializesWithGeofenceDestination() {
        let options = RadarTripOptions(
            externalId: "trip-1",
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )

        #expect(options.externalId == "trip-1")
        #expect(options.destinationGeofenceTag == "store")
        #expect(options.destinationGeofenceExternalId == "store-1")
    }

    @Test("initializes with a scheduled arrival")
    func initializesWithScheduledArrival() throws {
        let scheduledArrivalAt = try #require(
            RadarUtils.isoDateFormatter.date(
                from: "2026-08-31T20:00:00.000+0000"
            )
        )

        let options = RadarTripOptions(
            externalId: "trip-1",
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1",
            scheduledArrivalAt: scheduledArrivalAt
        )

        #expect(options.scheduledArrivalAt == scheduledArrivalAt)
        #expect(options.startTracking)
    }

    @Test("initializes with an explicit tracking preference")
    func initializesWithTrackingPreference() {
        let options = RadarTripOptions(
            externalId: "trip-1",
            destinationGeofenceTag: nil,
            destinationGeofenceExternalId: nil,
            scheduledArrivalAt: nil,
            startTracking: false
        )

        #expect(options.startTracking == false)
        #expect(options.mode == .car)
    }

    @Test("allows mutable option fields to be configured")
    func configuresMutableFields() {
        let options = RadarTripOptions(
            externalId: "trip-1",
            destinationGeofenceTag: nil,
            destinationGeofenceExternalId: nil
        )
        let leg = RadarTripLeg(address: "123 Main St")

        options.metadata = ["driver": "driver-1"]
        options.mode = .truck
        options.approachingThreshold = 500
        options.startTracking = false
        options.legs = [leg]

        #expect(options.metadata?["driver"] as? String == "driver-1")
        #expect(options.mode == .truck)
        #expect(options.approachingThreshold == 500)
        #expect(options.startTracking == false)
        #expect(options.legs?.count == 1)
    }

    // MARK: - Dictionary Parsing

    @Test("parses complete trip options")
    func parsesCompleteOptions() throws {
        let options = try #require(
            RadarTripOptions(
                from: [
                    "externalId": "trip-1",
                    "metadata": ["driver": "driver-1"],
                    "destinationGeofenceTag": "store",
                    "destinationGeofenceExternalId": "store-1",
                    "mode": "foot",
                    "scheduledArrivalAt":
                        "2026-08-31T20:00:00.000+0000",
                    "approachingThreshold": 500,
                    "startTracking": false,
                ]
            )
        )

        #expect(options.externalId == "trip-1")
        #expect(options.metadata?["driver"] as? String == "driver-1")
        #expect(options.destinationGeofenceTag == "store")
        #expect(
            options.destinationGeofenceExternalId == "store-1"
        )
        #expect(options.mode == .foot)
        #expect(options.approachingThreshold == 500)
        #expect(options.startTracking == false)
        #expect(options.scheduledArrivalAt != nil)
    }

    @Test("parses scheduled arrival from an ISO date string")
    func parsesStringScheduledArrival() throws {
        let options = try #require(
            RadarTripOptions(
                from: [
                    "externalId": "trip-1",
                    "scheduledArrivalAt":
                        "2026-08-31T20:00:00.000+0000",
                ]
            )
        )
        let scheduledArrivalAt = try #require(
            options.scheduledArrivalAt
        )

        #expect(
            RadarUtils.isoDateFormatter.string(
                from: scheduledArrivalAt
            ) == "2026-08-31T20:00:00.000+0000"
        )
    }

    @Test("parses scheduled arrival from a Date")
    func parsesDateScheduledArrival() throws {
        let date = Date(timeIntervalSince1970: 1_788_200_000)

        let options = try #require(
            RadarTripOptions(
                from: [
                    "externalId": "trip-1",
                    "scheduledArrivalAt": date,
                ]
            )
        )

        #expect(options.scheduledArrivalAt == date)
    }

    @Test("parses scheduled arrival from milliseconds")
    func parsesMillisecondsScheduledArrival() throws {
        let milliseconds = 1_788_200_000_000

        let options = try #require(
            RadarTripOptions(
                from: [
                    "externalId": "trip-1",
                    "scheduledArrivalAt": milliseconds,
                ]
            )
        )

        #expect(
            options.scheduledArrivalAt?.timeIntervalSince1970
                == 1_788_200_000
        )
    }

    @Test("ignores malformed scheduled arrival values")
    func ignoresMalformedScheduledArrival() throws {
        let values: [Any] = [
            "not-a-date",
            ["unexpected": "dictionary"],
            NSNull(),
        ]

        for value in values {
            let options = try #require(
                RadarTripOptions(
                    from: [
                        "externalId": "trip-1",
                        "scheduledArrivalAt": value,
                    ]
                )
            )

            #expect(options.scheduledArrivalAt == nil)
        }
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
            let options = try #require(
                RadarTripOptions(
                    from: [
                        "externalId": "trip-1",
                        "mode": value,
                    ]
                )
            )

            #expect(options.mode == expected)
        }
    }

    @Test("defaults missing and unknown route modes to car")
    func defaultsRouteModeToCar() throws {
        let missingMode = try #require(
            RadarTripOptions(from: ["externalId": "trip-1"])
        )
        let unknownMode = try #require(
            RadarTripOptions(
                from: [
                    "externalId": "trip-1",
                    "mode": "spaceship",
                ]
            )
        )

        #expect(missingMode.mode == .car)
        #expect(unknownMode.mode == .car)
    }

    @Test("defaults startTracking to true when omitted")
    func defaultsStartTrackingToTrue() throws {
        let options = try #require(
            RadarTripOptions(from: ["externalId": "trip-1"])
        )

        #expect(options.startTracking)
        #expect(options.approachingThreshold == 0)
    }

    // MARK: - Serialization and Legs

    @Test("serializes complete trip options")
    func serializesCompleteOptions() throws {
        let scheduledArrivalAt = try #require(
            RadarUtils.isoDateFormatter.date(
                from: "2026-08-31T20:00:00.000+0000"
            )
        )
        let options = RadarTripOptions(
            externalId: "trip-1",
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1",
            scheduledArrivalAt: scheduledArrivalAt,
            startTracking: false
        )
        let leg = RadarTripLeg(address: "123 Main St")

        options.metadata = ["driver": "driver-1"]
        options.mode = .truck
        options.approachingThreshold = 500
        options.legs = [leg]

        let dictionary = options.dictionaryValue()

        #expect(dictionary["externalId"] as? String == "trip-1")
        #expect(
            dictionary["destinationGeofenceTag"] as? String
                == "store"
        )
        #expect(
            dictionary["destinationGeofenceExternalId"] as? String
                == "store-1"
        )
        #expect(dictionary["mode"] as? String == "truck")
        #expect(
            dictionary["scheduledArrivalAt"] as? String
                == "2026-08-31T20:00:00.000+0000"
        )
        #expect(
            (dictionary["approachingThreshold"] as? NSNumber)?
                .intValue == 500
        )
        #expect(
            (dictionary["startTracking"] as? NSNumber)?
                .boolValue == false
        )
        #expect(
            (dictionary["metadata"] as? [String: Any])?["driver"]
                as? String == "driver-1"
        )
        #expect((dictionary["legs"] as? [Any])?.count == 1)
    }

    @Test("omits unset optional values and zero thresholds")
    func omitsUnsetValues() {
        let options = RadarTripOptions(
            externalId: "trip-1",
            destinationGeofenceTag: nil,
            destinationGeofenceExternalId: nil
        )

        let dictionary = options.dictionaryValue()

        #expect(dictionary["externalId"] as? String == "trip-1")
        #expect(dictionary["metadata"] == nil)
        #expect(dictionary["destinationGeofenceTag"] == nil)
        #expect(
            dictionary["destinationGeofenceExternalId"] == nil
        )
        #expect(dictionary["scheduledArrivalAt"] == nil)
        #expect(dictionary["approachingThreshold"] == nil)
        #expect(dictionary["legs"] == nil)
        #expect(dictionary["mode"] as? String == "car")
        #expect(
            (dictionary["startTracking"] as? NSNumber)?.boolValue
                == true
        )
    }

    @Test("omits an empty leg array")
    func omitsEmptyLegArray() {
        let options = RadarTripOptions(
            externalId: "trip-1",
            destinationGeofenceTag: nil,
            destinationGeofenceExternalId: nil
        )
        options.legs = []

        #expect(options.dictionaryValue()["legs"] == nil)
    }

    @Test("serializes every route mode")
    func serializesRouteModes() {
        let cases: [(RadarRouteMode, String)] = [
            (.car, "car"),
            (.foot, "foot"),
            (.bike, "bike"),
            (.truck, "truck"),
            (.motorbike, "motorbike"),
        ]

        for (mode, expected) in cases {
            let options = RadarTripOptions(
                externalId: "trip-1",
                destinationGeofenceTag: nil,
                destinationGeofenceExternalId: nil
            )
            options.mode = mode

            #expect(
                options.dictionaryValue()["mode"] as? String
                    == expected
            )
        }
    }

    @Test("parses valid legs and drops malformed entries")
    func parsesLegs() throws {
        let options = try #require(
            RadarTripOptions(
                from: [
                    "externalId": "trip-1",
                    "legs": [
                        [
                            "destination": [
                                "address": "123 Main St"
                            ]
                        ],
                        "not-a-leg",
                    ],
                ]
            )
        )
        let legs = try #require(options.legs)

        #expect(legs.count == 1)
        #expect(legs[0].address == "123 Main St")
    }

    @Test("round-trips multi-leg trip options")
    func roundTripsLegs() throws {
        let options = RadarTripOptions(
            externalId: "trip-1",
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1"
        )
        let leg = RadarTripLeg(
            destinationGeofenceTag: "warehouse",
            destinationGeofenceExternalId: "warehouse-1"
        )
        leg.stopDuration = 10
        options.legs = [leg]

        let restored = try #require(
            RadarTripOptions(from: options.dictionaryValue())
        )
        let restoredLegs = try #require(restored.legs)

        #expect(restoredLegs.count == 1)
        #expect(
            restoredLegs[0].destinationGeofenceTag == "warehouse"
        )
    }

    // MARK: - Equality

    @Test("an option is equal to itself and matching options")
    func matchingOptionsAreEqual() {
        let options = makeCompleteOptions()
        let matching = makeCompleteOptions()

        #expect(options.isEqual(options))
        #expect(options.isEqual(matching))
    }

    @Test("options are not equal to nil or another type")
    func rejectsUnrelatedEqualityValues() {
        let options = makeCompleteOptions()

        #expect(options.isEqual(nil) == false)
        #expect(options.isEqual("trip-options") == false)
    }

    @Test("equality accounts for every option field")
    func equalityAccountsForEveryField() {
        let mutations: [(RadarTripOptions) -> Void] = [
            { $0.externalId = "different-trip" },
            { $0.metadata = ["driver": "different-driver"] },
            { $0.destinationGeofenceTag = "warehouse" },
            {
                $0.destinationGeofenceExternalId =
                    "different-store"
            },
            {
                $0.scheduledArrivalAt =
                    Date(timeIntervalSince1970: 1_788_200_001)
            },
            { $0.mode = .bike },
            { $0.approachingThreshold = 501 },
            { $0.startTracking = false },
            {
                $0.legs = [
                    RadarTripLeg(address: "456 Oak Ave")
                ]
            },
        ]

        for mutate in mutations {
            let original = makeCompleteOptions()
            let different = makeCompleteOptions()

            mutate(different)

            #expect(original.isEqual(different) == false)
        }
    }

    @Test("preserves a missing external ID from stored dictionaries")
    func preservesMissingExternalId() throws {
        let options = try #require(
            RadarTripOptions(from: [:])
        )

        #expect(options.externalId == nil)
    }

    private func makeCompleteOptions() -> RadarTripOptions {
        let options = RadarTripOptions(
            externalId: "trip-1",
            destinationGeofenceTag: "store",
            destinationGeofenceExternalId: "store-1",
            scheduledArrivalAt:
                Date(timeIntervalSince1970: 1_788_200_000),
            startTracking: true
        )

        options.metadata = ["driver": "driver-1"]
        options.mode = .truck
        options.approachingThreshold = 500
        options.legs = [
            RadarTripLeg(address: "123 Main St")
        ]

        return options
    }
}
