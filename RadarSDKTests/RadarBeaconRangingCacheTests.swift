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

extension RadarSerializedTests {

    @Suite("RadarBeaconRangingCache")
    @MainActor
    struct BeaconRangingCacheTests {

        private static let testUUID = "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"

        let cache = RadarBeaconRangingCache()
        let mockPermissions = MockRadarPermissionsHelper()
        let mockBridge = MockRadarSwiftBridge()
        let notificationCenter = NotificationCenter()
        let clock = BeaconRangingTestClock()

        init() {
            mockBridge.mockIsForeground = true
            mockBridge.mockLastLocation = CLLocation(latitude: 43.03, longitude: -87.93)
            mockBridge.mockSearchBeaconUUIDs = [Self.testUUID]

            cache.permissionsHelper = mockPermissions
            cache.notificationCenter = notificationCenter
            let clock = clock
            cache.now = { clock.time }
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

                #expect(mockBridge.searchBeaconsCallCount == 1)
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
                await waitUntil { mockBridge.searchBeaconsCallCount == 2 }

                #expect(cache.ranging)
                #expect(mockBridge.searchBeaconsCallCount == 2)
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

                #expect(mockBridge.searchBeaconsCallCount == 0)
                #expect(!cache.ranging)
            }
        }

        @Test("start without ranging available does not range")
        func start_rangingUnavailable_doesNotRange() async {
            await withBridge {
                mockPermissions.mockRangingAvailable = false

                cache.start()

                #expect(mockBridge.searchBeaconsCallCount == 0)
                #expect(!cache.ranging)
            }
        }

        @Test("start without a last location waits for beacons from trackVerified")
        func start_noLocation_rangesAfterUpdate() async {
            await withBridge {
                mockBridge.mockLastLocation = nil

                cache.start()
                #expect(mockBridge.searchBeaconsCallCount == 0)
                #expect(!cache.ranging)

                cache.update(beacons: nil, uuids: [Self.testUUID])
                #expect(cache.ranging)
            }
        }

        @Test("update before start is a no-op")
        func update_beforeStart_noop() async {
            await withBridge {
                cache.update(beacons: nil, uuids: [Self.testUUID])

                #expect(!cache.ranging)
                #expect(cache.constraints.isEmpty)
            }
        }

        @Test("update with the same beacons keeps the warmed-up cache")
        func update_sameBeacons_keepsCache() async {
            await withBridge {
                await startAndWaitForRanging()
                cache.handleRanged([Self.entry(rssi: -60)])

                cache.update(beacons: nil, uuids: [Self.testUUID])

                #expect(cache.cachedBeacons()?.count == 1)
            }
        }
    }
}
