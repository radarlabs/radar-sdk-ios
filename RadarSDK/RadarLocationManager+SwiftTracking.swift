//
//  RadarLocationManager+SwiftTracking.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Swift twin of `updateTracking:fromInitialize:`. `RadarLocationManager.m` calls it from inside
// its main-queue block, so it runs synchronously on the main thread.
extension RadarLocationManagerSwift {

    @objc(updateTrackingWithHost:location:fromInitialize:)
    static func updateTracking(host: RadarLocationManagerSwiftHost, location: CLLocation?, fromInitialize: Bool) {
        let options = Radar.getTrackingOptions()
        let localOptions = RadarSettings.trackingOptions

        RadarLogger.shared.debug(
            "🦅 Updating tracking | options = \(options.dictionaryValue()); location = \(String(describing: location))"
        )

        if !RadarSettings.tracking, let startTrackingAfter = localOptions?.startTrackingAfter, startTrackingAfter.timeIntervalSinceNow < 0 {
            RadarLogger.shared.debug(
                "🦅 Starting time-based tracking | startTrackingAfter = \(String(describing: options.startTrackingAfter))"
            )

            RadarSettings.tracking = true
        } else if RadarSettings.tracking, let stopTrackingAfter = localOptions?.stopTrackingAfter, stopTrackingAfter.timeIntervalSinceNow < 0 {
            RadarLogger.shared.debug(
                "🦅 Stopping time-based tracking | stopTrackingAfter = \(String(describing: options.stopTrackingAfter))"
            )

            RadarSettings.tracking = false
        }

        if RadarSettings.tracking {
            applyTrackingOptions(options, host: host, location: location)
        } else {
            stopUpdates(host: host, locationManager: host.locationManager)
            removeAllRegions(locationManager: host.locationManager)

            // If updateTracking() was called from the RadarLocationManager initializer, don't tell
            // the CLLocationManager to stop, because the location manager may be in use by other
            // location-based services.
            if !fromInitialize {
                RadarLogger.shared.debug("🦅 Stopping monitoring visits and SLCs")

                host.locationManager.stopMonitoringVisits()
                host.locationManager.stopMonitoringSignificantLocationChanges()
            }
        }
    }

    private static func applyTrackingOptions(
        _ options: RadarTrackingOptions,
        host: RadarLocationManagerSwiftHost,
        location: CLLocation?
    ) {
        let locationManager = host.locationManager
        let lowPowerLocationManager = host.lowPowerLocationManager
        let authorizationStatus = permissionsHelper.locationAuthorizationStatus()

        locationManager.allowsBackgroundLocationUpdates =
            RadarUtils.locationBackgroundMode && authorizationStatus == .authorizedAlways
        locationManager.pausesLocationUpdatesAutomatically = false

        lowPowerLocationManager.allowsBackgroundLocationUpdates = RadarUtils.locationBackgroundMode
        lowPowerLocationManager.pausesLocationUpdatesAutomatically = false

        if options.useMotion || options.usePressure {
            host.startMotionUpdates(options: options)
        }

        locationManager.desiredAccuracy = clLocationAccuracy(for: options.desiredAccuracy)

        lowPowerLocationManager.showsBackgroundLocationIndicator = options.showBlueBar

        applyUpdatesAndBubbleGeofence(options, host: host, location: location, authorizationStatus: authorizationStatus)

        if !options.syncGeofences {
            removeSyncedGeofences(locationManager: locationManager)
        }

        if options.useVisits {
            locationManager.startMonitoringVisits()
        } else {
            locationManager.stopMonitoringVisits()
        }

        if options.useSignificantLocationChanges {
            locationManager.startMonitoringSignificantLocationChanges()
        } else {
            locationManager.stopMonitoringSignificantLocationChanges()
        }

        if !options.beacons {
            removeSyncedBeacons(locationManager: locationManager)
        }
    }

    private static func applyUpdatesAndBubbleGeofence(
        _ options: RadarTrackingOptions,
        host: RadarLocationManagerSwiftHost,
        location: CLLocation?,
        authorizationStatus: CLAuthorizationStatus
    ) {
        let locationManager = host.locationManager
        let startUpdatesWhileInUse = RadarSettings.sdkConfiguration?.startUpdatesWhileInUse ?? false
        let shouldStartUpdates =
            options.showBlueBar || authorizationStatus == .authorizedAlways
            || (startUpdatesWhileInUse && authorizationStatus == .authorizedWhenInUse)

        let stopped = RadarSwift.bridge?.isStopped() ?? false
        let interval = stopped ? options.desiredStoppedUpdateInterval : options.desiredMovingUpdateInterval
        let useBubbleGeofence = stopped ? options.useStoppedGeofence : options.useMovingGeofence
        let bubbleGeofenceRadius = stopped ? options.stoppedGeofenceRadius : options.movingGeofenceRadius

        // Stop updates when they shouldn't run, not only when the interval is 0. Otherwise a timer
        // started under earlier options (for example, with the blue bar on) keeps running.
        if interval == 0 || !shouldStartUpdates {
            stopUpdates(host: host, locationManager: locationManager)
        } else {
            startUpdates(
                host: host,
                locationManager: locationManager,
                lowPowerLocationManager: host.lowPowerLocationManager,
                interval: interval,
                blueBar: options.showBlueBar
            )
        }

        if useBubbleGeofence {
            if let location {
                replaceBubbleGeofence(locationManager: locationManager, location: location, radius: bubbleGeofenceRadius)
            }
        } else {
            removeBubbleGeofence(locationManager: locationManager)
        }
    }
}
