//
//  RadarLocationManager+Swift.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Swift port of `RadarLocationManager` methods, added one at a time as the class
// migrates from Objective-C. Each method here has a twin in `RadarLocationManager.m`
// that dispatches to it when `useSwiftLocationManager` is enabled. When a method's
// Swift port is trusted, the ObjC body is deleted and the original method name takes
// over the call site. Until then, both implementations coexist.
//
// `RadarLocationManager.h` is a project-visibility header and is not in the framework's
// auto-synthesized Swift module, so we cannot extend `RadarLocationManager` from Swift.
// Static methods on this class are called from `RadarLocationManager.m` via
// `RadarSDK-Swift.h`. Methods that need access to the manager's CLLocationManager
// receive it as an explicit argument — once the porting cluster grows enough to share
// more instance state (timer, completion handlers), we can introduce a host protocol.
@objc(RadarLocationManagerSwift)
final class RadarLocationManagerSwift: NSObject {

    // Mirror of the identifier prefix constants in RadarLocationManager.m. Kept in sync by
    // hand until that file is fully ported.
    private static let identifierPrefix = "radar_"
    private static let bubbleGeofenceIdentifierPrefix = "radar_bubble_"
    private static let syncGeofenceIdentifierPrefix = "radar_geofence_"
    private static let syncBeaconIdentifierPrefix = "radar_beacon_"
    private static let syncBeaconUUIDIdentifierPrefix = "radar_uuid_"

    @objc static func restartPreviousTrackingOptions() {
        let previousTrackingOptions = RadarSettings.previousTrackingOptions
        RadarLogger.shared.debug("🦅 Restarting previous tracking options")

        if let previousTrackingOptions {
            Radar.startTracking(trackingOptions: previousTrackingOptions)
        } else {
            Radar.stopTracking()
        }

        RadarSettings.previousTrackingOptions = nil
    }

    @objc(matchBeaconIdsWithRanged:synced:)
    static func matchBeaconIds(ranged: [RadarBeacon], synced: [RadarBeacon]) -> [String] {
        var syncedMap: [String: String] = [:]
        for beacon in synced {
            let key = "\(beacon.uuid.lowercased())|\(beacon.major)|\(beacon.minor)"
            if let id = beacon._id {
                syncedMap[key] = id
            }
        }

        var matched: [String] = []
        for beacon in ranged {
            let key = "\(beacon.uuid.lowercased())|\(beacon.major)|\(beacon.minor)"
            if let matchedId = syncedMap[key] {
                matched.append(matchedId)
            }
        }

        RadarLogger.shared.log(
            level: .info,
            message: "🦅 Beacon ID matching | synced=\(syncedMap.count), ranged=\(ranged.count), matchedIds=\(matched)"
        )
        return matched
    }

    @objc(replaceSyncedBeaconsOnLocationManager:beacons:)
    static func replaceSyncedBeacons(locationManager: CLLocationManager, beacons: [RadarBeacon]?) {
        if RadarSettings.useRadarModifiedBeacon {
            RadarLogger.shared.debug("🦅 Skipping replacing synced beacons | useRadarModifiedBeacon = true")
            return
        }

        removeSyncedBeacons(locationManager: locationManager)

        let options = Radar.getTrackingOptions()
        guard RadarSettings.tracking, options.beacons, let beacons else {
            RadarLogger.shared.debug("🦅 Skipping replacing synced beacons")
            return
        }

        let numBeacons = min(beacons.count, 9)

        for beacon in beacons.prefix(numBeacons) {
            let identifier = "\(syncBeaconIdentifierPrefix)\(beacon._id ?? "")"
            guard let proximityUUID = UUID(uuidString: beacon.uuid) else {
                RadarLogger.shared.debug(
                    "🦅 Error syncing beacon | identifier = \(identifier); uuid = \(beacon.uuid); major = \(beacon.major); minor = \(beacon.minor)"
                )
                continue
            }

            guard let majorInt = Int(beacon.major), let minorInt = Int(beacon.minor) else {
                RadarLogger.shared.debug(
                    "🦅 Error syncing beacon | identifier = \(identifier); uuid = \(beacon.uuid); major = \(beacon.major); minor = \(beacon.minor)"
                )
                continue
            }

            let major = CLBeaconMajorValue(truncatingIfNeeded: majorInt)
            let minor = CLBeaconMinorValue(truncatingIfNeeded: minorInt)
            let region = CLBeaconRegion(
                proximityUUID: proximityUUID,
                major: major,
                minor: minor,
                identifier: identifier
            )
            region.notifyEntryStateOnDisplay = true
            locationManager.startMonitoring(for: region)
            locationManager.requestState(for: region)

            RadarLogger.shared.debug(
                "🦅 Synced beacon | identifier = \(identifier); uuid = \(beacon.uuid); major = \(beacon.major); minor = \(beacon.minor)"
            )
        }
    }

    @objc(replaceSyncedBeaconUUIDsOnLocationManager:uuids:)
    static func replaceSyncedBeaconUUIDs(locationManager: CLLocationManager, uuids: [String]?) {
        if RadarSettings.useRadarModifiedBeacon {
            RadarLogger.shared.debug("🦅 Skipping replacing synced beacon UUIDs | useRadarModifiedBeacon = true")
            return
        }

        removeSyncedBeacons(locationManager: locationManager)

        let options = Radar.getTrackingOptions()
        guard RadarSettings.tracking, options.beacons, let uuids else {
            RadarLogger.shared.debug("🦅 Skipping replacing synced beacon UUIDs")
            return
        }

        let numUUIDs = min(uuids.count, 9)

        for uuid in uuids.prefix(numUUIDs) {
            let identifier = "\(syncBeaconUUIDIdentifierPrefix)\(uuid)"
            guard let proximityUUID = UUID(uuidString: uuid) else {
                RadarLogger.shared.debug("🦅 Error syncing UUID | identifier = \(identifier); uuid = \(uuid)")
                continue
            }

            let region = CLBeaconRegion(proximityUUID: proximityUUID, identifier: identifier)
            region.notifyEntryStateOnDisplay = true
            locationManager.startMonitoring(for: region)
            locationManager.requestState(for: region)

            RadarLogger.shared.debug("🦅 Synced UUID | identifier = \(identifier); uuid = \(uuid)")
        }
    }

    @objc(removeSyncedBeaconsOnLocationManager:)
    static func removeSyncedBeacons(locationManager: CLLocationManager) {
        if RadarSettings.useRadarModifiedBeacon {
            RadarLogger.shared.debug("🦅 Skipping removing synced beacons | useRadarModifiedBeacon = true")
            return
        }

        for region in locationManager.monitoredRegions
        where region.identifier.hasPrefix(syncBeaconUUIDIdentifierPrefix)
            || region.identifier.hasPrefix(syncBeaconIdentifierPrefix)
        {
            locationManager.stopMonitoring(for: region)
        }
    }

    @objc(replaceBubbleGeofenceOnLocationManager:location:radius:)
    static func replaceBubbleGeofence(locationManager: CLLocationManager, location: CLLocation, radius: Int32) {
        // Always clear the existing bubble first. If tracking is off, the correct
        // end state is no bubble geofence, so we remove then return early.
        removeBubbleGeofence(locationManager: locationManager)

        guard RadarSettings.tracking else {
            return
        }

        let identifier = "\(bubbleGeofenceIdentifierPrefix)\(UUID().uuidString)"
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: CLLocationDistance(radius),
            identifier: identifier
        )
        locationManager.startMonitoring(for: region)

        RadarLogger.shared.debug(
            "🦅 Successfully added bubble geofence | latitude = \(location.coordinate.latitude); longitude = \(location.coordinate.longitude); radius = \(radius); identifier = \(identifier)"
        )
    }

    @objc(removeBubbleGeofenceOnLocationManager:)
    static func removeBubbleGeofence(locationManager: CLLocationManager) {
        for region in locationManager.monitoredRegions
        where region.identifier.hasPrefix(bubbleGeofenceIdentifierPrefix) {
            locationManager.stopMonitoring(for: region)
        }

        RadarLogger.shared.debug("🦅 Removed bubble geofences")
    }

    @objc(replaceSyncedGeofencesOnLocationManager:geofences:)
    static func replaceSyncedGeofences(locationManager: CLLocationManager, geofences: [RadarGeofence]?) {
        // Region monitoring only. Geofence notifications are registered separately through the
        // Swift notification actor (RadarNotificationHelper) by the ObjC dispatcher, so this
        // twin matches the shape of replaceSyncedBeacons.
        guard let geofences else {
            RadarLogger.shared.debug("🦅 Skipping replacing synced geofences")
            return
        }

        removeSyncedGeofences(locationManager: locationManager)

        let options = Radar.getTrackingOptions()
        let numGeofences = min(geofences.count, options.beacons ? 9 : 19)

        for geofence in geofences.prefix(numGeofences) {
            var center: RadarCoordinate?
            var radius = 100.0
            if let circle = geofence.geometry as? RadarCircleGeometry {
                center = circle.center
                radius = circle.radius
            } else if let polygon = geofence.geometry as? RadarPolygonGeometry {
                center = polygon.center
                radius = polygon.radius
            }
            guard let center else {
                continue
            }

            let identifier = "\(syncGeofenceIdentifierPrefix)\(geofence._id)"
            let region = CLCircularRegion(
                center: center.coordinate,
                radius: radius,
                identifier: identifier
            )
            locationManager.startMonitoring(for: region)

            RadarLogger.shared.debug(
                "🦅 Synced geofence | latitude = \(center.coordinate.latitude); longitude = \(center.coordinate.longitude); radius = \(radius); identifier = \(identifier)"
            )
        }
    }

    @objc(removeSyncedGeofencesOnLocationManager:)
    static func removeSyncedGeofences(locationManager: CLLocationManager) {
        for region in locationManager.monitoredRegions
        where region.identifier.hasPrefix(syncGeofenceIdentifierPrefix) {
            locationManager.stopMonitoring(for: region)
        }

        RadarLogger.shared.debug("🦅 Removed synced geofences")
    }

    @objc(removeAllRegionsOnLocationManager:)
    static func removeAllRegions(locationManager: CLLocationManager) {
        for region in locationManager.monitoredRegions
        where region.identifier.hasPrefix(identifierPrefix) {
            locationManager.stopMonitoring(for: region)
        }
    }

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

        let config = RadarSettings.sdkConfiguration
        guard status == .authorizedAlways || status == .authorizedWhenInUse,
            (config?.trackOnceOnAppOpen ?? false) || (config?.startTrackingOnInitialize ?? false)
        else {
            return
        }

        RadarLogger.shared.log(level: .info, message: "🦅 Location services authorized")
        Radar.trackOnce(completionHandler: nil)
        if config?.startTrackingOnInitialize ?? false, !RadarSettings.tracking {
            Radar.startTracking(trackingOptions: RadarSettings.trackingOptions)
        }
    }
}
