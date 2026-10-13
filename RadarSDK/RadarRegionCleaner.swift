//
//  RadarRegionCleaner.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Removes Radar's monitored regions without reading `monitoredRegions` on the main thread. That getter
// is a synchronous call into Core Location, and it can block for a long time at cold launch. The read
// runs on a background queue with a separate, delegate-less `CLLocationManager` (monitored regions are
// shared by every manager in the app). The tracking check and the `stopMonitoring` calls run on the main
// thread, where regions are registered, so tracking can't register a region between them.
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

    // Call on the main thread with the manager Radar registers regions on.
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
