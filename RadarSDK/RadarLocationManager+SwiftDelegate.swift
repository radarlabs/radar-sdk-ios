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

    @objc(didEnterRegionOnLocationManager:region:)
    static func didEnterRegion(locationManager: CLLocationManager, region: CLRegion) {
        handleRegion(
            locationManager: locationManager,
            region: region,
            action: "entry",
            isEntry: true
        )
    }

    @objc(didExitRegionOnLocationManager:region:)
    static func didExitRegion(locationManager: CLLocationManager, region: CLRegion) {
        handleRegion(
            locationManager: locationManager,
            region: region,
            action: "exit",
            isEntry: false
        )
    }

    private static func handleRegion(
        locationManager: CLLocationManager,
        region: CLRegion,
        action: String,
        isEntry: Bool
    ) {
        guard shouldHandleRegion(identifier: region.identifier, action: action) else {
            return
        }

        let identifier = region.identifier
        let location = effectiveLocation(for: locationManager)
        let beaconSource: RadarLocationSource = isEntry ? .beaconEnter : .beaconExit
        let geofenceSource: RadarLocationSource = isEntry ? .geofenceEnter : .geofenceExit

        if identifier.hasPrefix(syncBeaconUUIDIdentifierPrefix) || identifier.hasPrefix(syncBeaconIdentifierPrefix) {
            guard let location, let beaconRegion = region as? CLBeaconRegion else {
                return
            }

            handleBeaconRegion(
                location: location,
                identifier: identifier,
                region: beaconRegion,
                source: beaconSource,
                isEntry: isEntry
            )
        } else if let location = locationManager.location {
            RadarSwift.bridge?.handleLocation(location, source: geofenceSource)
        }
    }

    private static func handleBeaconRegion(
        location: CLLocation,
        identifier: String,
        region: CLBeaconRegion,
        source: RadarLocationSource,
        isEntry: Bool
    ) {
        let beaconUUID = region.uuid
        let beaconMajor = region.major?.uint16Value
        let beaconMinor = region.minor?.uint16Value

        Task { @MainActor in
            let beaconManager = RadarBeaconManagerSwift.shared
            let completionHandler: RadarBeaconCompletionHandler = { _, nearbyBeacons in
                RadarSwift.bridge?.handleLocation(
                    location,
                    source: source,
                    beacons: nearbyBeacons
                )
            }

            if identifier.hasPrefix(syncBeaconUUIDIdentifierPrefix) {
                if isEntry {
                    beaconManager.handleBeaconUUIDEntry(completionHandler: completionHandler)
                } else {
                    beaconManager.handleBeaconUUIDExit(completionHandler: completionHandler)
                }
            } else {
                let beaconRegion: CLBeaconRegion
                if let beaconMajor, let beaconMinor {
                    beaconRegion = CLBeaconRegion(
                        uuid: beaconUUID,
                        major: beaconMajor,
                        minor: beaconMinor,
                        identifier: identifier
                    )
                } else if let beaconMajor {
                    beaconRegion = CLBeaconRegion(
                        uuid: beaconUUID,
                        major: beaconMajor,
                        identifier: identifier
                    )
                } else {
                    beaconRegion = CLBeaconRegion(uuid: beaconUUID, identifier: identifier)
                }

                if isEntry {
                    beaconManager.handleBeaconEntry(for: beaconRegion, completionHandler: completionHandler)
                } else {
                    beaconManager.handleBeaconExit(for: beaconRegion, completionHandler: completionHandler)
                }
            }
        }
    }

    @MainActor
    @objc(didDetermineState:region:completionHandler:)
    static func didDetermineState(
        _ state: CLRegionState,
        region: CLRegion,
        completionHandler: @escaping RadarBeaconCompletionHandler
    ) {
        let identifier = region.identifier
        guard identifier.hasPrefix(syncBeaconIdentifierPrefix) || identifier.hasPrefix(syncBeaconUUIDIdentifierPrefix),
            let beaconRegion = region as? CLBeaconRegion
        else {
            return
        }

        let isInside = state == .inside
        RadarLogger.shared.debug("🦅 \(isInside ? "Inside" : "Outside") beacon region | identifier = \(identifier)")

        let beaconManager = RadarBeaconManagerSwift.shared
        if identifier.hasPrefix(syncBeaconUUIDIdentifierPrefix) {
            if isInside {
                beaconManager.handleBeaconUUIDEntry(for: beaconRegion, completionHandler: completionHandler)
            } else {
                beaconManager.handleBeaconUUIDExit(for: beaconRegion, completionHandler: completionHandler)
            }
        } else if isInside {
            beaconManager.handleBeaconEntry(for: beaconRegion, completionHandler: completionHandler)
        } else {
            beaconManager.handleBeaconExit(for: beaconRegion, completionHandler: completionHandler)
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
