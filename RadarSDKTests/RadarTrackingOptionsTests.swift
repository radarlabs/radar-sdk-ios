//
//  RadarTrackingOptionsTests.swift
//  RadarSDKTests
//
//  Created by Alan Charles on 9/1/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

// swiftlint:disable file_length

import Testing
import Foundation

@testable import RadarSDK

@Suite("RadarTrackingOptionsTests")
struct RadarTrackingOptionsTests {

    @Test("continuous preset preserves existing configuration")
    func continuousPreset() {
        let options = RadarTrackingOptions.presetContinuous

        #expect(options.desiredStoppedUpdateInterval == 30)
        #expect(options.desiredMovingUpdateInterval == 30)
        #expect(options.desiredSyncInterval == 20)
        #expect(options.desiredAccuracy == .high)
        #expect(options.stopDuration == 140)
        #expect(options.stopDistance == 70)
        #expect(options.startTrackingAfter == nil)
        #expect(options.stopTrackingAfter == nil)
        #expect(options.replay == .none)
        #expect(options.syncLocations == .all)
        #expect(options.showBlueBar)
        #expect(options.useStoppedGeofence == false)
        #expect(options.stoppedGeofenceRadius == 0)
        #expect(options.useMovingGeofence == false)
        #expect(options.movingGeofenceRadius == 0)
        #expect(options.syncGeofences)
        #expect(options.useVisits == false)
        #expect(options.useSignificantLocationChanges == false)
        #expect(options.beacons == false)
        #expect(options.useIndoorScan == false)
        #expect(options.useMotion == false)
        #expect(options.usePressure == false)
        #expect(options.batchInterval == 0)
        #expect(options.batchSize == 0)
        #expect(options.type == .default)
    }

    @Test("responsive preset preserves existing configuration")
    func responsivePreset() {
        let options = RadarTrackingOptions.presetResponsive

        #expect(options.desiredStoppedUpdateInterval == 0)
        #expect(options.desiredMovingUpdateInterval == 150)
        #expect(options.desiredSyncInterval == 20)
        #expect(options.desiredAccuracy == .medium)
        #expect(options.stopDuration == 140)
        #expect(options.stopDistance == 70)
        #expect(options.startTrackingAfter == nil)
        #expect(options.stopTrackingAfter == nil)
        #expect(options.replay == .stops)
        #expect(options.syncLocations == .all)
        #expect(options.showBlueBar == false)
        #expect(options.useStoppedGeofence)
        #expect(options.stoppedGeofenceRadius == 100)
        #expect(options.useMovingGeofence)
        #expect(options.movingGeofenceRadius == 100)
        #expect(options.syncGeofences)
        #expect(options.useVisits)
        #expect(options.useSignificantLocationChanges)
        #expect(options.beacons == false)
        #expect(options.useIndoorScan == false)
        #expect(options.useMotion == false)
        #expect(options.usePressure == false)
        #expect(options.batchInterval == 0)
        #expect(options.batchSize == 0)
        #expect(options.type == .default)
    }

    @Test("efficient preset preserves existing configuration")
    func efficientPreset() {
        let options = RadarTrackingOptions.presetEfficient

        #expect(options.desiredStoppedUpdateInterval == 0)
        #expect(options.desiredMovingUpdateInterval == 0)
        #expect(options.desiredSyncInterval == 0)
        #expect(options.desiredAccuracy == .medium)
        #expect(options.stopDuration == 0)
        #expect(options.stopDistance == 0)
        #expect(options.startTrackingAfter == nil)
        #expect(options.stopTrackingAfter == nil)
        #expect(options.replay == .stops)
        #expect(options.syncLocations == .all)
        #expect(options.showBlueBar == false)
        #expect(options.useStoppedGeofence == false)
        #expect(options.stoppedGeofenceRadius == 0)
        #expect(options.useMovingGeofence == false)
        #expect(options.movingGeofenceRadius == 0)
        #expect(options.syncGeofences)
        #expect(options.useVisits)
        #expect(options.useSignificantLocationChanges == false)
        #expect(options.beacons == false)
        #expect(options.useIndoorScan == false)
        #expect(options.useMotion == false)
        #expect(options.usePressure == false)
        #expect(options.batchInterval == 0)
        #expect(options.batchSize == 0)
        #expect(options.type == .default)
    }

    @Test("preset access returns independent mutable instances")
    func presetsReturnIndependentInstances() {
        let first = RadarTrackingOptions.presetResponsive
        let second = RadarTrackingOptions.presetResponsive

        #expect(first !== second)

        first.desiredMovingUpdateInterval = 999
        first.syncLocations = .none
        first.beacons = true

        #expect(second.desiredMovingUpdateInterval == 150)
        #expect(second.syncLocations == .all)
        #expect(second.beacons == false)
    }

    // MARK: - Enum Mappings

    @Test("maps desired accuracy values and strings")
    func mapsDesiredAccuracy() throws {
        let unknown = try #require(
                RadarTrackingOptionsDesiredAccuracy(rawValue: 999)
            )

        let cases: [(RadarTrackingOptionsDesiredAccuracy, String)] = [
            (.high, "high"),
            (.medium, "medium"),
            (.low, "low"),
        ]

        for (value, string) in cases {
            #expect(RadarTrackingOptions.string(for: value) == string)
            #expect(
                RadarTrackingOptions.desiredAccuracy(for: string) == value
            )
        }

        #expect(RadarTrackingOptions.string(for: unknown) == "medium")
        #expect(RadarTrackingOptions.desiredAccuracy(for: "unknown") == .medium)
        #expect(RadarTrackingOptions.desiredAccuracy(for: "") == .medium)
    }
    
    @Test("maps replay values and strings")
    func mapsReplay() throws {
        let unknown = try #require(
                RadarTrackingOptionsReplay(rawValue: 999)
            )
    
        let cases: [(RadarTrackingOptionsReplay, String)] = [
            (.stops, "stops"),
            (.none, "none"),
            (.all, "all"),
        ]

        for (value, string) in cases {
            #expect(RadarTrackingOptions.string(for: value) == string)
            #expect(RadarTrackingOptions.replay(for: string) == value)
        }

        #expect(RadarTrackingOptions.string(for: unknown) == "none")
        #expect(RadarTrackingOptions.replay(for: "unknown") == .none)
        #expect(RadarTrackingOptions.replay(for: "") == .none)
    }

    @Test("maps sync values and strings")
    func mapsSyncLocations() throws {
        let unknown = try #require(
                RadarTrackingOptionsSyncLocations(rawValue: 999)
            )

        let cases: [(RadarTrackingOptionsSyncLocations, String)] = [
            (.all, "all"),
            (.stopsAndExits, "stopsAndExits"),
            (.none, "none"),
            (.events, "events"),
        ]

        for (value, string) in cases {
            #expect(RadarTrackingOptions.string(for: value) == string)
            #expect(
                RadarTrackingOptions.syncLocations(for: string) == value
            )
        }

        #expect(RadarTrackingOptions.string(for: unknown) == "all")
        #expect(RadarTrackingOptions.syncLocations(for: "unknown") == .all)
        #expect(RadarTrackingOptions.syncLocations(for: "") == .all)
    }

    @Test("maps tracking option types and strings")
    func mapsTypes() throws {
        let unknown = try #require(
                RadarTrackingOptionsType(rawValue: 999)
            )

        let cases: [(RadarTrackingOptionsType, String)] = [
            (.default, "default"),
            (.onTrip, "on-trip"),
            (.inGeofence, "in-geofence"),
            (.isUser, "is-user"),
        ]

        for (value, string) in cases {
            #expect(RadarTrackingOptions.string(for: value) == string)
            #expect(RadarTrackingOptions.type(for: string) == value)
        }

        #expect(RadarTrackingOptions.string(for: unknown) == "default")
        #expect(RadarTrackingOptions.type(for: "unknown") == .default)
        #expect(RadarTrackingOptions.type(for: "") == .default)
    }

    // MARK: - Dictionary Parsing

    @Test("parses an empty dictionary using legacy defaults")
    func parsesEmptyDictionary() throws {
        let options = try #require(
            RadarTrackingOptions(from: [:])
        )

        #expect(options.desiredStoppedUpdateInterval == 0)
        #expect(options.desiredMovingUpdateInterval == 0)
        #expect(options.desiredSyncInterval == 0)
        #expect(options.desiredAccuracy == .medium)
        #expect(options.stopDuration == 0)
        #expect(options.stopDistance == 0)
        #expect(options.startTrackingAfter == nil)
        #expect(options.stopTrackingAfter == nil)
        #expect(options.replay == .none)
        #expect(options.syncLocations == .all)
        #expect(options.showBlueBar == false)
        #expect(options.useStoppedGeofence == false)
        #expect(options.stoppedGeofenceRadius == 0)
        #expect(options.useMovingGeofence == false)
        #expect(options.movingGeofenceRadius == 0)
        #expect(options.syncGeofences == false)
        #expect(options.useVisits == false)
        #expect(options.useSignificantLocationChanges == false)
        #expect(options.beacons == false)
        #expect(options.useIndoorScan == false)
        #expect(options.useMotion == false)
        #expect(options.usePressure == false)
        #expect(options.batchInterval == 0)
        #expect(options.batchSize == 0)
        #expect(options.type == .default)
    }

    @Test("parses a complete tracking options dictionary")
    func parsesCompleteDictionary() throws {
        let startTrackingAfter = Date(
            timeIntervalSince1970: 1_788_200_000
        )
        let stopTrackingAfter = Date(
            timeIntervalSince1970: 1_788_203_600
        )

        let options = try #require(
            RadarTrackingOptions(
                from: [
                    "desiredStoppedUpdateInterval": 10,
                    "desiredMovingUpdateInterval": 20,
                    "desiredSyncInterval": 30,
                    "desiredAccuracy": "low",
                    "stopDuration": 40,
                    "stopDistance": 50,
                    "startTrackingAfter": startTrackingAfter,
                    "stopTrackingAfter": stopTrackingAfter,
                    "sync": "events",
                    "replay": "all",
                    "showBlueBar": true,
                    "useStoppedGeofence": true,
                    "stoppedGeofenceRadius": 60,
                    "useMovingGeofence": true,
                    "movingGeofenceRadius": 70,
                    "syncGeofences": true,
                    "useVisits": true,
                    "useSignificantLocationChanges": true,
                    "beacons": true,
                    "useIndoorScan": true,
                    "useMotion": true,
                    "usePressure": true,
                    "batchInterval": 80,
                    "batchSize": 90,
                    "type": "on-trip",
                ]
            )
        )

        #expect(options.desiredStoppedUpdateInterval == 10)
        #expect(options.desiredMovingUpdateInterval == 20)
        #expect(options.desiredSyncInterval == 30)
        #expect(options.desiredAccuracy == .low)
        #expect(options.stopDuration == 40)
        #expect(options.stopDistance == 50)
        #expect(options.startTrackingAfter == startTrackingAfter)
        #expect(options.stopTrackingAfter == stopTrackingAfter)
        #expect(options.replay == .all)
        #expect(options.syncLocations == .events)
        #expect(options.showBlueBar)
        #expect(options.useStoppedGeofence)
        #expect(options.stoppedGeofenceRadius == 60)
        #expect(options.useMovingGeofence)
        #expect(options.movingGeofenceRadius == 70)
        #expect(options.syncGeofences)
        #expect(options.useVisits)
        #expect(options.useSignificantLocationChanges)
        #expect(options.beacons)
        #expect(options.useIndoorScan)
        #expect(options.useMotion)
        #expect(options.usePressure)
        #expect(options.batchInterval == 80)
        #expect(options.batchSize == 90)
        #expect(options.type == .onTrip)
    }

    @Test("parses every supported date representation")
    func parsesDateRepresentations() throws {
        let expected = Date(
            timeIntervalSince1970: 1_788_200_000
        )
        let values: [Any] = [
            expected,
            RadarUtils.isoDateFormatter.string(from: expected),
            NSNumber(
                value: expected.timeIntervalSince1970 * 1_000
            ),
        ]

        for value in values {
            let options = try #require(
                RadarTrackingOptions(
                    from: [
                        "startTrackingAfter": value,
                        "stopTrackingAfter": value,
                    ]
                )
            )

            #expect(options.startTrackingAfter == expected)
            #expect(options.stopTrackingAfter == expected)
        }
    }

    @Test("ignores malformed date values")
    func ignoresMalformedDates() throws {
        let values: [Any] = [
            "not-a-date",
            ["unexpected"],
            NSNull(),
        ]

        for value in values {
            let options = try #require(
                RadarTrackingOptions(
                    from: [
                        "startTrackingAfter": value,
                        "stopTrackingAfter": value,
                    ]
                )
            )

            #expect(options.startTrackingAfter == nil)
            #expect(options.stopTrackingAfter == nil)
        }
    }

    @Test("preserves Objective-C scalar coercion")
    func coercesScalarValues() throws {
        let options = try #require(
            RadarTrackingOptions(
                from: [
                    "desiredStoppedUpdateInterval": "10",
                    "desiredMovingUpdateInterval": "20",
                    "desiredSyncInterval": "30",
                    "stopDuration": "40",
                    "stopDistance": "50",
                    "showBlueBar": "YES",
                    "useStoppedGeofence": "true",
                    "stoppedGeofenceRadius": "60",
                    "useMovingGeofence": 1,
                    "movingGeofenceRadius": "70",
                    "syncGeofences": "1",
                    "useVisits": "yes",
                    "useSignificantLocationChanges": "TRUE",
                    "beacons": 1,
                    "useIndoorScan": "Y",
                    "useMotion": "t",
                    "usePressure": 2,
                    "batchInterval": "80",
                    "batchSize": "90",
                ]
            )
        )

        #expect(options.desiredStoppedUpdateInterval == 10)
        #expect(options.desiredMovingUpdateInterval == 20)
        #expect(options.desiredSyncInterval == 30)
        #expect(options.stopDuration == 40)
        #expect(options.stopDistance == 50)
        #expect(options.showBlueBar)
        #expect(options.useStoppedGeofence)
        #expect(options.stoppedGeofenceRadius == 60)
        #expect(options.useMovingGeofence)
        #expect(options.movingGeofenceRadius == 70)
        #expect(options.syncGeofences)
        #expect(options.useVisits)
        #expect(options.useSignificantLocationChanges)
        #expect(options.beacons)
        #expect(options.useIndoorScan)
        #expect(options.useMotion)
        #expect(options.usePressure)
        #expect(options.batchInterval == 80)
        #expect(options.batchSize == 90)
    }

    // MARK: - Dictionary Serialization

    @Test("serializes every tracking option using the existing dictionary format")
    func serializesCompleteOptions() {
        let options = RadarTrackingOptions()
        let startTrackingAfter = Date(
            timeIntervalSince1970: 1_788_200_000
        )
        let stopTrackingAfter = Date(
            timeIntervalSince1970: 1_788_203_600
        )

        options.desiredStoppedUpdateInterval = 10
        options.desiredMovingUpdateInterval = 20
        options.desiredSyncInterval = 30
        options.desiredAccuracy = .low
        options.stopDuration = 40
        options.stopDistance = 50
        options.startTrackingAfter = startTrackingAfter
        options.stopTrackingAfter = stopTrackingAfter
        options.syncLocations = .events
        options.replay = .all
        options.showBlueBar = true
        options.useStoppedGeofence = true
        options.stoppedGeofenceRadius = 60
        options.useMovingGeofence = true
        options.movingGeofenceRadius = 70
        options.syncGeofences = true
        options.useVisits = true
        options.useSignificantLocationChanges = true
        options.beacons = true
        options.useIndoorScan = true
        options.useMotion = true
        options.usePressure = true
        options.batchInterval = 80
        options.batchSize = 90
        options.type = .onTrip

        let dictionary = options.dictionaryValue()
        let expected: [String: Any] = [
            "desiredStoppedUpdateInterval": 10,
            "desiredMovingUpdateInterval": 20,
            "desiredSyncInterval": 30,
            "desiredAccuracy": "low",
            "stopDuration": 40,
            "stopDistance": 50,
            "startTrackingAfter": 1_788_200_000_000,
            "stopTrackingAfter": 1_788_203_600_000,
            "sync": "events",
            "replay": "all",
            "showBlueBar": true,
            "useStoppedGeofence": true,
            "stoppedGeofenceRadius": 60,
            "useMovingGeofence": true,
            "movingGeofenceRadius": 70,
            "syncGeofences": true,
            "useVisits": true,
            "useSignificantLocationChanges": true,
            "beacons": true,
            "useIndoorScan": true,
            "useMotion": true,
            "usePressure": true,
            "batchInterval": 80,
            "batchSize": 90,
            "type": "on-trip",
        ]

        #expect(
            NSDictionary(dictionary: dictionary).isEqual(to: expected)
        )
    }

    @Test("omits absent tracking dates from serialization")
    func omitsAbsentDates() {
        let dictionary = RadarTrackingOptions().dictionaryValue()

        #expect(dictionary["startTrackingAfter"] == nil)
        #expect(dictionary["stopTrackingAfter"] == nil)
    }

    // MARK: - Equality

    @Test("compares every field currently included in equality")
    func comparesEqualityFields() throws {
        let mutations: [
            (String, (RadarTrackingOptions) -> Void)
        ] = [
            ("desiredStoppedUpdateInterval", {
                $0.desiredStoppedUpdateInterval += 1
            }),
            ("desiredMovingUpdateInterval", {
                $0.desiredMovingUpdateInterval += 1
            }),
            ("desiredSyncInterval", {
                $0.desiredSyncInterval += 1
            }),
            ("desiredAccuracy", {
                $0.desiredAccuracy = .low
            }),
            ("stopDuration", {
                $0.stopDuration += 1
            }),
            ("stopDistance", {
                $0.stopDistance += 1
            }),
            ("startTrackingAfter", {
                $0.startTrackingAfter = Date(
                    timeIntervalSince1970: 1_788_200_000
                )
            }),
            ("stopTrackingAfter", {
                $0.stopTrackingAfter = Date(
                    timeIntervalSince1970: 1_788_200_000
                )
            }),
            ("syncLocations", {
                $0.syncLocations = .events
            }),
            ("replay", {
                $0.replay = .all
            }),
            ("showBlueBar", {
                $0.showBlueBar.toggle()
            }),
            ("useStoppedGeofence", {
                $0.useStoppedGeofence.toggle()
            }),
            ("stoppedGeofenceRadius", {
                $0.stoppedGeofenceRadius += 1
            }),
            ("useMovingGeofence", {
                $0.useMovingGeofence.toggle()
            }),
            ("movingGeofenceRadius", {
                $0.movingGeofenceRadius += 1
            }),
            ("syncGeofences", {
                $0.syncGeofences.toggle()
            }),
            ("useVisits", {
                $0.useVisits.toggle()
            }),
            ("useSignificantLocationChanges", {
                $0.useSignificantLocationChanges.toggle()
            }),
            ("beacons", {
                $0.beacons.toggle()
            }),
            ("useIndoorScan", {
                $0.useIndoorScan.toggle()
            }),
            ("useMotion", {
                $0.useMotion.toggle()
            }),
            ("usePressure", {
                $0.usePressure.toggle()
            }),
            ("batchInterval", {
                $0.batchInterval += 1
            }),
            ("batchSize", {
                $0.batchSize += 1
            }),
        ]

        for (name, mutate) in mutations {
            let original = RadarTrackingOptions.presetResponsive
            let modified = try copy(original)

            #expect(original == modified)

            mutate(modified)

            #expect(
                original != modified,
                "Expected \(name) to participate in equality"
            )
        }
    }

    @Test("compares tracking dates at millisecond precision")
    func comparesDatePrecision() throws {
        let date = Date(
            timeIntervalSince1970: 1_788_200_000
        )
        let expected = RadarTrackingOptions.presetResponsive
        let candidate = try copy(expected)

        expected.startTrackingAfter = date
        expected.stopTrackingAfter = date
        candidate.startTrackingAfter = date.addingTimeInterval(0.0005)
        candidate.stopTrackingAfter = date.addingTimeInterval(0.0005)

        #expect(expected == candidate)

        candidate.startTrackingAfter = date.addingTimeInterval(0.002)
        #expect(expected != candidate)

        candidate.startTrackingAfter = date.addingTimeInterval(0.0005)
        candidate.stopTrackingAfter = date.addingTimeInterval(0.002)
        #expect(expected != candidate)
    }

    @Test("preserves existing behavior that equality ignores type")
    func equalityIgnoresType() throws {
        let defaultType = RadarTrackingOptions.presetResponsive
        let onTripType = try copy(defaultType)

        defaultType.type = .default
        onTripType.type = .onTrip

        #expect(defaultType == onTripType)
    }

    private func copy(
        _ options: RadarTrackingOptions
    ) throws -> RadarTrackingOptions {
        try #require(
            RadarTrackingOptions(from: options.dictionaryValue())
        )
    }

    // MARK: - Initialization

    @Test("initializes using Objective-C zero-value defaults")
    func initializesWithDefaults() {
        let options = RadarTrackingOptions()

        #expect(options.desiredStoppedUpdateInterval == 0)
        #expect(options.desiredMovingUpdateInterval == 0)
        #expect(options.desiredSyncInterval == 0)
        #expect(options.desiredAccuracy == .high)
        #expect(options.stopDuration == 0)
        #expect(options.stopDistance == 0)
        #expect(options.startTrackingAfter == nil)
        #expect(options.stopTrackingAfter == nil)
        #expect(options.replay == .stops)
        #expect(options.syncLocations == .all)
        #expect(options.showBlueBar == false)
        #expect(options.useStoppedGeofence == false)
        #expect(options.stoppedGeofenceRadius == 0)
        #expect(options.useMovingGeofence == false)
        #expect(options.movingGeofenceRadius == 0)
        #expect(options.syncGeofences == false)
        #expect(options.useVisits == false)
        #expect(options.useSignificantLocationChanges == false)
        #expect(options.beacons == false)
        #expect(options.useIndoorScan == false)
        #expect(options.useMotion == false)
        #expect(options.usePressure == false)
        #expect(options.batchInterval == 0)
        #expect(options.batchSize == 0)
        #expect(options.type == .default)
    }

    @Test("returns nil for a nil dictionary")
    func returnsNilForNilDictionary() {
        let dictionary: [AnyHashable: Any]? = nil

        #expect(RadarTrackingOptions(from: dictionary) == nil)
    }
}
