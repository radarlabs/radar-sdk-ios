//
//  RadarContinuousBeaconManagerRangingTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing
import UIKit

@testable import RadarSDK

extension RadarSerializedTests.ContinuousBeaconManagerTests {

    // MARK: - Ranging

    @Test("ranged beacons with rssi 0 are ignored")
    func handleRanged_zeroRssi_isIgnored() async {
        await withBridge {
            await startAndWarmUp()

            manager.handleRanged([Self.entry(rssi: 0)])

            #expect(manager.beacons(near: Self.venueA)?.isEmpty == true)
        }
    }

    @Test("start without location permission doesn't search or range")
    func start_withoutPermissions_doesNotRange() async {
        await withBridge {
            mockPermissions.mockAuthorizationStatus = .denied

            manager.start()
            await settle()

            #expect(fakeSearch.locations.isEmpty)
            #expect(!manager.ranging)
        }
    }

    @Test("start without ranging available doesn't search or range")
    func start_rangingNotAvailable_doesNotRange() async {
        await withBridge {
            mockPermissions.mockRangingAvailable = false

            manager.start()
            await settle()

            #expect(fakeSearch.locations.isEmpty)
            #expect(!manager.ranging)
        }
    }

    @Test("update with the same beacons doesn't restart ranging")
    func update_sameBeacons_doesNotRestartRanging() async {
        await withBridge {
            await startAndWarmUp()
            manager.handleRanged([Self.entry(rssi: -60)])

            manager.onSearched(from: Self.venueA, result: Self.uuidResult(Self.testUUID))

            #expect(manager.beacons(near: Self.venueA)?.count == 1)
        }
    }

    @Test("a failed search doesn't range")
    func search_failed_doesNotRange() async {
        await withBridge {
            fakeSearch.result = nil

            manager.start()
            await waitUntil { sleeper.pendingCount > 0 }

            #expect(fakeSearch.locations.count == 1)
            #expect(!manager.ranging)
        }
    }

    @Test("constraints prefer UUIDs and otherwise use specific beacons, skipping invalid ones")
    func constraints_preferUUIDsAndSkipInvalidBeacons() {
        let fromUUIDs = RadarContinuousBeaconManager.SearchResult(
            uuids: [Self.testUUID],
            beacons: [.init(uuid: Self.testUUID, major: "1", minor: "2")]
        ).constraints
        #expect(fromUUIDs.count == 1)
        #expect(fromUUIDs.first?.major == nil)

        let fromBeacons = RadarContinuousBeaconManager.SearchResult(
            uuids: [],
            beacons: [
                .init(uuid: Self.testUUID, major: "1", minor: "2"),
                .init(uuid: "not-a-uuid", major: "1", minor: "2"),
                .init(uuid: Self.testUUID, major: "x", minor: "2"),
                // An Eddystone beacon from the Objective-C search.
                .init(uuid: "", major: "", minor: ""),
            ]
        ).constraints
        #expect(fromBeacons.count == 1)
        #expect(fromBeacons.first?.major == 1)
        #expect(fromBeacons.first?.minor == 2)
    }

    @Test("rangingUnavailable pauses ranging, and the next refresh resumes it")
    func rangingUnavailable_pausesUntilRefresh() async {
        await withBridge {
            await startAndWaitForRanging()

            manager.handleRangingFailed(Self.rangingUnavailableKey(Self.testUUID), error: CLError(.rangingUnavailable))
            #expect(!manager.ranging)
            #expect(rangedUUIDs.isEmpty)

            await fireRefresh()
            await waitUntil { manager.ranging }

            #expect(rangedUUIDs == [Self.testUUID])
        }
    }

    @Test("rangingUnavailable pauses ranging, and the caller's search resumes it")
    func rangingUnavailable_pausesUntilCallersSearch() async {
        await withBridge {
            await startAndWarmUp()

            manager.handleRangingFailed(Self.rangingUnavailableKey(Self.testUUID), error: CLError(.rangingUnavailable))

            #expect(manager.beacons(near: Self.venueA) == nil)
            manager.onSearched(from: Self.venueA, result: Self.uuidResult(Self.testUUID))
            #expect(rangedUUIDs == [Self.testUUID])
        }
    }

    @Test("other ranging failures, or failures for beacons not being ranged, don't pause")
    func rangingFailed_otherErrorsOrConstraints_doNotPause() async {
        await withBridge {
            await startAndWaitForRanging()

            manager.handleRangingFailed(Self.rangingUnavailableKey(Self.testUUID), error: CLError(.rangingFailure))
            manager.handleRangingFailed(Self.rangingUnavailableKey(Self.otherUUID), error: CLError(.rangingUnavailable))

            #expect(manager.ranging)
        }
    }

    // MARK: - Searches

    @Test("a startup search that returns after the caller's search is ignored")
    func startupSearch_returningAfterCallersSearch_isIgnored() async {
        await withBridge {
            fakeSearch.holds = true
            manager.start()
            await waitUntil { fakeSearch.locations.count == 1 }

            manager.onSearched(from: Self.venueB, result: Self.uuidResult(Self.otherUUID))
            fakeSearch.finishPending()
            await settle()

            #expect(rangedUUIDs == [Self.otherUUID])
            #expect(manager.searchLocation == Self.venueB)
        }
    }

    @Test("a failed caller's search schedules a refresh")
    func onSearched_failed_schedulesRefresh() async {
        await withBridge {
            mockBridge.mockLastLocation = nil
            manager.start()

            manager.onSearched(from: Self.venueA, result: nil)

            #expect(await lastRefreshDelay() == RadarContinuousBeaconManager.refreshInterval)
            #expect(!manager.ranging)
        }
    }

    @Test("onSearched before start is ignored")
    func onSearched_notStarted_isIgnored() async {
        await withBridge {
            manager.onSearched(from: Self.venueA, result: Self.uuidResult(Self.testUUID))

            #expect(!manager.ranging)
            #expect(manager.searchResult == nil)
            #expect(sleeper.delays.isEmpty)
        }
    }

    @Test("the Objective-C search result is used only when it succeeded")
    func handleSearch_mapsStatus() async {
        #expect(RadarContinuousBeaconManager.SearchResult(status: .errorServer, uuids: [Self.testUUID], beacons: nil) == nil)
        #expect(RadarContinuousBeaconManager.SearchResult(status: .success, uuids: nil, beacons: nil)?.constraints.isEmpty == true)

        await withBridge {
            mockBridge.mockLastLocation = nil
            manager.start()

            manager.handleSearch(from: Self.venueA, status: .success, beaconUUIDs: [Self.testUUID], beacons: nil)

            #expect(rangedUUIDs == [Self.testUUID])
            #expect(manager.searchLocation == Self.venueA)
        }
    }

    // MARK: - Refreshes

    @Test("a refresh after the interval searches again from the last location")
    func refresh_afterInterval_searchesAgainFromLastLocation() async {
        await withBridge {
            await startAndWaitForRanging()
            #expect(await lastRefreshDelay() == RadarContinuousBeaconManager.refreshInterval)

            mockBridge.mockLastLocation = Self.nearVenueA
            await fireRefresh()
            await waitUntil { fakeSearch.locations.count == 2 }

            #expect(fakeSearch.locations.last == Self.nearVenueA)
            #expect(manager.searchLocation == Self.nearVenueA)
        }
    }

    @Test("a refresh after a failed search retries")
    func refresh_afterFailedSearch_retries() async {
        await withBridge {
            fakeSearch.result = nil
            manager.start()
            await waitUntil { sleeper.pendingCount > 0 }

            fakeSearch.result = Self.uuidResult(Self.testUUID)
            await fireRefresh()
            await waitUntil { manager.ranging }

            #expect(fakeSearch.locations.count == 2)
            #expect(rangedUUIDs == [Self.testUUID])
        }
    }

    @Test("a refresh in the background or after stop doesn't search")
    func refresh_inBackgroundOrAfterStop_doesNotSearch() async {
        await withBridge {
            await startAndWaitForRanging()

            mockBridge.mockIsForeground = false
            await fireRefresh()
            await settle()
            #expect(fakeSearch.locations.count == 1)

            mockBridge.mockIsForeground = true
            manager.onSearched(from: Self.venueA, result: Self.uuidResult(Self.testUUID))
            manager.stop()
            await fireRefresh()
            await settle()
            #expect(fakeSearch.locations.count == 1)
        }
    }

    // MARK: - Lifecycle

    @Test("background pauses; foreground resumes, and searches again once the interval has passed")
    func lifecycle_backgroundPausesAndForegroundResumes() async {
        await withBridge {
            await startAndWaitForRanging()
            manager.handleRanged([Self.entry(rssi: -60)])

            notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
            await waitUntil { !manager.ranging }
            #expect(!manager.ranging)
            #expect(rangedUUIDs.isEmpty)

            // Back within the refresh interval: ranges the last search's beacons without searching.
            clock.time += 10
            let refreshCount = sleeper.delays.count
            notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
            await waitUntil { manager.ranging }
            #expect(rangedUUIDs == [Self.testUUID])
            await waitUntil { sleeper.delays.count > refreshCount }
            #expect(sleeper.delays.last == RadarContinuousBeaconManager.refreshInterval - 10)
            await settle()
            #expect(fakeSearch.locations.count == 1)

            // Back after the refresh interval: searches again.
            notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
            await waitUntil { !manager.ranging }
            clock.time += RadarContinuousBeaconManager.refreshInterval
            fakeSearch.result = Self.uuidResult(Self.otherUUID)
            notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
            await waitUntil { rangedUUIDs == [Self.otherUUID] }

            #expect(fakeSearch.locations.count == 2)
            #expect(rangedUUIDs == [Self.otherUUID])
        }
    }

    @Test("stop stops ranging, clears the result, and ignores lifecycle notifications")
    func stop_stopsRangingAndIgnoresLifecycle() async {
        await withBridge {
            await startAndWaitForRanging()

            manager.stop()

            #expect(!manager.started)
            #expect(!manager.ranging)
            #expect(rangedUUIDs.isEmpty)
            #expect(manager.searchResult == nil)
            #expect(manager.beacons(near: Self.venueA) == nil)

            notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
            await settle()
            #expect(!manager.ranging)
            #expect(fakeSearch.locations.count == 1)
        }
    }

    @Test("stop invalidates a running search")
    func stop_invalidatesRunningSearch() async {
        await withBridge {
            fakeSearch.holds = true
            manager.start()
            await waitUntil { fakeSearch.locations.count == 1 }

            manager.stop()
            fakeSearch.finishPending()
            await settle()

            #expect(!manager.ranging)
            #expect(manager.searchResult == nil)
        }
    }
}
