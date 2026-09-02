//
//  RadarLocationManager+SwiftDelegate.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

private final class RadarBeaconRegionStateBox: @unchecked Sendable {
    let location: CLLocation
    let region: CLBeaconRegion

    init(location: CLLocation, region: CLBeaconRegion) {
        self.location = location
        self.region = region
    }
}

// The `CLLocationManagerDelegate` half of `RadarLocationManager`
extension RadarLocationManagerSwift {

    @objc(didUpdateLocations:completionHandlerCount:)
    static func didUpdateLocations(_ updates: [CLLocation]?, completionHandlerCount: UInt) {
        // At least one location update exists. Last one is the one we care about
        guard let location = updates?.last else {
            return
        }

        let source = locationSource(completionHandlerCount: completionHandlerCount)
        guard source != .unknown else {
            return
        }

        RadarSwift.bridge?.handleLocation(location, source: source)
    }

    private static func locationSource(completionHandlerCount: UInt) -> RadarLocationSource {
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

    @objc(didVisitOnLocationManager:visit:)
    static func didVisit(locationManager: CLLocationManager, visit: CLVisit) {
        guard let location = locationManager.location else {
            return
        }

        RadarLogger.shared.debug(
            "🦅 Visit detected | arrival = \(visit.arrivalDate); departure = \(visit.departureDate); horizontalAccuracy = \(visit.horizontalAccuracy); visit.coordinate = (\(visit.coordinate.latitude), \(visit.coordinate.longitude)); manager.location = \(location)"
        )

        guard RadarSettings.tracking else {
            RadarLogger.shared.debug("🦅 Ignoring visit: not tracking")
            return
        }

        // Core Location represents an arrival-only visit with a distant-future departure date;
        // a concrete departure date means the visit is complete. See CLVisit.departureDate.
        let source: RadarLocationSource =
            visit.departureDate == .distantFuture
            ? .visitArrival
            : .visitDeparture
        RadarSwift.bridge?.handleLocation(location, source: source)
    }

    @objc(didDetermineStateOnLocationManager:state:region:)
    static func didDetermineState(locationManager: CLLocationManager, state: CLRegionState, region: CLRegion) {
        let identifier = region.identifier
        guard identifier.hasPrefix(syncBeaconIdentifierPrefix) || identifier.hasPrefix(syncBeaconUUIDIdentifierPrefix) else {
            return
        }

        guard let location = effectiveLocation(for: locationManager), let beaconRegion = region as? CLBeaconRegion else {
            return
        }

        let isInside = state == .inside
        let source: RadarLocationSource = isInside ? .beaconEnter : .beaconExit
        let stateBox = RadarBeaconRegionStateBox(location: location, region: beaconRegion)
        RadarLogger.shared.debug("🦅 \(isInside ? "Inside" : "Outside") beacon region | identifier = \(identifier)")

        runOnMainThread { [stateBox] in
            MainActor.assumeIsolated {
                let beaconManager = RadarBeaconManagerSwift.shared
                let completionHandler: RadarBeaconCompletionHandler = { _, _ in
                    RadarSwift.bridge?.handleLocation(stateBox.location, source: source)
                }

                if identifier.hasPrefix(syncBeaconUUIDIdentifierPrefix) {
                    if isInside {
                        beaconManager.handleBeaconUUIDEntry(for: stateBox.region, completionHandler: completionHandler)
                    } else {
                        beaconManager.handleBeaconUUIDExit(for: stateBox.region, completionHandler: completionHandler)
                    }
                } else if isInside {
                    beaconManager.handleBeaconEntry(for: stateBox.region, completionHandler: completionHandler)
                } else {
                    beaconManager.handleBeaconExit(for: stateBox.region, completionHandler: completionHandler)
                }
            }
        }
    }

    // Core Location may call this delegate off the main thread, while beacon state is main-actor owned.
    private static func runOnMainThread(_ work: @escaping @MainActor @Sendable () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                work()
            }
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    work()
                }
            }
        }
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
