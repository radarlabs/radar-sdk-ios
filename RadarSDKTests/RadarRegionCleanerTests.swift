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

        // Installs a mock as RadarRegionCleaner's manager and as the shared RadarLocationManager's
        // manager, seeds both with the same regions (monitored regions are shared app-wide), and
        // restores everything afterward.
        private func withMockedLocationManagers(
            useSwiftLocationManager: Bool = false,
            _ body: (RadarLocationManager, TrackingCLLocationManager, TrackingCLLocationManager) async -> Void
        ) async {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let manager = RadarLocationManager.sharedInstance()
            let originalLocationManager = manager.locationManager
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
            manager.locationManager = originalLocationManager
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
                #expect(cleaner.monitoredRegionsReadCount == 1)
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
            await withMockedLocationManagers(useSwiftLocationManager: useSwiftLocationManager) { manager, main, cleaner in
                manager.updateTracking()
                await drainMainQueue()
                RadarRegionCleaner.waitUntilIdle()

                #expect(main.trackedRegions.map(\.identifier) == ["other_region"])
                #expect(cleaner.monitoredRegionsReadCount == 0)
            }
        }

        @Test("The cleanup does nothing while tracking is on")
        func cleanupSkipsWhileTracking() async {
            await withMockedLocationManagers { _, _, cleanerLocationManager in
                RadarSettings.tracking = true

                RadarRegionCleaner.removeAllRegionsInBackground()
                RadarRegionCleaner.waitUntilIdle()

                #expect(cleanerLocationManager.monitoredRegionsReadCount == 0)
                #expect(cleanerLocationManager.trackedRegions.count == Self.seededRegions.count)
            }
        }

        @Test("The cleanup stops when tracking starts partway through")
        func cleanupStopsWhenTrackingStarts() async {
            await withMockedLocationManagers { _, _, cleanerLocationManager in
                cleanerLocationManager.onStopMonitoring = { _ in
                    RadarSettings.tracking = true
                }

                RadarRegionCleaner.removeAllRegionsInBackground()
                RadarRegionCleaner.waitUntilIdle()

                let radarRegions = cleanerLocationManager.trackedRegions.filter { $0.identifier.hasPrefix("radar_") }
                #expect(radarRegions.count == 2)
            }
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
