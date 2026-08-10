//
//  RadarLocationManager+SwiftDelegate.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// The `CLLocationManagerDelegate` half of the `RadarLocationManager` Swift port. These twins
// are called from the delegate callbacks in RadarLocationManager.m; the tracking- and
// region-management twins live in RadarLocationManager+Swift.swift alongside the identifier
// prefix constants. Split out purely so neither file exceeds SwiftLint's 400-line limit —
// see that file's header comment for how the migration works.
extension RadarLocationManagerSwift {

    // Takes the heading rather than the location manager, so it uses a plain selector
    // instead of the `...OnLocationManager:` convention. `RadarState` is a non-@objc Swift
    // class and can't appear in an @objc signature, so it's constructed inside the method.
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
    // carries our identifier prefix, and we only act on it while tracking. `didEnterRegion`
    // and `didExitRegion` ran identical copies of this, differing only in the log wording, so
    // `action` ("entry"/"exit") is threaded through purely to preserve those messages.
    // `didDetermineState` is deliberately not a caller — it gates on the beacon prefixes and
    // has no tracking check.
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

    @objc(shouldHandleVisit:location:)
    static func shouldHandleVisit(_ visit: CLVisit, location: CLLocation?) -> Bool {
        guard let location else {
            return false
        }

        RadarLogger.shared.debug(
            "🦅 Visit detected | arrival = \(visit.arrivalDate); departure = \(visit.departureDate); horizontalAccuracy = \(visit.horizontalAccuracy); visit.coordinate = (\(visit.coordinate.latitude), \(visit.coordinate.longitude)); manager.location = \(location)"
        )

        guard RadarSettings.tracking else {
            RadarLogger.shared.debug("🦅 Ignoring visit: not tracking")
            return false
        }

        return true
    }

    // Core Location reports a visit that is still in progress with `departureDate` set to
    // the distant future, so that sentinel — not a nil check — is what distinguishes an
    // arrival from a departure.
    @objc(locationSourceForVisit:)
    static func locationSource(for visit: CLVisit) -> RadarLocationSource {
        return visit.departureDate == Date.distantFuture ? .visitArrival : .visitDeparture
    }
}
