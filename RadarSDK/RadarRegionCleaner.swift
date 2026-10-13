//
//  RadarRegionCleaner.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Removes Radar's monitored regions for `initialize` and config fetches without reading
// `monitoredRegions` on the main thread.
//
// Threading:
// - The `monitoredRegions` read runs on `queue`. The getter returns data, so it waits for Core Location
//   to answer, and at cold launch that can take hundreds of milliseconds. Doing it on the main thread
//   caused App Hangs in `initialize`.
// - The read uses its own delegate-less `CLLocationManager`, created, used, and released inside one
//   block on `queue`, so the manager stays on the thread that created it. A manager with no delegate
//   needs no run loop, and monitored regions are shared by every manager in the app, so it sees the
//   regions Radar's main-thread managers registered.
// - The tracking check and the `stopMonitoring` calls run together on the main thread. That's where
//   regions are registered (`updateTracking`, and API responses delivered on main), so `startTracking`
//   can't register a region between the check and the stops. Synced geofences reuse identifiers, so
//   without this a cleanup could remove a region tracking had just registered again.
// - `stopMonitoring` returns nothing and doesn't wait for Core Location to reply, so it's cheap on the
//   main thread: about 0.04 ms per region on an iPhone 16e, where a `monitoredRegions` read once took
//   824 ms. The SDK already calls `startMonitoring` and `stopMonitoring` on the main thread elsewhere.
@objc(RadarRegionCleaner)
final class RadarRegionCleaner: NSObject {

    static let queue = DispatchQueue(label: "io.radar.regionCleaner", qos: .utility)

    // Called on `queue`. Each read creates, uses, and releases its manager inside one block, so the
    // manager is only used on the thread that created it.
    nonisolated(unsafe) static var makeLocationManager: () -> CLLocationManager = { CLLocationManager() }

    // Carries the main-thread manager and the regions read on `queue` back to the main thread.
    private final class Cleanup: @unchecked Sendable {
        let locationManager: CLLocationManager
        var regions: [CLRegion] = []

        init(locationManager: CLLocationManager) {
            self.locationManager = locationManager
        }
    }

    // Reads Radar's regions on `queue`, then stops them on `locationManager` on the main thread unless
    // tracking is on by then. Pass the manager Radar registers regions on. Safe to call from any thread.
    @objc(removeAllRegionsUsingLocationManager:)
    static func removeAllRegions(using locationManager: CLLocationManager) {
        let cleanup = Cleanup(locationManager: locationManager)
        queue.async {
            guard let regions = radarRegions(locationManager: makeLocationManager()) else {
                return
            }

            cleanup.regions = regions
            Task { @MainActor in
                stopMonitoring(cleanup.regions, locationManager: cleanup.locationManager)
            }
        }
    }

    // Runs on `queue`. Returns nil while tracking is on, since tracking owns the regions then.
    static func radarRegions(locationManager: CLLocationManager) -> [CLRegion]? {
        if RadarSettings.tracking {
            return nil
        }

        return locationManager.monitoredRegions.filter {
            $0.identifier.hasPrefix(RadarLocationManagerSwift.identifierPrefix)
        }
    }

    // Checks tracking again because it may have started since the read. Synced geofences reuse their
    // identifiers, so a region from the read may be one tracking just registered again. Regions are
    // registered on the main thread, so none can be registered between this check and the stops.
    //
    // With tracking off, synced regions are removed by design: `trackOnce` registers synced geofences
    // and beacons, and the config in its response runs this cleanup right after. So the cleanup doesn't
    // need to protect regions `trackOnce` registers while it's pending.
    @MainActor
    static func stopMonitoring(_ regions: [CLRegion], locationManager: CLLocationManager) {
        if RadarSettings.tracking {
            RadarLogger.shared.debug("Tracking started, skipping region cleanup | regions = \(regions.count)")
            return
        }

        for region in regions {
            locationManager.stopMonitoring(for: region)
        }

        RadarLogger.shared.debug("Removed regions | removed = \(regions.count)")
    }
}
