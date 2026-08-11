//
//  RadarLocationManager+SwiftDelegate.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// The `CLLocationManagerDelegate` half of `RadarLocationManager`
extension RadarLocationManagerSwift {

    @objc(locationSourceForUpdates:completionHandlerCount:)
    static func locationSource(for updates: [CLLocation]?, completionHandlerCount: UInt) -> RadarLocationSource {
        guard updates?.last != nil else {
            return .unknown
        }

        let configuration = RadarSettings.sdkConfiguration
        if completionHandlerCount > 0,
            configuration?.skipForegroundCheck == true || RadarSwift.bridge?.isForeground() == true
        {
            return .foregroundLocation
        }

        guard RadarSettings.tracking else {
            RadarLogger.shared.debug("🦅 Ignoring location: not tracking")
            return .unknown
        }

        return .backgroundLocation
    }

    @objc(didUpdateHeading:)
    static func didUpdateHeading(_ heading: CLHeading) {
        RadarState().lastHeadingData = [
            "magneticHeading": heading.magneticHeading,
            "trueHeading": heading.trueHeading,
            "headingAccuracy": heading.headingAccuracy,
            "x": heading.x,
            "y": heading.y,
            "z": heading.z,
            "timestamp": heading.timestamp.timeIntervalSince1970,
        ]
    }

    @objc(didChangeAuthorizationStatus:)
    static func didChangeAuthorizationStatus(_ status: CLAuthorizationStatus) {
        let state = RadarState()
        let previousStatus = state.locationAuthorizationStatus
        state.locationAuthorizationStatus = status

        if status == previousStatus {
            return
        }

        guard let config = RadarSettings.sdkConfiguration else {
            return
        }
        guard status == .authorizedAlways || status == .authorizedWhenInUse,
            config.trackOnceOnAppOpen || config.startTrackingOnInitialize
        else {
            return
        }

        RadarLogger.shared.log(level: .info, message: "🦅 Location services authorized")
        Radar.trackOnce(completionHandler: nil)
        if config.startTrackingOnInitialize, !RadarSettings.tracking {
            Radar.startTracking(trackingOptions: RadarSettings.trackingOptions)
        }
    }

    @objc(didFailWithError:)
    static func didFail(error: NSError) {
        RadarLogger.shared.debug("🦅 CLLocation manager error | error = \(error)")
        RadarSwift.bridge?.didFail(status: .errorLocation)
    }

    // Falls back to the last known location when the manager's current location is stale or
    // missing — used by the region delegate callbacks (didEnterRegion/didExitRegion/
    // didDetermineState) before they hand off to `handleLocation:`.
    @objc(effectiveLocationForLocationManager:)
    static func effectiveLocation(for locationManager: CLLocationManager) -> CLLocation? {
        if let location = locationManager.location, location.isValid {
            return location
        }
        return RadarSwift.bridge?.lastLocation()
    }

    // The shared entry gate for the region delegate callbacks: a region is ours only if it
    // carries our identifier prefix, and we only act on it while tracking.
    @objc(shouldHandleRegionWithIdentifier:action:)
    static func shouldHandleRegion(identifier: String, action: String) -> Bool {
        guard identifier.hasPrefix(identifierPrefix) else {
            RadarLogger.shared.debug("🦅 Ignoring region \(action): wrong prefix")
            return false
        }

        guard RadarSettings.tracking else {
            RadarLogger.shared.debug("🦅 Ignoring region \(action): not tracking")
            return false
        }

        return true
    }

}
