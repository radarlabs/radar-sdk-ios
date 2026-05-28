//
//  TrackingCLLocationManager.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// Test-only `CLLocationManager` subclass that records `startMonitoring` /
/// `stopMonitoring` / `requestLocation` / `stopUpdatingLocation` / `requestState`
/// calls and overrides `monitoredRegions` so Swift twins can be exercised
/// without touching real Core Location state. Subclassing CLLocationManager
/// is officially unsupported by Apple, but the existing ObjC test helper
/// `CLLocationManagerMock` already relies on it for the same purpose.
final class TrackingCLLocationManager: CLLocationManager, @unchecked Sendable {
    private(set) var trackedRegions = Set<CLRegion>()
    private(set) var requestLocationCallCount = 0
    private(set) var stopUpdatingLocationCallCount = 0
    private(set) var requestStateRegions: [CLRegion] = []

    override var monitoredRegions: Set<CLRegion> { trackedRegions }

    override func startMonitoring(for region: CLRegion) {
        trackedRegions.insert(region)
    }

    override func stopMonitoring(for region: CLRegion) {
        trackedRegions.remove(region)
    }

    override func requestLocation() {
        requestLocationCallCount += 1
    }

    override func stopUpdatingLocation() {
        stopUpdatingLocationCallCount += 1
    }

    override func requestState(for region: CLRegion) {
        requestStateRegions.append(region)
    }

    func seed(_ identifiers: [String]) {
        for identifier in identifiers {
            trackedRegions.insert(CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                radius: 100,
                identifier: identifier
            ))
        }
    }
}
