//
//  RadarBeaconRangingCacheSearchLocationTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing
import UIKit

@testable import RadarSDK

extension RadarSerializedTests.BeaconRangingCacheTests {

    @Test("cachedBeacons(near:) is nil when the beacons were searched from somewhere else")
    func cachedBeaconsNear_farFromSearchLocation_isNil() async {
        await withBridge {
            // Last session's location, near a different venue's beacons.
            mockBridge.mockLastLocation = Self.venueA
            cache.searchBeacons = { _ in
                .init(uuids: [], beacons: [.init(uuid: Self.testUUID, major: "1", minor: "2")])
            }

            await startAndWaitForRanging()
            // CoreLocation reports empty ranging results for venue A's beacon.
            cache.handleRanged([])

            // trackVerified runs at venue B, about 1.7km away.
            #expect(cache.cachedBeacons(near: Self.venueB) == nil)
        }
    }

    @Test("after moving far away, the next one-shot request re-targets the cache")
    func cachedBeaconsNear_farAway_reseedsFromOneShot() async {
        await withBridge {
            mockBridge.mockLastLocation = Self.venueA
            cache.searchBeacons = { _ in
                .init(uuids: [], beacons: [.init(uuid: Self.testUUID, major: "1", minor: "2")])
            }
            await startAndWaitForRanging()
            cache.handleRanged([])

            #expect(cache.cachedBeacons(near: Self.venueB) == nil)
            #expect(cache.constraints.isEmpty)
            #expect(rangedUUIDs.isEmpty)

            // trackVerified's own search near venue B returns B's beacons.
            cache.seedIfNeeded(uuids: [Self.otherUUID], beacons: nil)
            #expect(rangedUUIDs == [Self.otherUUID])

            cache.handleRanged([])
            #expect(cache.cachedBeacons(near: Self.venueB)?.isEmpty == true)
        }
    }

    @Test("cachedBeacons(near:) is nil when a full search result can't cover the user's location")
    func cachedBeaconsNear_truncatedSearch_isNil() async {
        await withBridge {
            // A large venue: the search returns its limit of 10 beacons, all within ~50m of the
            // search location. Beacons farther away weren't returned.
            mockBridge.mockLastLocation = Self.venueA
            cache.searchBeacons = { _ in
                .init(
                    uuids: [],
                    beacons: (0..<RadarBeaconRangingCache.searchLimit).map {
                        .init(
                            uuid: Self.testUUID, major: "1", minor: "\($0)",
                            location: CLLocation(
                                latitude: Self.venueA.coordinate.latitude + Double($0) * 0.00005,
                                longitude: Self.venueA.coordinate.longitude
                            )
                        )
                    }
                )
            }
            await startAndWaitForRanging()
            cache.handleRanged([])

            // The user walks 200m across the venue, out of range of every returned beacon.
            let acrossVenue = CLLocation(latitude: Self.venueA.coordinate.latitude + 0.0018, longitude: Self.venueA.coordinate.longitude)
            #expect(cache.cachedBeacons(near: acrossVenue) == nil)
        }
    }

    @Test("cachedBeacons(near:) keeps UUID ranging wherever the device is")
    func cachedBeaconsNear_uuids_coverEverywhere() async {
        await withBridge {
            mockBridge.mockLastLocation = Self.venueA
            await startAndWaitForRanging()
            cache.handleRanged([Self.entry(rssi: -60)])

            #expect(cache.cachedBeacons(near: Self.venueB)?.count == 1)
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

    @Test("a stale foreground search doesn't overwrite a re-targeted cache")
    func staleSearch_afterRetarget_isIgnored() async {
        await withBridge {
            mockBridge.mockLastLocation = Self.venueA
            let venueASearch = RadarBeaconRangingCache.SearchResult(
                uuids: [],
                beacons: [.init(uuid: Self.testUUID, major: "1", minor: "2")]
            )
            cache.searchBeacons = { _ in venueASearch }
            await startAndWaitForRanging()
            cache.handleRanged([])

            // Background, then foreground: the new search from the stale venue A location is
            // still running.
            notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
            await waitUntil { !cache.ranging }
            var finishSearch: CheckedContinuation<Void, Never>?
            cache.searchBeacons = { _ in
                await withCheckedContinuation { finishSearch = $0 }
                return venueASearch
            }
            notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
            await waitUntil { finishSearch != nil }

            // trackVerified at venue B re-targets the cache, and its own search seeds B's beacons.
            #expect(cache.cachedBeacons(near: Self.venueB) == nil)
            cache.seedIfNeeded(uuids: [Self.otherUUID], beacons: nil)
            #expect(rangedUUIDs == [Self.otherUUID])

            // Then the stale venue A search finishes.
            finishSearch?.resume()
            await waitUntil { cache.searchLocation != Self.venueB }

            #expect(cache.searchLocation == Self.venueB)
            #expect(rangedUUIDs == [Self.otherUUID])
        }
    }
}
