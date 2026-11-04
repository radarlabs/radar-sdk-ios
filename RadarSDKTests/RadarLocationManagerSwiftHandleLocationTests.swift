//
//  RadarLocationManagerSwiftHandleLocationTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

enum HandleLocationFixtures {
    static let origin = CLLocationCoordinate2D(latitude: 40.7, longitude: -73.9)

    static func location(
        latitude: Double = origin.latitude,
        longitude: Double = origin.longitude,
        horizontalAccuracy: CLLocationAccuracy = 10,
        timestamp: Date = Date()
    ) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: 10,
            timestamp: timestamp
        )
    }

    /// Moving options with stop detection on, so `handleLocation` runs the stop calculation.
    static func trackingOptions(
        syncLocations: RadarTrackingOptionsSyncLocations = .all,
        replay: RadarTrackingOptionsReplay = .none,
        desiredSyncInterval: Int32 = 0
    ) -> RadarTrackingOptions {
        let options = RadarTrackingOptions.presetResponsive
        options.stopDistance = 70
        options.stopDuration = 140
        options.desiredStoppedUpdateInterval = 0
        options.desiredSyncInterval = desiredSyncInterval
        options.syncLocations = syncLocations
        options.replay = replay
        options.beacons = false
        return options
    }

    /// The `RadarState` keys `handleLocation` reads and writes.
    static let stateKeys = [
        "radar-lastLocation", "radar-lastMovedLocation", "radar-lastMovedAt", "radar-stopped",
        "radar-lastSentAt", "radar-canExit", "radar-lastFailedStoppedLocation",
    ]

    /// `handleLocation` calls `updateTracking:`, which dispatches to the main queue. Let that work
    /// run while this test's settings are still in place, so it can't act on the next test's state.
    /// The second hop covers main-actor work the first round schedules.
    @MainActor
    static func drainMainQueue() async {
        for _ in 0..<2 {
            await withCheckedContinuation { continuation in
                DispatchQueue.main.async { continuation.resume() }
            }
        }
    }

    static func clearRadarState() {
        for key in stateKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarHandleLocationSwiftTests {

        // MARK: - Early exits

        @Test("an invalid location fails the waiting location requests and is not sent")
        func invalidLocationFailsCompletionHandlers() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()
                let host = TrackingRadarLocationManagerHost()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(horizontalAccuracy: -1), source: .backgroundLocation,
                    beacons: nil)

                #expect(host.cancelTimeoutsCallCount == 1)
                #expect(host.completionStatuses == [.errorLocation])
                #expect(host.sentLocations.isEmpty)
                #expect(bridge.lastLocation() == nil)
            }
        }

        @Test("an inaccurate location while stopped updates tracking and is not sent")
        func inaccurateLocationWhileStoppedOnlyUpdatesTracking() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()
                bridge.mockStopped = true
                let host = TrackingRadarLocationManagerHost()
                let location = HandleLocationFixtures.location(horizontalAccuracy: 1500)

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: location, source: .backgroundLocation, beacons: nil)

                #expect(host.updateTrackingLocations.count == 1)
                #expect(host.updateTrackingLocations.first??.timestamp == location.timestamp)
                #expect(host.completionStatuses.isEmpty)
                #expect(host.sentLocations.isEmpty)
                #expect(bridge.lastLocation() == nil)
            }
        }

        @Test("a background location is skipped when tracking is off")
        func backgroundLocationSkippedWhenNotTracking() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = false
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()
                let host = TrackingRadarLocationManagerHost()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(), source: .backgroundLocation, beacons: nil)

                #expect(host.sentLocations.isEmpty)
                #expect(host.completionStatuses.isEmpty)
                #expect(bridge.lastLocation() == nil)
                #expect(bridge.lastSentAt() == nil)
            }
        }

        @Test("a manual location is sent even when tracking is off")
        func manualLocationSentWhenNotTracking() throws {
            try RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = false
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()
                let host = TrackingRadarLocationManagerHost()
                let location = HandleLocationFixtures.location()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: location, source: .manualLocation, beacons: nil)

                let sent = try #require(host.sentLocations.first)
                #expect(host.sentLocations.count == 1)
                #expect(sent.location === location)
                #expect(sent.source == .manualLocation)
                #expect(sent.forceTrack)
                #expect(!sent.replayed)
                // Manual locations don't restart tracking.
                #expect(host.updateTrackingLocations.isEmpty)
                #expect(host.completionStatuses == [.success])
                #expect(bridge.lastLocation() === location)
                #expect(bridge.lastSentAt() != nil)
            }
        }

        @Test("a foreground location updates state but is not sent")
        func foregroundLocationIsNotSent() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()
                let host = TrackingRadarLocationManagerHost()
                let location = HandleLocationFixtures.location()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: location, source: .foregroundLocation, beacons: nil)

                #expect(host.sentLocations.isEmpty)
                #expect(host.updateTrackingLocations.count == 1)
                #expect(host.completionStatuses == [.success])
                #expect(bridge.lastClientLocation === location)
                #expect(bridge.lastLocation() === location)
                #expect(bridge.lastSentAt() != nil)
            }
        }

        // MARK: - Stop detection

        @Test("the first location records where and when the device last moved")
        func firstLocationRecordsLastMoved() throws {
            try RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()
                let host = TrackingRadarLocationManagerHost()
                let location = HandleLocationFixtures.location()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: location, source: .backgroundLocation, beacons: [])

                #expect(bridge.lastMovedLocation() === location)
                #expect(bridge.lastMovedAt() == location.timestamp)
                #expect(!bridge.isStopped())
                let sent = try #require(host.sentLocations.first)
                #expect(!sent.stopped)
                #expect(sent.beacons?.isEmpty == true)
            }
        }

        @Test("staying within the stop distance for the stop duration marks the device stopped and sends")
        func stayingPutMarksStopped() throws {
            try RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions(desiredSyncInterval: 600)
                let movedAt = Date().addingTimeInterval(-300)
                bridge.mockLastMovedLocation = HandleLocationFixtures.location(timestamp: movedAt)
                bridge.mockLastMovedAt = movedAt
                // A recent send would normally hit the sync interval, but `justStopped` ignores it.
                bridge.mockLastSentAt = Date()
                let host = TrackingRadarLocationManagerHost()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(), source: .backgroundLocation, beacons: nil)

                #expect(bridge.isStopped())
                #expect(bridge.lastMovedAt() == movedAt)
                let sent = try #require(host.sentLocations.first)
                #expect(sent.stopped)
            }
        }

        @Test("moving beyond the stop distance resets where and when the device last moved")
        func movingResetsLastMoved() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()
                let movedAt = Date().addingTimeInterval(-300)
                bridge.mockLastMovedLocation = HandleLocationFixtures.location(timestamp: movedAt)
                bridge.mockLastMovedAt = movedAt
                let host = TrackingRadarLocationManagerHost()
                let location = HandleLocationFixtures.location(latitude: HandleLocationFixtures.origin.latitude + 0.01)

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: location, source: .backgroundLocation, beacons: nil)

                #expect(!bridge.isStopped())
                #expect(bridge.lastMovedLocation() === location)
                #expect(bridge.lastMovedAt() == location.timestamp)
            }
        }

        @Test("a location older than the last move is skipped")
        func oldLocationSkipped() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()
                let movedAt = Date()
                bridge.mockLastMovedLocation = HandleLocationFixtures.location(timestamp: movedAt)
                bridge.mockLastMovedAt = movedAt
                let host = TrackingRadarLocationManagerHost()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(timestamp: movedAt.addingTimeInterval(-60)),
                    source: .backgroundLocation, beacons: nil)

                #expect(host.sentLocations.isEmpty)
                #expect(host.completionStatuses.isEmpty)
                #expect(bridge.lastLocation() == nil)
            }
        }

        // MARK: - Seam

        @Test("the Objective-C and Swift paths leave the same location state for a foreground location")
        @MainActor
        func objcAndSwiftPathsMatch() async throws {
            let manager = RadarLocationManager.sharedInstance()
            let location = HandleLocationFixtures.location()

            RadarLocationManagerSwiftTestHelpers.clearState()
            HandleLocationFixtures.clearRadarState()
            defer {
                RadarLocationManagerSwiftTestHelpers.clearState()
                HandleLocationFixtures.clearRadarState()
            }
            RadarSettings.tracking = false
            RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": false])
            manager.handle(location, source: .foregroundLocation)
            await HandleLocationFixtures.drainMainQueue()

            let defaults = UserDefaults.standard
            let objcStopped = defaults.bool(forKey: "radar-stopped")
            let objcLastMovedAt = defaults.object(forKey: "radar-lastMovedAt") as? Date
            let objcLastSentAt = try #require(defaults.object(forKey: "radar-lastSentAt") as? Date)
            #expect(objcLastMovedAt == location.timestamp)

            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer { RadarSwift.bridge = originalBridge }
            HandleLocationFixtures.clearRadarState()

            RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: ["useSwiftLocationManager": true])
            manager.handle(location, source: .foregroundLocation)
            await HandleLocationFixtures.drainMainQueue()

            // With the flag on, state goes through the bridge, so Objective-C never writes RadarState.
            #expect(defaults.object(forKey: "radar-lastSentAt") == nil)
            #expect(bridge.isStopped() == objcStopped)
            #expect(bridge.lastMovedAt() == objcLastMovedAt)
            #expect(bridge.lastMovedLocation() === location)
            #expect(bridge.lastLocation() === location)
            #expect(bridge.lastClientLocationSource == .foregroundLocation)
            let swiftLastSentAt = try #require(bridge.lastSentAt())
            #expect(swiftLastSentAt >= objcLastSentAt)
        }
    }
}
