//
//  RadarSerializationSnapshotTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

// Pilot snapshot tests (FENCE-3229). Each test parses a fixture with the SDK's own parser,
// serializes the model the way the Flutter and React Native bridges do, and compares the result
// with a snapshot in Resources/Serialized. See SerializationSnapshot for how to record snapshots.
// The snapshot paths match the Android SDK's, so the two platforms' output can be diffed.

@Suite("Serialization snapshots")
struct RadarSerializationSnapshotTests {

    /// `RadarTimeZone.dictionaryValue` formats `currentTime` in the device's time zone, so the
    /// output differs between machines. Pins the default time zone to UTC (what CI runners use)
    /// while `body` runs.
    ///
    /// This changes process-wide state, so a test running in parallel that reads the default time
    /// zone in that short window could see UTC. No other suite depends on the local time zone today.
    private static func withUTCDefaultTimeZone<T>(_ body: () throws -> T) rethrows -> T {
        let original = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "UTC")!
        defer { NSTimeZone.default = original }
        return try body()
    }

    @Test("geocode.json addresses")
    func geocodeAddresses() throws {
        let response = try RadarSDKTestResources.jsonDictionary(fromResource: "geocode")
        let addressesObject = try #require(response["addresses"])
        let addresses = try #require(RadarAddress.addresses(fromObject: addressesObject))
        try #require(!addresses.isEmpty)

        for (index, address) in addresses.enumerated() {
            let dictionary = Self.withUTCDefaultTimeZone { address.dictionaryValue() }
            SerializationSnapshot.assertMatches(dictionary, snapshot: "geocode/addresses.\(index)")
        }
    }

    @Test("Full Address fixture")
    func fullAddress() throws {
        let object = try SerializationSnapshot.jsonObject(resource: "Full/Address.json")
        let address = try #require(RadarAddress(from: object))

        assertFullyPopulated(address)

        let dictionary = Self.withUTCDefaultTimeZone { address.dictionaryValue() }
        SerializationSnapshot.assertMatches(dictionary, snapshot: "full/Address/root")
    }

    /// Sets every field `[Radar dictionaryForLocation:]` reads. It doesn't read `timestamp`,
    /// `floor` or `ellipsoidalAltitude`; the timestamp is set anyway so the input matches Android's.
    /// `floor` and `ellipsoidalAltitude` have no public initializer.
    @Test("Location built in code")
    func builtLocation() {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 40.7039, longitude: -73.9867),
            altitude: 10.5,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 3.0,
            course: 90.0,
            courseAccuracy: 10.0,
            speed: 1.5,
            speedAccuracy: 0.5,
            timestamp: Date(timeIntervalSince1970: 1_737_479_963),  // 2025-01-21T17:19:23Z
            sourceInfo: CLLocationSourceInformation(softwareSimulationState: false, andExternalAccessoryState: false)
        )

        SerializationSnapshot.assertMatches(Radar.dictionaryForLocation(location), snapshot: "built/location")
    }

    @Test("assertFullyPopulated reports unset fields, including Swift-only storage")
    func fullyPopulatedReportsUnsetFields() throws {
        let object: [String: Any] = [
            "latitude": 40.7039,
            "longitude": -73.9867,
            "categories": [] as [String],
            "timeZone": ["id": "America/New_York"],
        ]
        let address = try #require(RadarAddress(from: object))

        let collector = IssueCommentCollector()
        withKnownIssue {
            assertFullyPopulated(address, allowedNull: ["RadarAddress.unit", "RadarTimeZone.idValue"])
        } matching: { issue in
            collector.append(issue.comments.map(\.rawValue).joined())
            return true
        }
        let reported = collector.comments

        let paths = Set(reported.compactMap { $0.split(separator: " ").first.map(String.init) })
        // Objective-C properties of the Swift @objcMembers model.
        #expect(paths.contains("RadarAddress.formattedAddress"))
        #expect(paths.contains("RadarAddress.categories"))
        // RadarTimeZone's public properties are non-optional with defaults, so only Mirror sees
        // that their private storage is nil.
        #expect(paths.contains("RadarAddress.timeZone.nameValue"))
        #expect(!paths.contains("RadarAddress.timeZone.idValue"))
        #expect(!paths.contains("RadarAddress.unit"))
        // RadarTimeZone.idValue is set, so its allowedNull entry is reported as unused.
        #expect(reported.contains { $0.hasPrefix("allowedNull entry RadarTimeZone.idValue") })
    }

    @Test("Canonical JSON number formatting")
    func canonicalNumbers() throws {
        let cases: [(Any, String)] = [
            (42, "42"),
            (42.0, "42.0"),
            (NSNumber(value: Int32(-18_000)), "-18000"),
            (true, "true"),
            (NSNumber(value: false), "false"),
            (40.7039, "40.7039"),
            (0.001, "0.001"),
            (1e-7, "1.0e-7"),
            (1e7, "1.0e7"),
            (12_345_678.0, "1.2345678e7"),
            (-0.0, "-0.0"),
            (NSNumber(value: Float(0.1)), "0.10000000149011612"),
        ]
        for (value, expected) in cases {
            #expect(try SnapshotCanonicalJSON.string(from: [value]) == "[\n  \(expected)\n]\n")
        }
        #expect(throws: SnapshotCanonicalJSON.UnsupportedValue.self) {
            try SnapshotCanonicalJSON.string(from: ["date": Date()])
        }
        #expect(throws: SnapshotCanonicalJSON.UnsupportedValue.self) {
            try SnapshotCanonicalJSON.string(from: [Double.nan])
        }
    }

    @Test("Canonical JSON strings and layout")
    func canonicalLayout() throws {
        let value: [String: Any] = [
            "b": "quote \" slash / backslash \\ newline \n tab \t bell \u{07} flag 🇺🇸",
            "a": [:] as [String: Any],
            "B": [] as [Any],
            "é": NSNull(),
        ]
        let expected = """
            {
              "B": [],
              "a": {},
              "b": "quote \\" slash / backslash \\\\ newline \\n tab \\t bell \\u0007 flag 🇺🇸",
              "é": null
            }

            """
        #expect(try SnapshotCanonicalJSON.string(from: value) == expected)
    }
}

/// Collects issue comments from `withKnownIssue`'s `matching` closure, which must be `Sendable`.
private final class IssueCommentCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    var comments: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ comment: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(comment)
    }
}
