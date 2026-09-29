//
//  RadarBeaconRangingCacheTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing
import UIKit

@testable import RadarSDK

final class BeaconRangingTestClock {
    var time: TimeInterval = 1000
}

final class BeaconSearchStub {
    var callCount = 0
    var uuids = ["2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"]
}

/// Records what the cache asked CoreLocation to range.
final class BeaconRangingRecorder: RadarBeaconRanging {
    private(set) var active: Set<String> = []

    func startRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint) {
        active.insert(constraint.uuid.uuidString)
    }

    func stopRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint) {
        active.remove(constraint.uuid.uuidString)
    }
}

extension RadarSerializedTests {

    @Suite("RadarBeaconRangingCache")
    @MainActor
    struct BeaconRangingCacheTests {

        private static let testUUID = "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"
        private static let otherUUID = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
        private static let venueA = CLLocation(latitude: 43.0300, longitude: -87.9300)
        private static let venueB = CLLocation(latitude: 43.0372, longitude: -87.9300)

        let cache = RadarBeaconRangingCache()
        let mockPermissions = MockRadarPermissionsHelper()
        let mockBridge = MockRadarSwiftBridge()
        let notificationCenter = NotificationCenter()
        let clock = BeaconRangingTestClock()
        let search = BeaconSearchStub()
        let recorder = BeaconRangingRecorder()

        init() {
            mockBridge.mockIsForeground = true
            mockBridge.mockLastLocation = CLLocation(latitude: 43.03, longitude: -87.93)

            cache.permissionsHelper = mockPermissions
            cache.notificationCenter = notificationCenter
            let clock = clock
            cache.now = { clock.time }
            let search = search
            cache.searchBeacons = { _ in
                search.callCount += 1
                return RadarBeaconRangingCache.constraints(uuids: search.uuids, beacons: [])
            }
            cache.ranger = recorder
        }

        // MARK: - Helpers

        private func withBridge(_ body: () async throws -> Void) async rethrows {
            let original = RadarSwift.bridge
            RadarSwift.bridge = mockBridge
            defer {
                cache.stop()
                RadarSwift.bridge = original
            }
            try await body()
        }

        private func waitUntil(_ condition: () -> Bool) async {
            for _ in 0..<100 where !condition() {
                await Task.yield()
            }
        }

        private func startAndWaitForRanging() async {
            cache.start()
            await waitUntil { cache.ranging }
        }

        private static func entry(rssi: Int, major: String = "1", minor: String = "2") -> RadarBeaconRangingCache.RangedBeacon {
            RadarBeaconRangingCache.RangedBeacon(uuid: testUUID, major: major, minor: minor, rssi: rssi)
        }

        // MARK: - Tests

        @Test("cachedBeacons is nil before start")
        func cachedBeacons_beforeStart_isNil() async {
            await withBridge {
                #expect(cache.cachedBeacons() == nil)
            }
        }

        @Test("start searches beacons and ranges, but is not ready until the first ranging callback")
        func start_rangesButNotWarmedUp() async {
            await withBridge {
                await startAndWaitForRanging()

                #expect(search.callCount == 1)
                #expect(cache.ranging)
                #expect(cache.constraints.count == 1)
                #expect(cache.cachedBeacons() == nil)
            }
        }

        @Test("cachedBeacons is empty, not nil, once warmed up with no beacons in range")
        func cachedBeacons_warmedUpNoBeacons_isEmpty() async {
            await withBridge {
                await startAndWaitForRanging()

                cache.handleRanged([])

                #expect(cache.cachedBeacons()?.isEmpty == true)
            }
        }

        @Test("cachedBeacons returns ranged beacons and drops them after maxBeaconAge")
        func cachedBeacons_expiresStaleBeacons() async {
            await withBridge {
                await startAndWaitForRanging()

                cache.handleRanged([Self.entry(rssi: -60), Self.entry(rssi: -70, minor: "3")])
                #expect(cache.cachedBeacons()?.count == 2)

                clock.time += RadarBeaconRangingCache.maxBeaconAge - 1
                cache.handleRanged([Self.entry(rssi: -62)])

                clock.time += 2
                #expect(cache.cachedBeacons()?.count == 1)

                clock.time += RadarBeaconRangingCache.maxBeaconAge
                #expect(cache.cachedBeacons()?.isEmpty == true)
            }
        }

        @Test("ranged beacons with rssi 0 are ignored")
        func handleRanged_zeroRssi_ignored() async {
            await withBridge {
                await startAndWaitForRanging()

                cache.handleRanged([Self.entry(rssi: 0)])

                #expect(cache.cachedBeacons()?.isEmpty == true)
            }
        }

        @Test("background pauses and clears the cache; foreground resumes and searches again")
        func lifecycle_pausesAndResumes() async {
            await withBridge {
                await startAndWaitForRanging()
                cache.handleRanged([Self.entry(rssi: -60)])

                notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
                await waitUntil { !cache.ranging }

                #expect(!cache.ranging)
                #expect(cache.cachedBeacons() == nil)

                notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
                await waitUntil { search.callCount == 2 }

                #expect(cache.ranging)
                #expect(search.callCount == 2)
                #expect(cache.cachedBeacons() == nil)
            }
        }

        @Test("stop clears state and ignores lifecycle notifications")
        func stop_clearsState() async {
            await withBridge {
                await startAndWaitForRanging()
                cache.handleRanged([Self.entry(rssi: -60)])

                cache.stop()

                #expect(!cache.requested)
                #expect(!cache.ranging)
                #expect(cache.cachedBeacons() == nil)

                notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
                #expect(!cache.ranging)
            }
        }

        @Test("start without location permission does not range")
        func start_notAuthorized_doesNotRange() async {
            await withBridge {
                mockPermissions.mockAuthorizationStatus = .denied

                cache.start()

                #expect(search.callCount == 0)
                #expect(!cache.ranging)
            }
        }

        @Test("start without ranging available does not range")
        func start_rangingUnavailable_doesNotRange() async {
            await withBridge {
                mockPermissions.mockRangingAvailable = false

                cache.start()

                #expect(search.callCount == 0)
                #expect(!cache.ranging)
            }
        }

        @Test("start without a last location ranges once a one-shot request seeds beacons")
        func start_noLocation_rangesAfterUpdate() async {
            await withBridge {
                mockBridge.mockLastLocation = nil

                cache.start()
                #expect(search.callCount == 0)
                #expect(!cache.ranging)

                cache.seedIfNeeded(uuids: [Self.testUUID], beacons: nil)
                #expect(cache.ranging)
            }
        }

        @Test("seedIfNeeded does not replace beacons the cache is already ranging")
        func seedIfNeeded_alreadyRanging_keepsConstraints() async {
            await withBridge {
                await startAndWaitForRanging()
                cache.handleRanged([Self.entry(rssi: -60)])

                cache.seedIfNeeded(uuids: [Self.otherUUID], beacons: nil)

                #expect(cache.constraints.count == 1)
                #expect(cache.constraints.first?.uuid.uuidString == Self.testUUID)
                #expect(cache.cachedBeacons()?.count == 1)
            }
        }

        @Test("constraints prefer UUIDs and otherwise use specific beacons, skipping invalid ones")
        func constraints_builder() {
            let fromUUIDs = RadarBeaconRangingCache.constraints(
                uuids: [Self.testUUID],
                beacons: [.init(uuid: Self.testUUID, major: "1", minor: "2")]
            )
            #expect(fromUUIDs.count == 1)
            #expect(fromUUIDs.first?.major == nil)

            let fromBeacons = RadarBeaconRangingCache.constraints(
                uuids: [],
                beacons: [
                    .init(uuid: Self.testUUID, major: "1", minor: "2"),
                    .init(uuid: "not-a-uuid", major: "1", minor: "2"),
                    .init(uuid: Self.testUUID, major: "x", minor: "2"),
                ]
            )
            #expect(fromBeacons.count == 1)
            #expect(fromBeacons.first?.major == 1)
            #expect(fromBeacons.first?.minor == 2)
        }

        @Test("update stops ranging the previous beacons")
        func update_newBeacons_stopsPreviousBeacons() async {
            await withBridge {
                await startAndWaitForRanging()
                #expect(recorder.active == [Self.testUUID])

                cache.update(constraints: RadarBeaconRangingCache.constraints(uuids: [Self.otherUUID], beacons: []))

                #expect(recorder.active == [Self.otherUUID])
            }
        }

        @Test("stop stops ranging after the beacons changed")
        func stop_afterUpdate_stopsAllRanging() async {
            await withBridge {
                await startAndWaitForRanging()
                cache.update(constraints: RadarBeaconRangingCache.constraints(uuids: [Self.otherUUID], beacons: []))

                cache.stop()

                #expect(recorder.active.isEmpty)
            }
        }

        @Test("update before start is a no-op")
        func update_beforeStart_noop() async {
            await withBridge {
                cache.update(constraints: RadarBeaconRangingCache.constraints(uuids: [Self.testUUID], beacons: []))

                #expect(!cache.ranging)
                #expect(cache.constraints.isEmpty)
            }
        }

        @Test("update with the same beacons keeps the warmed-up cache")
        func update_sameBeacons_keepsCache() async {
            await withBridge {
                await startAndWaitForRanging()
                cache.handleRanged([Self.entry(rssi: -60)])

                cache.update(constraints: RadarBeaconRangingCache.constraints(uuids: [Self.testUUID], beacons: []))

                #expect(cache.cachedBeacons()?.count == 1)
            }
        }
    }
}

// MARK: - Search location

extension RadarSerializedTests.BeaconRangingCacheTests {

    @Test("cachedBeacons(near:) is nil when the beacons were searched from somewhere else")
    func cachedBeaconsNear_farFromSearchLocation_isNil() async {
        await withBridge {
            // Last session's location, near a different venue's beacons.
            mockBridge.mockLastLocation = Self.venueA
            search.uuids = []
            cache.searchBeacons = { _ in
                self.search.callCount += 1
                return RadarBeaconRangingCache.constraints(
                    uuids: nil,
                    beacons: [.init(uuid: Self.testUUID, major: "1", minor: "2")]
                )
            }

            await startAndWaitForRanging()
            // CoreLocation reports empty ranging results for venue A's beacon.
            cache.handleRanged([])

            // trackVerified runs at venue B, 800m away.
            #expect(cache.cachedBeacons(near: Self.venueB) == nil)
        }
    }

    @Test("after moving far away, the next one-shot request re-targets the cache")
    func cachedBeaconsNear_farAway_reseedsFromOneShot() async {
        await withBridge {
            mockBridge.mockLastLocation = Self.venueA
            await startAndWaitForRanging()
            cache.handleRanged([])

            #expect(cache.cachedBeacons(near: Self.venueB) == nil)
            #expect(cache.constraints.isEmpty)
            #expect(recorder.active.isEmpty)

            // trackVerified's own search near venue B returns B's beacons.
            cache.seedIfNeeded(uuids: [Self.otherUUID], beacons: nil)
            #expect(recorder.active == [Self.otherUUID])

            cache.handleRanged([])
            #expect(cache.cachedBeacons(near: Self.venueB)?.isEmpty == true)
        }
    }

    @Test("cachedBeacons(near:) returns cached beacons near the search location")
    func cachedBeaconsNear_nearSearchLocation_returnsBeacons() async {
        await withBridge {
            mockBridge.mockLastLocation = Self.venueA
            await startAndWaitForRanging()
            cache.handleRanged([Self.entry(rssi: -60)])

            let nearby = CLLocation(latitude: Self.venueA.coordinate.latitude + 0.001, longitude: Self.venueA.coordinate.longitude)
            #expect(cache.cachedBeacons(near: nearby)?.count == 1)
        }
    }
}
