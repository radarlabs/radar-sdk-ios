//
//  RadarLocationManagerSwiftHandleLocationSyncTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarHandleLocationSwiftSyncTests {

        // MARK: - Replay

        @Test("a failed stopped location is replayed instead of the new location")
        func failedStoppedLocationIsReplayed() throws {
            try RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions(replay: .stops)
                let failed = HandleLocationFixtures.location(timestamp: Date().addingTimeInterval(-600))
                bridge.mockLastFailedStoppedLocation = failed
                let host = TrackingRadarLocationManagerHost()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(), source: .backgroundLocation, beacons: nil)

                let sent = try #require(host.sentLocations.first)
                #expect(sent.location === failed)
                #expect(sent.stopped)
                #expect(sent.replayed)
                #expect(bridge.lastFailedStoppedLocation() == nil)
            }
        }

        // MARK: - Sync gating

        @Test("a location inside the desired sync interval is not sent")
        func desiredSyncIntervalSkips() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions(desiredSyncInterval: 600)
                let lastSentAt = Date().addingTimeInterval(-60)
                bridge.mockLastSentAt = lastSentAt
                let host = TrackingRadarLocationManagerHost()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(), source: .backgroundLocation, beacons: nil)

                #expect(host.sentLocations.isEmpty)
                #expect(bridge.lastSentAt() == lastSentAt)
                // State still updates before the sync gates.
                #expect(bridge.lastLocation() != nil)
            }
        }

        @Test("a location within a second of the last send is rate limited")
        func rateLimitSkips() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()
                bridge.mockLastSentAt = Date()
                let host = TrackingRadarLocationManagerHost()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(), source: .backgroundLocation, beacons: nil)

                #expect(host.sentLocations.isEmpty)
            }
        }

        @Test("a waiting location request bypasses the sync gates")
        func pendingCompletionHandlerBypassesSyncGates() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions(desiredSyncInterval: 600)
                bridge.mockLastSentAt = Date()
                let host = TrackingRadarLocationManagerHost()
                host.pendingCompletionHandlerCount = 1

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(), source: .backgroundLocation, beacons: nil)

                #expect(host.sentLocations.count == 1)
            }
        }

        @Test("sync mode none skips sending")
        func syncNoneSkips() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions(syncLocations: .none)
                bridge.mockLastSentAt = Date().addingTimeInterval(-60)
                let host = TrackingRadarLocationManagerHost()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(), source: .backgroundLocation, beacons: nil)

                #expect(host.sentLocations.isEmpty)
            }
        }

        @Test("stops-and-exits sync skips sending when the device can't exit")
        func stopsAndExitsSkipsWhenCannotExit() {
            RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions(syncLocations: .stopsAndExits)
                bridge.mockLastSentAt = Date().addingTimeInterval(-60)
                bridge.mockCanExit = false
                let host = TrackingRadarLocationManagerHost()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(), source: .backgroundLocation, beacons: nil)

                #expect(host.sentLocations.isEmpty)
            }
        }

        // MARK: - Indoor locations

        @Test("an indoor location is sent without touching the device's location state")
        func indoorLocationBypassesDeviceState() throws {
            try RadarLocationManagerSwiftTestHelpers.withMockedSwiftTrackingDependencies { bridge in
                RadarSettings.tracking = true
                RadarSettings.trackingOptions = HandleLocationFixtures.trackingOptions()
                bridge.mockStopped = true
                let host = TrackingRadarLocationManagerHost()

                RadarLocationManagerSwift.handleLocation(
                    host: host, location: HandleLocationFixtures.location(), source: .indoors, beacons: nil)

                #expect(host.cancelTimeoutsCallCount == 0)
                #expect(host.completionStatuses.isEmpty)
                #expect(host.updateTrackingLocations.isEmpty)
                #expect(bridge.lastLocation() == nil)
                #expect(bridge.lastMovedLocation() == nil)
                #expect(bridge.lastClientLocation == nil)
                let sent = try #require(host.sentLocations.first)
                #expect(sent.stopped)
            }
        }
    }
}
