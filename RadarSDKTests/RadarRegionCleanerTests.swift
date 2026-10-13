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
        // restores everything afterward. The cleaner reads regions from its own manager and stops them
        // on the RadarLocationManager's manager. Using a fresh RadarLocationManager keeps tests running
        // in parallel from reading the mock through the shared instance. RadarRegionCleaner is global,
        // so cleanups those tests start can still read the cleaner's mock; assert on which manager was
        // read and changed, not exact read counts.
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

            await Self.waitForCleanup()
            RadarRegionCleaner.makeLocationManager = originalMakeLocationManager
            RadarLocationManagerSwiftTestHelpers.clearState()
        }

        // Waits for the main-queue `updateTracking` block, the read on the cleaner's queue, and the
        // main-thread stops, in that order.
        private static func waitForCleanup() async {
            await drainMainQueue()
            RadarRegionCleaner.waitUntilIdle()
            await drainMainQueue()
        }

        @Test("updateTrackingFromInitialize with tracking off reads regions off the main thread and removes them", arguments: [false, true])
        func initializeRemovesRegionsOffMainThread(useSwiftLocationManager: Bool) async {
            await withMockedLocationManagers(useSwiftLocationManager: useSwiftLocationManager) { manager, main, cleaner in
                manager.updateTrackingFromInitialize()
                await Self.waitForCleanup()

                #expect(main.monitoredRegionsReadCount == 0)
                #expect(cleaner.monitoredRegionsReadCount >= 1)
                #expect(!cleaner.monitoredRegionsReadOnMainThread)
                #expect(main.trackedRegions.map(\.identifier) == ["other_region"])
            }
        }

        @Test("updateTrackingFromMeta with tracking off reads regions off the main thread and removes them", arguments: [false, true])
        func metaRemovesRegionsOffMainThread(useSwiftLocationManager: Bool) async {
            await withMockedLocationManagers(useSwiftLocationManager: useSwiftLocationManager) { manager, main, cleaner in
                // With the Swift location manager, config fetches reach `updateTrackingFromInitialize`
                // through `RadarSwift.bridge`. The bridge is global, and the Objective-C tests running
                // in parallel replace it in `Radar.initialize`, so only swap it for this call.
                let originalBridge = RadarSwift.bridge
                if useSwiftLocationManager {
                    let bridge = MockRadarSwiftBridge()
                    bridge.onUpdateTrackingFromInitialize = { manager.updateTrackingFromInitialize() }
                    RadarSwift.bridge = bridge
                }
                manager.updateTracking(from: nil)
                RadarSwift.bridge = originalBridge
                await Self.waitForCleanup()

                #expect(main.monitoredRegionsReadCount == 0)
                #expect(cleaner.monitoredRegionsReadCount >= 1)
                #expect(!cleaner.monitoredRegionsReadOnMainThread)
                #expect(main.trackedRegions.map(\.identifier) == ["other_region"])
            }
        }

        @Test("updateTracking with tracking off still removes Radar regions on the main manager", arguments: [false, true])
        func updateTrackingRemovesRegionsOnMainManager(useSwiftLocationManager: Bool) async {
            await withMockedLocationManagers(useSwiftLocationManager: useSwiftLocationManager) { manager, main, _ in
                manager.updateTracking()
                await Self.waitForCleanup()

                #expect(main.trackedRegions.map(\.identifier) == ["other_region"])
            }
        }

        @Test("The read returns nothing while tracking is on")
        func readSkipsWhileTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            let locationManager = TrackingCLLocationManager()
            locationManager.seed(Self.seededRegions)
            RadarSettings.tracking = true

            #expect(RadarRegionCleaner.radarRegions(locationManager: locationManager) == nil)
            #expect(locationManager.monitoredRegionsReadCount == 0)
        }

        @Test("Regions read before tracking starts are not removed")
        @MainActor
        func stopsSkipWhenTrackingStartsAfterRead() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }
            let cleanerLocationManager = TrackingCLLocationManager()
            let locationManager = TrackingCLLocationManager()
            cleanerLocationManager.seed(Self.seededRegions)
            locationManager.seed(Self.seededRegions)

            let regions = RadarRegionCleaner.radarRegions(locationManager: cleanerLocationManager) ?? []
            // startTracking registers its regions again between the read and the stops.
            RadarSettings.tracking = true
            RadarRegionCleaner.stopMonitoring(regions, locationManager: locationManager)

            #expect(regions.count == 3)
            #expect(locationManager.trackedRegions.count == Self.seededRegions.count)
        }

        @Test("A changed authorization status applies tracking again while tracking", arguments: [false, true])
        func changedAuthorizationAppliesTrackingAgain(useSwiftLocationManager: Bool) async {
            await withMockedLocationManagers(useSwiftLocationManager: useSwiftLocationManager) { manager, locationManager, _ in
                let state = RadarState()
                let originalStatus = state.locationAuthorizationStatus
                let originalBridge = RadarSwift.bridge
                let bridge = MockRadarSwiftBridge()
                RadarSwift.bridge = bridge
                defer {
                    RadarSwift.bridge = originalBridge
                    state.locationAuthorizationStatus = originalStatus
                }
                state.locationAuthorizationStatus = .authorizedWhenInUse
                // Zero update intervals so updateTracking stops updates instead of starting a timer.
                let options = RadarTrackingOptions()
                options.desiredStoppedUpdateInterval = 0
                options.desiredMovingUpdateInterval = 0
                RadarSettings.trackingOptions = options
                RadarSettings.tracking = true

                manager.locationManager(locationManager, didChangeAuthorization: .authorizedAlways)
                await drainMainQueue()

                if useSwiftLocationManager {
                    #expect(bridge.updateTrackingCallCount == 1)
                } else {
                    // The callback writes allowsBackgroundLocationUpdates, then updateTracking writes it again.
                    #expect(locationManager.allowsBackgroundLocationUpdatesWrites.count == 2)
                }
            }
        }

        @Test(
            "The authorization callback sets allowsBackgroundLocationUpdates",
            arguments: [CLAuthorizationStatus.authorizedAlways, .authorizedWhenInUse, .denied]
        )
        func authorizationCallbackSetsBackgroundUpdates(status: CLAuthorizationStatus) async {
            await withMockedLocationManagers { manager, locationManager, _ in
                let state = RadarState()
                let originalStatus = state.locationAuthorizationStatus
                defer { state.locationAuthorizationStatus = originalStatus }
                state.locationAuthorizationStatus = .notDetermined

                manager.locationManager(locationManager, didChangeAuthorization: status)

                let expected = RadarUtils.locationBackgroundMode && status == .authorizedAlways
                #expect(locationManager.allowsBackgroundLocationUpdatesWrites == [expected])
            }
        }

        // Core Location calls the callback with the current status when the manager is created, so on
        // a launch where the permission hasn't changed, the status matches the stored one.
        @Test(
            "The authorization callback sets allowsBackgroundLocationUpdates when the status is unchanged",
            arguments: [false, true]
        )
        func authorizationCallbackSetsBackgroundUpdatesWhenUnchanged(useSwiftLocationManager: Bool) async {
            await withMockedLocationManagers(useSwiftLocationManager: useSwiftLocationManager) { manager, locationManager, _ in
                let state = RadarState()
                let originalStatus = state.locationAuthorizationStatus
                defer { state.locationAuthorizationStatus = originalStatus }
                state.locationAuthorizationStatus = .authorizedAlways

                manager.locationManager(locationManager, didChangeAuthorization: .authorizedAlways)

                #expect(locationManager.allowsBackgroundLocationUpdatesWrites == [RadarUtils.locationBackgroundMode])
            }
        }
    }
}
