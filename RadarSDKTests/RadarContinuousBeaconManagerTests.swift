//
//  RadarContinuousBeaconManagerTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing
import UIKit

@testable import RadarSDK

/// A clock the tests advance by hand.
@MainActor
final class ContinuousBeaconTestClock {
    var time: TimeInterval = 1000
}

/// Holds every refresh sleep until `fireAll()`.
@MainActor
final class ContinuousBeaconTestSleeper {
    private(set) var delays: [TimeInterval] = []
    private var continuations: [CheckedContinuation<Void, Never>] = []

    var pendingCount: Int { continuations.count }

    func sleep(_ delay: TimeInterval) async {
        delays.append(delay)
        await withCheckedContinuation { continuations.append($0) }
    }

    func fireAll() {
        let pending = continuations
        continuations = []
        pending.forEach { $0.resume() }
    }
}

/// Records searches, and holds them until `finishPending()` while `holds` is set.
@MainActor
final class ContinuousBeaconTestSearch {
    var result: RadarContinuousBeaconManager.SearchResult? = .init(uuids: [RadarSerializedTests.ContinuousBeaconManagerTests.testUUID], beacons: [])
    var holds = false
    private(set) var locations: [CLLocation] = []
    private var pending: [CheckedContinuation<Void, Never>] = []

    func search(_ location: CLLocation) async -> RadarContinuousBeaconManager.SearchResult? {
        locations.append(location)
        if holds {
            await withCheckedContinuation { pending.append($0) }
        }
        return result
    }

    func finishPending() {
        let continuations = pending
        pending = []
        continuations.forEach { $0.resume() }
    }
}

extension RadarSerializedTests {

    @Suite("RadarContinuousBeaconManager")
    @MainActor
    struct ContinuousBeaconManagerTests {

        static let testUUID = "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"
        static let otherUUID = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
        static let venueA = CLLocation(latitude: 43.0300, longitude: -87.9300)
        // About 55m from venue A.
        static let nearVenueA = CLLocation(latitude: 43.0305, longitude: -87.9300)
        // About 1km from venue A.
        static let venueB = CLLocation(latitude: 43.0390, longitude: -87.9300)

        let manager = RadarContinuousBeaconManager()
        let mockPermissions = MockRadarPermissionsHelper()
        let mockBridge = MockRadarSwiftBridge()
        let notificationCenter = NotificationCenter()
        let clock = ContinuousBeaconTestClock()
        let sleeper = ContinuousBeaconTestSleeper()
        let fakeSearch = ContinuousBeaconTestSearch()

        init() {
            mockBridge.mockIsForeground = true
            mockBridge.mockLastLocation = Self.venueA

            manager.permissionsHelper = mockPermissions
            manager.notificationCenter = notificationCenter
            manager.now = { [clock] in clock.time }
            manager.sleep = { [sleeper] in await sleeper.sleep($0) }
            manager.searchBeacons = { [fakeSearch] in await fakeSearch.search($0) }
        }

        // MARK: - Helpers

        func withBridge(_ body: () async throws -> Void) async rethrows {
            let original = RadarSwift.bridge
            RadarSwift.bridge = mockBridge
            defer {
                manager.stop()
                sleeper.fireAll()
                fakeSearch.finishPending()
                RadarSwift.bridge = original
            }
            try await body()
        }

        func waitUntil(_ condition: () -> Bool) async {
            for _ in 0..<100 where !condition() {
                await Task.yield()
            }
        }

        /// Lets pending searches and refreshes run.
        func settle() async {
            for _ in 0..<20 {
                await Task.yield()
            }
        }

        /// Waits for a refresh to be scheduled, then fires it.
        func fireRefresh() async {
            await waitUntil { sleeper.pendingCount > 0 }
            sleeper.fireAll()
        }

        /// The delay of the last scheduled refresh, once it's waiting.
        func lastRefreshDelay() async -> TimeInterval? {
            await waitUntil { sleeper.pendingCount > 0 }
            return sleeper.delays.last
        }

        /// UUIDs CoreLocation is currently ranging for the manager.
        var rangedUUIDs: Set<String> {
            Set(manager.locationManager.rangedBeaconConstraints.map(\.uuid.uuidString))
        }

        func startAndWaitForRanging() async {
            manager.start()
            await waitUntil { manager.ranging }
        }

        /// Starts ranging and waits out the minimum ranging duration.
        func startAndWarmUp() async {
            await startAndWaitForRanging()
            clock.time += RadarContinuousBeaconManager.minRangingDuration
        }

        static func entry(rssi: Int, major: String = "1", minor: String = "2") -> RadarContinuousBeaconManager.RangedBeacon {
            RadarContinuousBeaconManager.RangedBeacon(uuid: testUUID, major: major, minor: minor, rssi: rssi)
        }

        static func uuidResult(_ uuid: String) -> RadarContinuousBeaconManager.SearchResult {
            .init(uuids: [uuid], beacons: [])
        }

        static func rangingUnavailableKey(_ uuid: String) -> String {
            RadarContinuousBeaconManager.key(for: CLBeaconIdentityConstraint(uuid: UUID(uuidString: uuid)!))
        }

        // MARK: - beacons(near:)

        @Test("beacons(near:) is nil when not started")
        func beacons_notStarted_isNil() async {
            await withBridge {
                #expect(manager.beacons(near: Self.venueA) == nil)
            }
        }

        @Test("beacons(near:) is nil before the minimum ranging duration, without resetting")
        func beacons_beforeMinRanging_isNilWithoutResetting() async {
            await withBridge {
                await startAndWaitForRanging()
                clock.time += RadarContinuousBeaconManager.minRangingDuration - 1

                #expect(manager.beacons(near: Self.venueA) == nil)
                #expect(manager.ranging)
                #expect(manager.searchResult != nil)
            }
        }

        @Test("beacons(near:) is empty, not nil, after the minimum ranging duration without results")
        func beacons_afterMinRangingWithoutResults_isEmpty() async {
            await withBridge {
                await startAndWarmUp()

                #expect(manager.beacons(near: Self.venueA)?.isEmpty == true)
            }
        }

        @Test("beacons(near:) returns ranged beacons until they expire")
        func beacons_returnsBeaconsUntilTheyExpire() async {
            await withBridge {
                await startAndWarmUp()

                manager.handleRanged([Self.entry(rssi: -60), Self.entry(rssi: -70, minor: "3")])
                #expect(manager.beacons(near: Self.venueA)?.count == 2)

                clock.time += RadarContinuousBeaconManager.maxBeaconAge - 1
                manager.handleRanged([Self.entry(rssi: -62)])

                clock.time += 2
                #expect(manager.beacons(near: Self.venueA)?.count == 1)

                clock.time += RadarContinuousBeaconManager.maxBeaconAge
                #expect(manager.beacons(near: Self.venueA)?.isEmpty == true)
            }
        }

        @Test("beacons(near:) is nil after a refresh changes the beacons, until the new ranging runs")
        func beacons_afterRefreshChangesBeacons_isNilUntilNewRangingRuns() async {
            await withBridge {
                await startAndWarmUp()
                #expect(manager.beacons(near: Self.venueA) != nil)

                fakeSearch.result = Self.uuidResult(Self.otherUUID)
                await fireRefresh()
                await waitUntil { rangedUUIDs == [Self.otherUUID] }

                #expect(rangedUUIDs == [Self.otherUUID])
                #expect(manager.beacons(near: Self.venueA) == nil)

                clock.time += RadarContinuousBeaconManager.minRangingDuration
                #expect(manager.beacons(near: Self.venueA)?.isEmpty == true)
            }
        }

        @Test("beacons(near:) serves locations within the max search distance")
        func beacons_withinMaxDistance_isServed() async {
            await withBridge {
                await startAndWarmUp()

                #expect(manager.beacons(near: Self.nearVenueA)?.isEmpty == true)
            }
        }

        @Test("beacons(near:) beyond the max search distance resets, then ranges the caller's search")
        func beacons_beyondMaxDistance_resetsAndRangesCallersSearch() async {
            await withBridge {
                fakeSearch.result = .init(uuids: [], beacons: [.init(uuid: Self.testUUID, major: "1", minor: "2")])
                await startAndWarmUp()

                #expect(manager.beacons(near: Self.venueB) == nil)
                #expect(!manager.ranging)
                #expect(manager.searchResult == nil)
                #expect(manager.searchLocation == nil)

                manager.onSearched(from: Self.venueB, result: Self.uuidResult(Self.otherUUID))

                #expect(rangedUUIDs == [Self.otherUUID])
                #expect(manager.searchLocation == Self.venueB)
            }
        }

        @Test("beacons(near:) isn't served beyond the max search distance, even for a UUID search")
        func beacons_uuidSearchBeyondMaxDistance_isNil() async {
            await withBridge {
                await startAndWarmUp()

                #expect(manager.beacons(near: Self.venueB) == nil)
            }
        }

        @Test("beacons(near:) without ranging ranges the caller's search")
        func beacons_withoutRanging_rangesCallersSearch() async {
            await withBridge {
                mockBridge.mockLastLocation = nil
                manager.start()
                await settle()
                #expect(fakeSearch.locations.isEmpty)

                #expect(manager.beacons(near: Self.venueA) == nil)
                manager.onSearched(from: Self.venueA, result: Self.uuidResult(Self.testUUID))

                #expect(rangedUUIDs == [Self.testUUID])
                #expect(manager.searchLocation == Self.venueA)
            }
        }

        @Test("beacons(near:) during the minimum ranging duration keeps ranging the caller's same search")
        func beacons_duringMinRanging_keepsRangingCallersSearch() async {
            await withBridge {
                await startAndWaitForRanging()
                clock.time += 1

                #expect(manager.beacons(near: Self.venueA) == nil)
                manager.onSearched(from: Self.venueA, result: Self.uuidResult(Self.testUUID))

                // Ranging wasn't restarted, so it's ready on the original schedule.
                clock.time += RadarContinuousBeaconManager.minRangingDuration - 1
                #expect(manager.beacons(near: Self.venueA)?.isEmpty == true)
            }
        }
    }
}
