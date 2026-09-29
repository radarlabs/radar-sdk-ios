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

extension RadarSerializedTests {

    @Suite("RadarBeaconRangingCache")
    @MainActor
    struct BeaconRangingCacheTests {

        static let testUUID = "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"
        static let otherUUID = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
        static let venueA = CLLocation(latitude: 43.0300, longitude: -87.9300)
        static let venueB = CLLocation(latitude: 43.0450, longitude: -87.9300)

        let cache = RadarBeaconRangingCache()
        let mockPermissions = MockRadarPermissionsHelper()
        let mockBridge = MockRadarSwiftBridge()
        let notificationCenter = NotificationCenter()

        init() {
            mockBridge.mockIsForeground = true
            mockBridge.mockLastLocation = CLLocation(latitude: 43.03, longitude: -87.93)

            cache.permissionsHelper = mockPermissions
            cache.notificationCenter = notificationCenter
            cache.now = { 1000 }
            cache.searchBeacons = { _ in
                .init(uuids: [Self.testUUID], beacons: [])
            }
        }

        // MARK: - Helpers

        func withBridge(_ body: () async throws -> Void) async rethrows {
            let original = RadarSwift.bridge
            RadarSwift.bridge = mockBridge
            defer {
                cache.stop()
                RadarSwift.bridge = original
            }
            try await body()
        }

        func waitUntil(_ condition: () -> Bool) async {
            for _ in 0..<100 where !condition() {
                await Task.yield()
            }
        }

        /// UUIDs CoreLocation is currently ranging for the cache.
        var rangedUUIDs: Set<String> {
            Set(cache.locationManager.rangedBeaconConstraints.map(\.uuid.uuidString))
        }

        func startAndWaitForRanging() async {
            cache.start()
            await waitUntil { cache.ranging }
        }

        static func entry(rssi: Int, major: String = "1", minor: String = "2") -> RadarBeaconRangingCache.RangedBeacon {
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

                #expect(cache.searchLocation == mockBridge.mockLastLocation)
                #expect(cache.ranging)
                #expect(rangedUUIDs == [Self.testUUID])
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

                cache.now = { 1000 + RadarBeaconRangingCache.maxBeaconAge - 1 }
                cache.handleRanged([Self.entry(rssi: -62)])

                cache.now = { 1000 + RadarBeaconRangingCache.maxBeaconAge + 1 }
                #expect(cache.cachedBeacons()?.count == 1)

                cache.now = { 1000 + 2 * RadarBeaconRangingCache.maxBeaconAge }
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
                #expect(rangedUUIDs.isEmpty)
                #expect(cache.cachedBeacons() == nil)

                // The new search on foreground finds different beacons.
                cache.searchBeacons = { _ in
                    .init(uuids: [Self.otherUUID], beacons: [])
                }
                notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
                await waitUntil { rangedUUIDs == [Self.otherUUID] }

                #expect(cache.ranging)
                #expect(rangedUUIDs == [Self.otherUUID])
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
                #expect(rangedUUIDs.isEmpty)
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
                await waitUntil { cache.searchLocation != nil }

                #expect(cache.searchLocation == nil)
                #expect(!cache.ranging)
            }
        }

        @Test("start without ranging available does not range")
        func start_rangingUnavailable_doesNotRange() async {
            await withBridge {
                mockPermissions.mockRangingAvailable = false

                cache.start()
                await waitUntil { cache.searchLocation != nil }

                #expect(cache.searchLocation == nil)
                #expect(!cache.ranging)
            }
        }

        @Test("start without a last location ranges once a one-shot request seeds beacons")
        func start_noLocation_rangesAfterUpdate() async {
            await withBridge {
                mockBridge.mockLastLocation = nil

                cache.start()
                await waitUntil { cache.searchLocation != nil }
                #expect(cache.searchLocation == nil)
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
            let fromUUIDs = RadarBeaconRangingCache.SearchResult(
                uuids: [Self.testUUID],
                beacons: [.init(uuid: Self.testUUID, major: "1", minor: "2")]
            ).constraints
            #expect(fromUUIDs.count == 1)
            #expect(fromUUIDs.first?.major == nil)

            let fromBeacons = RadarBeaconRangingCache.SearchResult(
                uuids: [],
                beacons: [
                    .init(uuid: Self.testUUID, major: "1", minor: "2"),
                    .init(uuid: "not-a-uuid", major: "1", minor: "2"),
                    .init(uuid: Self.testUUID, major: "x", minor: "2"),
                ]
            ).constraints
            #expect(fromBeacons.count == 1)
            #expect(fromBeacons.first?.major == 1)
            #expect(fromBeacons.first?.minor == 2)
        }

        @Test("update stops ranging the previous beacons")
        func update_newBeacons_stopsPreviousBeacons() async {
            await withBridge {
                await startAndWaitForRanging()
                #expect(rangedUUIDs == [Self.testUUID])

                cache.update(.init(uuids: [Self.otherUUID], beacons: []))

                #expect(rangedUUIDs == [Self.otherUUID])
            }
        }

        @Test("stop stops ranging after the beacons changed")
        func stop_afterUpdate_stopsAllRanging() async {
            await withBridge {
                await startAndWaitForRanging()
                cache.update(.init(uuids: [Self.otherUUID], beacons: []))

                cache.stop()

                #expect(rangedUUIDs.isEmpty)
            }
        }

        @Test("update before start is a no-op")
        func update_beforeStart_noop() async {
            await withBridge {
                cache.update(.init(uuids: [Self.testUUID], beacons: []))

                #expect(!cache.ranging)
                #expect(cache.constraints.isEmpty)
            }
        }

        @Test("update with the same beacons keeps the warmed-up cache")
        func update_sameBeacons_keepsCache() async {
            await withBridge {
                await startAndWaitForRanging()
                cache.handleRanged([Self.entry(rssi: -60)])

                cache.update(.init(uuids: [Self.testUUID], beacons: []))

                #expect(cache.cachedBeacons()?.count == 1)
            }
        }
    }
}
