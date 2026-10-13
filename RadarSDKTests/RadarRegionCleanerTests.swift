//
//  RadarRegionCleanerTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension RadarRegionCleaner {
    // Blocks until every queued cleanup has finished.
    static func waitUntilIdle() {
        queue.sync {}
    }
}

private func drainMainQueue() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            continuation.resume()
        }
    }
}

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarRegionCleanerTests {

        private static let seededRegions = ["radar_geofence_a", "radar_bubble_b", "radar_beacon_c", "other_region"]

        // Gives a fresh RadarLocationManager a mock manager and installs another as RadarRegionCleaner's
        // manager, seeds both with the same regions (monitored regions are shared app-wide), and
        // restores everything afterward. Using a fresh RadarLocationManager keeps tests running in
        // parallel from reading the mock through the shared instance. RadarRegionCleaner is global,
        // so cleanups those tests start can still use the mock; assert on its contents, not exact
        // read counts.
        private func withMockedLocationManagers(
            useSwiftLocationManager: Bool = false,
            _ body: (RadarLocationManager, TrackingCLLocationManager, TrackingCLLocationManager) async -> Void
        ) async {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager()
            let originalMakeLocationManager = RadarRegionCleaner.makeLocationManager
            let locationManager = TrackingCLLocationManager()
            let cleanerLocationManager = TrackingCLLocationManager()
            locationManager.seed(Self.seededRegions)
            cleanerLocationManager.seed(Self.seededRegions)
            manager.locationManager = locationManager
            RadarRegionCleaner.makeLocationManager = { cleanerLocationManager }
            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": useSwiftLocationManager])

            await body(manager, locationManager, cleanerLocationManager)

            RadarRegionCleaner.waitUntilIdle()
            RadarRegionCleaner.makeLocationManager = originalMakeLocationManager
            RadarLocationManagerSwiftTestHelpers.clearState()
        }

        @Test("updateTrackingFromInitialize with tracking off removes Radar regions off the main thread", arguments: [false, true])
        func initializeRemovesRegionsOffMainThread(useSwiftLocationManager: Bool) async {
            await withMockedLocationManagers(useSwiftLocationManager: useSwiftLocationManager) { manager, main, cleaner in
                manager.updateTrackingFromInitialize()
                await drainMainQueue()
                RadarRegionCleaner.waitUntilIdle()

                #expect(main.monitoredRegionsReadCount == 0)
                #expect(cleaner.monitoredRegionsReadCount >= 1)
                #expect(!cleaner.monitoredRegionsReadOnMainThread)
                #expect(cleaner.trackedRegions.map(\.identifier) == ["other_region"])
            }
        }

        @Test("updateTrackingFromMeta with tracking off removes Radar regions off the main thread", arguments: [false, true])
        func metaRemovesRegionsOffMainThread(useSwiftLocationManager: Bool) async {
            await withMockedLocationManagers(useSwiftLocationManager: useSwiftLocationManager) { manager, main, cleaner in
                manager.updateTracking(from: nil)
                await drainMainQueue()
                RadarRegionCleaner.waitUntilIdle()

                #expect(main.monitoredRegionsReadCount == 0)
                #expect(!cleaner.monitoredRegionsReadOnMainThread)
                #expect(cleaner.trackedRegions.map(\.identifier) == ["other_region"])
            }
        }

        @Test("updateTracking with tracking off still removes Radar regions on the main manager", arguments: [false, true])
        func updateTrackingRemovesRegionsOnMainManager(useSwiftLocationManager: Bool) async {
            await withMockedLocationManagers(useSwiftLocationManager: useSwiftLocationManager) { manager, main, _ in
                manager.updateTracking()
                await drainMainQueue()
                RadarRegionCleaner.waitUntilIdle()

                #expect(main.trackedRegions.map(\.identifier) == ["other_region"])
            }
        }

        @Test("The cleanup does nothing while tracking is on")
        func cleanupSkipsWhileTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            let locationManager = TrackingCLLocationManager()
            locationManager.seed(Self.seededRegions)
            RadarSettings.tracking = true

            RadarRegionCleaner.removeAllRegions(locationManager: locationManager)

            #expect(locationManager.monitoredRegionsReadCount == 0)
            #expect(locationManager.trackedRegions.count == Self.seededRegions.count)
        }

        @Test("The cleanup stops when tracking starts partway through")
        func cleanupStopsWhenTrackingStarts() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            let locationManager = TrackingCLLocationManager()
            locationManager.seed(Self.seededRegions)
            locationManager.onStopMonitoring = { _ in
                RadarSettings.tracking = true
            }

            RadarRegionCleaner.removeAllRegions(locationManager: locationManager)

            let radarRegions = locationManager.trackedRegions.filter { $0.identifier.hasPrefix("radar_") }
            #expect(radarRegions.count == 2)
        }

        @Test("The authorization callback sets allowsBackgroundLocationUpdates", arguments: [CLAuthorizationStatus.authorizedAlways, .authorizedWhenInUse, .denied])
        func authorizationCallbackSetsBackgroundUpdates(status: CLAuthorizationStatus) async {
            await withMockedLocationManagers { manager, locationManager, _ in
                let state = RadarState()
                let originalStatus = state.locationAuthorizationStatus
                defer { state.locationAuthorizationStatus = originalStatus }

                manager.locationManager(locationManager, didChangeAuthorization: status)

                let expected = RadarUtils.locationBackgroundMode && status == .authorizedAlways
                #expect(locationManager.allowsBackgroundLocationUpdates == expected)
            }
        }
    }
}
