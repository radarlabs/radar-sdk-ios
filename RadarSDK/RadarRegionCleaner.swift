//
//  RadarRegionCleaner.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Removes Radar's monitored regions off the main thread. `monitoredRegions` is a synchronous call
// into locationd that can block for a long time at cold launch, so the cleanup that
// `updateTracking:fromInitialize:` runs on every `initialize` and config fetch happens here instead.
// Monitored regions are shared by every `CLLocationManager` in the app, so a separate manager with no
// delegate can remove regions the main-thread managers registered.
@objc(RadarRegionCleaner)
final class RadarRegionCleaner: NSObject {

    private static let queue = DispatchQueue(label: "io.radar.regionCleaner", qos: .utility)

    // Called on `queue`. Each cleanup creates, uses, and releases its manager inside one block, so the
    // manager is only used on the thread that created it.
    nonisolated(unsafe) static var makeLocationManager: () -> CLLocationManager = { CLLocationManager() }

    @objc static func removeAllRegionsInBackground() {
        queue.async {
            removeAllRegions(locationManager: makeLocationManager())
        }
    }

    // Blocks until every queued cleanup has finished. Used by tests.
    static func waitUntilIdle() {
        queue.sync {}
    }

    private static func removeAllRegions(locationManager: CLLocationManager) {
        if RadarSettings.tracking {
            return
        }

        let regions = locationManager.monitoredRegions.filter {
            $0.identifier.hasPrefix(RadarLocationManagerSwift.identifierPrefix)
        }

        var removedCount = 0
        for region in regions {
            // Tracking may have started on the main thread since the scan. Synced geofences reuse their
            // identifiers, so a region in the scan may be one tracking just registered again.
            if RadarSettings.tracking {
                RadarLogger.shared.debug("Tracking started, stopping background region cleanup | removed = \(removedCount)")
                return
            }

            locationManager.stopMonitoring(for: region)
            removedCount += 1
        }

        RadarLogger.shared.debug("Removed regions in background | removed = \(removedCount)")
    }
}
