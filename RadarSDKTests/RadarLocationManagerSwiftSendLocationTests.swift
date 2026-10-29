//
//  RadarLocationManagerSwiftSendLocationTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

// Keep the send fixtures next to the tests that use them.
// swiftlint:disable file_length

/// Records one-shot ranging requests and answers them with a scripted result.
final class StubBeaconRanger: @unchecked Sendable {
    var status: RadarStatus = .success
    var rangedBeacons: [RadarBeacon]? = []
    private(set) var rangedBeaconRequests: [[RadarBeacon]] = []
    private(set) var rangedUUIDRequests: [[String]] = []

    func range(_ beacons: [RadarBeacon], completionHandler: RadarBeaconCompletionHandler) {
        rangedBeaconRequests.append(beacons)
        completionHandler(status, rangedBeacons)
    }

    func range(uuids: [String], completionHandler: RadarBeaconCompletionHandler) {
        rangedUUIDRequests.append(uuids)
        completionHandler(status, rangedBeacons)
    }
}

/// `-[RadarLocationManager sendLocation:stopped:source:replayed:beacons:forceTrack:]`, which is
/// private to RadarLocationManager.m.
private typealias ObjCSendLocation =
    @convention(c) (
        AnyObject, Selector, CLLocation, Bool, RadarLocationSource, Bool, NSArray?, Bool
    ) -> Void

@MainActor
enum SendFixtures {
    static let indoorLocation = HandleLocationFixtures.location(latitude: 40.71)
    static let syncRegion: [String: Any] = ["useSyncRegion": true]
    static let modifiedBeacons: [String: Any] = ["useRadarModifiedBeacon": true]
    static let syncRegionWithModifiedBeacons: [String: Any] = ["useSyncRegion": true, "useRadarModifiedBeacon": true]

    /// Replaces the bridge, ranging, and indoor location seams `sendLocation` uses, and clears the
    /// settings and sync state it reads.
    static func withDependencies(
        _ sdkConfiguration: [String: Any] = [:],
        beacons: Bool = false,
        _ body: (MockRadarSwiftBridge, StubBeaconRanger) async throws -> Void
    ) async rethrows {
        RadarLocationManagerSwiftTestHelpers.clearState()
        RadarSyncManager.syncStore.clear()
        defer {
            RadarLocationManagerSwiftTestHelpers.clearState()
            RadarSyncManager.syncStore.clear()
        }

        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: sdkConfiguration)
        let options = HandleLocationFixtures.trackingOptions()
        options.beacons = beacons
        RadarSettings.trackingOptions = options

        let bridge = MockRadarSwiftBridge()
        let originalBridge = RadarSwift.bridge
        RadarSwift.bridge = bridge
        defer { RadarSwift.bridge = originalBridge }

        let ranger = StubBeaconRanger()
        let originalRangeBeacons = RadarLocationManagerSwift.rangeBeacons
        let originalRangeBeaconUUIDs = RadarLocationManagerSwift.rangeBeaconUUIDs
        let originalGetIndoorLocation = RadarLocationManagerSwift.getIndoorLocation
        RadarLocationManagerSwift.rangeBeacons = { ranger.range($0, completionHandler: $1) }
        RadarLocationManagerSwift.rangeBeaconUUIDs = { ranger.range(uuids: $0, completionHandler: $1) }
        RadarLocationManagerSwift.getIndoorLocation = { $0(indoorLocation) }
        defer {
            RadarLocationManagerSwift.rangeBeacons = originalRangeBeacons
            RadarLocationManagerSwift.rangeBeaconUUIDs = originalRangeBeaconUUIDs
            RadarLocationManagerSwift.getIndoorLocation = originalGetIndoorLocation
        }

        try await body(bridge, ranger)
    }

    /// Sends `location` and waits until the send clears `sending`, which every path does when it
    /// finishes, whether or not it tracked.
    static func send(
        host: TrackingRadarLocationManagerHost,
        location: CLLocation = HandleLocationFixtures.location(),
        source: RadarLocationSource = .backgroundLocation,
        beacons: [RadarBeacon]? = nil,
        forceTrack: Bool = true
    ) async {
        await withCheckedContinuation { continuation in
            host.onSendingCleared = {
                host.onSendingCleared = nil
                continuation.resume()
            }
            RadarLocationManagerSwift.sendLocation(
                host: host, location: location, stopped: false, source: source, replayed: false, beacons: beacons,
                forceTrack: forceTrack)
        }
    }

    /// Writes a synced region around `HandleLocationFixtures.origin` with one beacon at its center.
    static func writeSyncedRegion(beaconId: String = "beacon1", lastSyncedBeaconIds: [String] = []) {
        let center = RadarCoordinate(
            latitude: HandleLocationFixtures.origin.latitude, longitude: HandleLocationFixtures.origin.longitude)
        var state = RadarSyncState()
        state.syncedRegionCenter = center
        state.syncedRegionRadius = 1000
        state.syncedBeacons = [
            RadarBeaconSwift(
                id: beaconId, description: "Beacon", tag: "tag", externalId: beaconId, uuid: syncedBeaconUUID,
                major: "1", minor: "2", geometry: center)
        ]
        state.lastSyncedBeaconIds = lastSyncedBeaconIds
        RadarSyncManager.syncStore.write(state)
    }

    static let syncedBeaconUUID = "B9407F30-F5F8-466E-AFF9-25556B57FE6D"

    /// A ranged beacon matching the synced region's beacon.
    static func rangedSyncedBeacon() -> RadarBeacon {
        RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "ranged", uuid: syncedBeaconUUID, major: "1", minor: "2")
    }

    static func user(geofences: [RadarGeofence] = []) -> RadarUser {
        let dict: [String: Any] = [
            "_id": "user",
            "location": [
                "type": "Point",
                "coordinates": [HandleLocationFixtures.origin.longitude, HandleLocationFixtures.origin.latitude],
            ],
            "geofences": geofences.map { $0.dictionaryValue() },
            "beacons": [] as [[String: Any]],
        ]
        return RadarUser(object: dict as NSDictionary)!
    }
}

extension RadarSerializedTests {
    @Suite(.serialized)
    @MainActor
    struct RadarSendLocationSwiftTests {

        // MARK: - Tracking

        @Test("a location is tracked with its beacons and indoor location, and the response is applied")
        func tracksAndAppliesResponse() async throws {
            try await SendFixtures.withDependencies { bridge, _ in
                let host = TrackingRadarLocationManagerHost()
                let beacons = [RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "b", uuid: "u", major: "1", minor: "1")]
                let geofences = [RadarLocationManagerSwiftTestHelpers.makeGeofence(id: "nearby")]
                bridge.trackResponse = .init(
                    status: .success, user: SendFixtures.user(), nearbyGeofences: geofences,
                    config: RadarConfig.from(dictionary: [:]))
                let location = HandleLocationFixtures.location()

                await SendFixtures.send(host: host, location: location, beacons: beacons)

                let request = try #require(bridge.trackRequests.first)
                #expect(bridge.trackRequests.count == 1)
                #expect(request.location === location)
                #expect(request.beacons?.first === beacons.first)
                #expect(request.indoorLocation === SendFixtures.indoorLocation)
                #expect(!host.sending())
                #expect(bridge.updateTrackingFromInitializeCallCount == 1)
                #expect(host.replacedSyncedGeofences.count == 1)
                #expect(host.replacedSyncedGeofences.first??.first === geofences.first)
                #expect(bridge.indoorTrackingGeofences.count == 1)
            }
        }

        @Test("a failed response applies the meta but keeps the synced geofences")
        func failedResponseKeepsGeofences() async {
            await SendFixtures.withDependencies { bridge, _ in
                let host = TrackingRadarLocationManagerHost()
                bridge.trackResponse = .init(status: .errorServer, config: RadarConfig.from(dictionary: [:]))

                await SendFixtures.send(host: host)

                #expect(bridge.updateTrackingFromInitializeCallCount == 1)
                #expect(host.replacedSyncedGeofences.isEmpty)
            }
        }

        @Test("a response without a config is not applied, but indoor tracking still updates")
        func responseWithoutConfigIsNotApplied() async {
            await SendFixtures.withDependencies { bridge, _ in
                let host = TrackingRadarLocationManagerHost()
                bridge.trackResponse = .init(status: .success, user: SendFixtures.user())

                await SendFixtures.send(host: host)

                #expect(bridge.trackRequests.count == 1)
                #expect(bridge.updateTrackingFromInitializeCallCount == 0)
                #expect(host.replacedSyncedGeofences.isEmpty)
                #expect(bridge.indoorTrackingGeofences.count == 1)
            }
        }

        @Test("with modified beacons, every response is applied, even without a config")
        func modifiedBeaconsAlwaysApplyResponse() async {
            await SendFixtures.withDependencies(SendFixtures.modifiedBeacons) { bridge, _ in
                let host = TrackingRadarLocationManagerHost()
                bridge.trackResponse = .init(status: .errorServer)

                await SendFixtures.send(host: host)

                #expect(bridge.trackRequests.count == 1)
                #expect(bridge.updateTrackingFromInitializeCallCount == 1)
                #expect(host.replacedSyncedGeofences.count == 1)
                #expect(bridge.indoorTrackingGeofences.isEmpty)
            }
        }

        // MARK: - Sync region

        @Test("a successful track marks fired dwell events")
        func successfulTrackMarksDwellEvents() async throws {
            try await SendFixtures.withDependencies(SendFixtures.syncRegion) { bridge, _ in
                SendFixtures.writeSyncedRegion()
                let host = TrackingRadarLocationManagerHost()
                let geofence = RadarLocationManagerSwiftTestHelpers.makeGeofence(id: "dwelled")
                bridge.trackResponse = .init(
                    status: .success, events: [makeEvent(type: .userDwelledInGeofence, geofence: geofence)],
                    user: SendFixtures.user(), config: RadarConfig.from(dictionary: [:]))

                await SendFixtures.send(host: host)

                let state = try #require(RadarSyncManager.syncStore.read())
                #expect(state.dwellEventsFired == ["dwelled"])
            }
        }

        @Test("a failed track rolls back the beacon state saved before it")
        func failedTrackRollsBackBeaconState() async throws {
            try await SendFixtures.withDependencies(
                SendFixtures.syncRegionWithModifiedBeacons, beacons: true
            ) { bridge, ranger in
                SendFixtures.writeSyncedRegion(lastSyncedBeaconIds: ["previous"])
                ranger.rangedBeacons = [SendFixtures.rangedSyncedBeacon()]
                bridge.trackResponse = .init(status: .errorServer)
                let host = TrackingRadarLocationManagerHost()

                await SendFixtures.send(host: host, forceTrack: true)

                #expect(bridge.trackRequests.count == 1)
                let state = try #require(RadarSyncManager.syncStore.read())
                #expect(state.lastSyncedBeaconIds == ["previous"])
            }
        }

        // MARK: - Beacon search

        @Test("beacon entries and exits don't search for beacons")
        func beaconSourcesSkipSearch() async {
            await SendFixtures.withDependencies(beacons: true) { bridge, ranger in
                let host = TrackingRadarLocationManagerHost()

                await SendFixtures.send(host: host, source: .beaconEnter)

                #expect(bridge.searchBeaconsLocations.isEmpty)
                #expect(ranger.rangedBeaconRequests.isEmpty)
                #expect(bridge.trackRequests.count == 1)
            }
        }

        @Test("outside a synced region, nearby beacons are searched and the location is sent without waiting")
        func searchesBeaconsOutsideSyncedRegion() async throws {
            try await SendFixtures.withDependencies(beacons: true) { bridge, ranger in
                let host = TrackingRadarLocationManagerHost()
                let beacons = [RadarLocationManagerSwiftTestHelpers.makeBeacon(id: "b", uuid: "u", major: "1", minor: "1")]

                await SendFixtures.send(host: host, beacons: beacons)

                #expect(bridge.searchBeaconsLocations.count == 1)
                #expect(ranger.rangedBeaconRequests.isEmpty)
                let request = try #require(bridge.trackRequests.first)
                #expect(request.beacons?.first === beacons.first)
            }
        }

        @Test("in a synced region, a location is skipped when ranging doesn't change the beacon state")
        func unchangedBeaconStateSkipsTrack() async {
            await SendFixtures.withDependencies(SendFixtures.syncRegion, beacons: true) { bridge, ranger in
                SendFixtures.writeSyncedRegion(lastSyncedBeaconIds: ["beacon1"])
                ranger.rangedBeacons = [SendFixtures.rangedSyncedBeacon()]
                let host = TrackingRadarLocationManagerHost()

                await SendFixtures.send(host: host, forceTrack: false)

                #expect(ranger.rangedBeaconRequests.count == 1)
                #expect(bridge.trackRequests.isEmpty)
                #expect(bridge.lastSentAt() == nil)
                #expect(!host.sending())
            }
        }

        @Test("in a synced region, a changed beacon state is saved and sent with the ranged beacons")
        func changedBeaconStateTracksRangedBeacons() async throws {
            try await SendFixtures.withDependencies(SendFixtures.syncRegion, beacons: true) { bridge, ranger in
                SendFixtures.writeSyncedRegion()
                let ranged = SendFixtures.rangedSyncedBeacon()
                ranger.rangedBeacons = [ranged]
                var beaconIdsWhenTracked: [String]?
                bridge.onTrackRequest = { beaconIdsWhenTracked = RadarSyncManager.syncStore.read()?.lastSyncedBeaconIds }
                let host = TrackingRadarLocationManagerHost()

                await SendFixtures.send(host: host, forceTrack: false)

                let request = try #require(bridge.trackRequests.first)
                #expect(request.beacons?.first === ranged)
                #expect(bridge.lastSentAt() != nil)
                #expect(beaconIdsWhenTracked == ["beacon1"])
            }
        }

        // MARK: - Modified beacons

        @Test("with modified beacons and no synced beacons nearby, only a forced track is sent, with no beacons")
        func modifiedBeaconsWithoutSyncedBeacons() async throws {
            try await SendFixtures.withDependencies(
                SendFixtures.syncRegionWithModifiedBeacons, beacons: true
            ) { bridge, _ in
                SendFixtures.writeSyncedRegion()
                let farAway = HandleLocationFixtures.location(latitude: HandleLocationFixtures.origin.latitude + 0.005)
                let host = TrackingRadarLocationManagerHost()

                await SendFixtures.send(host: host, location: farAway, forceTrack: false)
                #expect(bridge.trackRequests.isEmpty)

                await SendFixtures.send(host: host, location: farAway, forceTrack: true)
                let request = try #require(bridge.trackRequests.first)
                #expect(request.beacons?.isEmpty == true)
            }
        }

        @Test("with modified beacons, a forced track is sent without beacons when ranging fails")
        func modifiedBeaconsRangingFailure() async throws {
            try await SendFixtures.withDependencies(
                SendFixtures.syncRegionWithModifiedBeacons, beacons: true
            ) { bridge, ranger in
                SendFixtures.writeSyncedRegion()
                ranger.status = .errorBluetooth
                ranger.rangedBeacons = nil
                let host = TrackingRadarLocationManagerHost()

                await SendFixtures.send(host: host, forceTrack: true)

                let request = try #require(bridge.trackRequests.first)
                #expect(request.beacons == nil)
            }
        }

        @Test("with modified beacons, searched beacon UUIDs are ranged and sent")
        func modifiedBeaconsRangeSearchedUUIDs() async throws {
            try await SendFixtures.withDependencies(SendFixtures.modifiedBeacons, beacons: true) { bridge, ranger in
                bridge.searchBeaconsResult = (nil, [SendFixtures.syncedBeaconUUID])
                let ranged = SendFixtures.rangedSyncedBeacon()
                ranger.rangedBeacons = [ranged]
                let host = TrackingRadarLocationManagerHost()

                await SendFixtures.send(host: host)

                #expect(ranger.rangedUUIDRequests == [[SendFixtures.syncedBeaconUUID]])
                let request = try #require(bridge.trackRequests.first)
                #expect(request.beacons?.first === ranged)
            }
        }

        @Test("with modified beacons, a search with no beacons sends the location with no beacons")
        func modifiedBeaconsEmptySearch() async throws {
            try await SendFixtures.withDependencies(SendFixtures.modifiedBeacons, beacons: true) { bridge, ranger in
                let host = TrackingRadarLocationManagerHost()

                await SendFixtures.send(host: host)

                #expect(ranger.rangedBeaconRequests.isEmpty)
                #expect(ranger.rangedUUIDRequests.isEmpty)
                let request = try #require(bridge.trackRequests.first)
                #expect(request.beacons?.isEmpty == true)
            }
        }

        // MARK: - Seam

        @Test("the Objective-C sendLocation sends through Swift when the flag is on")
        func objcSendLocationDispatchesToSwift() async {
            await SendFixtures.withDependencies(["useSwiftLocationManager": true]) { bridge, _ in
                let manager = RadarLocationManager.sharedInstance()
                let location = HandleLocationFixtures.location()
                await withCheckedContinuation { continuation in
                    bridge.onTrack = {
                        bridge.onTrack = nil
                        continuation.resume()
                    }
                    let selector = NSSelectorFromString("sendLocation:stopped:source:replayed:beacons:forceTrack:")
                    let sendLocation = unsafeBitCast(manager.method(for: selector), to: ObjCSendLocation.self)
                    sendLocation(manager, selector, location, true, .manualLocation, false, nil, true)
                }

                #expect(bridge.trackRequests.first?.location === location)
                #expect(bridge.trackRequests.first?.stopped == true)
                #expect(manager.value(forKey: "sending") as? Bool == false)
            }
        }
    }
}
