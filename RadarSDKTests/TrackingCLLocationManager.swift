//
//  TrackingCLLocationManager.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// Test-only `CLLocationManager` subclass that records `startMonitoring` /
/// `stopMonitoring` / `requestState` calls and overrides `monitoredRegions`
/// so Swift twins can be exercised without touching real Core Location
/// state. Subclassing CLLocationManager is officially unsupported by Apple,
/// but the existing ObjC test helper `CLLocationManagerMock` already relies
/// on it for the same purpose.
final class TrackingCLLocationManager: CLLocationManager, @unchecked Sendable {
    private(set) var trackedRegions = Set<CLRegion>()
    private(set) var requestStateRegions: [CLRegion] = []
    private(set) var startUpdatingLocationCallCount = 0
    private(set) var stopUpdatingLocationCallCount = 0
    private(set) var stopUpdatingHeadingCallCount = 0
    private(set) var requestLocationCallCount = 0
    private(set) var startMonitoringVisitsCallCount = 0
    private(set) var stopMonitoringVisitsCallCount = 0
    private(set) var startMonitoringSLCCallCount = 0
    private(set) var stopMonitoringSLCCallCount = 0
    var mockLocation: CLLocation?
    // When set, `monitoredRegions` returns this instead of `trackedRegions`, simulating Core
    // Location before it has caught up with recent `startMonitoring`/`stopMonitoring` calls. Used to
    // test that `removeBubbleGeofence` still stops a bubble its `monitoredRegions` scan can't see.
    var staleMonitoredRegions: Set<CLRegion>?
    // Counts `monitoredRegions` reads and records whether any ran on the main thread, so tests can
    // check that a code path keeps the synchronous locationd call off the main thread.
    private(set) var monitoredRegionsReadCount = 0
    private(set) var monitoredRegionsReadOnMainThread = false
    // Called after each `stopMonitoring(for:)`.
    var onStopMonitoring: ((CLRegion) -> Void)?
    // Records writes instead of passing them to Core Location, which raises an exception when
    // `allowsBackgroundLocationUpdates` is set to true without the location background mode.
    private(set) var allowsBackgroundLocationUpdatesWrites: [Bool] = []

    override var allowsBackgroundLocationUpdates: Bool {
        get { allowsBackgroundLocationUpdatesWrites.last ?? false }
        set { allowsBackgroundLocationUpdatesWrites.append(newValue) }
    }

    override var monitoredRegions: Set<CLRegion> {
        monitoredRegionsReadCount += 1
        if Thread.isMainThread {
            monitoredRegionsReadOnMainThread = true
        }
        return staleMonitoredRegions ?? trackedRegions
    }
    override var location: CLLocation? { mockLocation }

    override func startMonitoring(for region: CLRegion) {
        trackedRegions.insert(region)
    }

    override func stopMonitoring(for region: CLRegion) {
        trackedRegions.remove(region)
        onStopMonitoring?(region)
    }

    override func requestState(for region: CLRegion) {
        requestStateRegions.append(region)
    }

    override func stopUpdatingLocation() {
        stopUpdatingLocationCallCount += 1
    }

    override func startUpdatingLocation() {
        startUpdatingLocationCallCount += 1
    }

    override func stopUpdatingHeading() {
        stopUpdatingHeadingCallCount += 1
    }

    override func requestLocation() {
        requestLocationCallCount += 1
    }

    override func startMonitoringVisits() {
        startMonitoringVisitsCallCount += 1
    }

    override func stopMonitoringVisits() {
        stopMonitoringVisitsCallCount += 1
    }

    override func startMonitoringSignificantLocationChanges() {
        startMonitoringSLCCallCount += 1
    }

    override func stopMonitoringSignificantLocationChanges() {
        stopMonitoringSLCCallCount += 1
    }

    func seed(_ identifiers: [String]) {
        for identifier in identifiers {
            trackedRegions.insert(
                CLCircularRegion(
                    center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    radius: 100,
                    identifier: identifier
                ))
        }
    }
}
