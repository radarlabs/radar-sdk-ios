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
// shared by every manager in the app). The checks and the `stopMonitoring` calls run on the main thread,
// where regions are registered. The cleanup is skipped if tracking started or synced regions were
// registered since it began, so it never removes a region registered after the read.
@objc(RadarRegionCleaner)
final class RadarRegionCleaner: NSObject {

    static let queue = DispatchQueue(label: "io.radar.regionCleaner", qos: .utility)

    // Called on `queue`. Each read creates, uses, and releases its manager inside one block, so the
    // manager is only used on the thread that created it.
    nonisolated(unsafe) static var makeLocationManager: () -> CLLocationManager = { CLLocationManager() }

    // Counts calls to `didRegisterRegions()`. Only read and written on the main thread.
    nonisolated(unsafe) private(set) static var registrationCount = 0

    // Carries the main-thread manager and the regions read on `queue` back to the main thread.
    private final class Cleanup: @unchecked Sendable {
        let locationManager: CLLocationManager
        let registrationCount: Int
        var regions: [CLRegion] = []

        init(locationManager: CLLocationManager, registrationCount: Int) {
            self.locationManager = locationManager
            self.registrationCount = registrationCount
        }
    }

    // Call on the main thread with the manager Radar registers regions on.
    @objc(removeAllRegionsUsingLocationManager:)
    static func removeAllRegions(using locationManager: CLLocationManager) {
        let cleanup = Cleanup(locationManager: locationManager, registrationCount: registrationCount)
        queue.async {
            guard let regions = radarRegions(locationManager: makeLocationManager()) else {
                return
            }

            cleanup.regions = regions
            Task { @MainActor in
                stopMonitoring(
                    cleanup.regions,
                    locationManager: cleanup.locationManager,
                    registrationCount: cleanup.registrationCount
                )
            }
        }
    }

    // Call on the main thread whenever synced regions are registered. `trackOnce` registers synced
    // geofences and beacons even with tracking off, and they reuse identifiers, so a pending cleanup's
    // read may list a region that was just registered again.
    @objc static func didRegisterRegions() {
        registrationCount += 1
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

    // Skips the stops if tracking started or synced regions were registered since the cleanup began
    // (`registrationCount` is the count it began with). Synced geofences reuse their identifiers, so a
    // region from the read may be one that was just registered again. Regions are registered on the
    // main thread, so none can be registered between these checks and the stops.
    @MainActor
    static func stopMonitoring(_ regions: [CLRegion], locationManager: CLLocationManager, registrationCount: Int) {
        if RadarSettings.tracking {
            RadarLogger.shared.debug("Tracking started, skipping region cleanup | regions = \(regions.count)")
            return
        }

        if registrationCount != Self.registrationCount {
            RadarLogger.shared.debug("Regions registered since the cleanup began, skipping it | regions = \(regions.count)")
            return
        }

        for region in regions {
            locationManager.stopMonitoring(for: region)
        }

        RadarLogger.shared.debug("Removed regions | removed = \(regions.count)")
    }
}
