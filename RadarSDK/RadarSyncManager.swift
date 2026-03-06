//
//  RadarSyncManager.swift
//  RadarSDK
//
//  Created by Alan Charles on 1/29/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

@objc(RadarSyncManager)
public final class RadarSyncManager: NSObject {
    
    private static let placeDetectionRadius: Double = 100.0
    private static let beaconRange: Double = 100.0
    private static let boundaryThresholdFraction: Double = 0.2
    private static let syncRegionIdentifierPrefix = "radar_synced_"
    nonisolated(unsafe) private static var syncTimer: Timer?
    
    // MARK: - Lifecycle
    
    @objc public static func start(interval: TimeInterval) {
        stop()
        
        fetchSyncRegion()
        
        DispatchQueue.main.async {
            syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                fetchSyncRegion()
            }
        }
    }
    
    @objc public static func stop() {
        syncTimer?.invalidate()
        syncTimer = nil
        RadarLogger.shared.debug("SyncManager: Stopped sync region polling")
    }
    
    // MARK: - API 
    
    @objc public static func fetchSyncRegion() {
        guard let location = RadarSwift.bridge?.lastLocation() else {
            RadarLogger.shared.debug("SyncManager: No last location, skipping sync region fetch")
            return
        }
        
        RadarSwift.bridge?.fetchSyncRegion(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
        ) { status, res in
            guard status == .success, let res = res else {
                RadarLogger.shared.warning("SyncManager: Sync region request failed")
                return
            }
            
            if let geofencesArray = res["geofences"] {
                let geofences = RadarSwift.bridge?.geofencesFromObject(geofencesArray) ?? []
                RadarSwift.bridge?.setSyncedGeofences(geofences)
            }
            
            if let placesArray = res["places"] {
                let places = RadarSwift.bridge?.placesFromObject(placesArray) ?? []
                RadarSwift.bridge?.setSyncedPlaces(places)
            }
            
            if let beaconsArray = res["beacons"] {
                let beacons = RadarSwift.bridge?.beaconsFromObject(beaconsArray) ?? []
                RadarSwift.bridge?.setSyncedBeacons(beacons)
            }
            
            if let regionDict = res["region"] as? [String: Any],
               let lat = regionDict["latitude"] as? Double,
               let lng = regionDict["longitude"] as? Double,
               let radius = regionDict["radius"] as? Double,
               radius > 0 {
                let syncedRegion = CLCircularRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                    radius: radius,
                    identifier: "\(syncRegionIdentifierPrefix)\(UUID().uuidString)"
                )
                RadarSwift.bridge?.setSyncedRegion(syncedRegion)
                RadarLogger.shared.debug("SyncManager: Stored region | lat = \(lat); lng = \(lng); radius = \(radius)")
            } else {
                RadarSwift.bridge?.setSyncedRegion(nil)
            }
        }
    }
    
    // MARK: - Track Decision
    
    @objc public static func shouldTrack(location: CLLocation, options: RadarTrackingOptions) -> Bool {
        guard options.syncLocations == .events else {
            return true
        }
        
        guard RadarSwift.bridge?.syncedRegion() != nil else {
            RadarLogger.shared.debug("SyncManager: No synced region, should track")
            return true
        }
        
        if isNearSyncedRegionBoundary(location: location) {
            RadarLogger.shared.debug("SyncManager: Near synced region boundary, refreshing")
            fetchSyncRegion()
        }
        
        if isOutsideSyncedRegion(location: location) {
            RadarLogger.shared.debug("SyncManager: Outside synced region, should track")
            return true
        }
        
        if Radar.getTripOptions() != nil {
            RadarLogger.shared.debug("SyncManager: On active trip, should track")
            return true
        }
        
        if hasGeofenceStateChanged(location: location)
            || hasPlaceStateChanged(location: location)
            || hasBeaconStateChanged(location: location) {
            updateLastKnownSyncState(location: location)
            return true
        }
        
        RadarLogger.shared.debug("SyncManager: No state change detected, skipping track")
        return false
    }
    
    
    @objc public static func isNearSyncedRegionBoundary(location: CLLocation) -> Bool {
        guard let syncedRegion = RadarSwift.bridge?.syncedRegion() else {
            return false
        }
        let center = CLLocation(latitude: syncedRegion.center.latitude, longitude: syncedRegion.center.longitude)
        let distanceFromCenter = location.distance(from: center)
        let distanceFromEdge = syncedRegion.radius - distanceFromCenter
        
        return distanceFromEdge <= (syncedRegion.radius * boundaryThresholdFraction)
    }

    @objc public static func isOutsideSyncedRegion(location: CLLocation) -> Bool {
        guard let syncedRegion = RadarSwift.bridge?.syncedRegion() else {
            return true
        }
        
        return !syncedRegion.contains(location.coordinate)
    }
    
    // MARK: - Geometry Helpers

    @objc public static func isPoint(_ point: CLLocation, insideCircleWithCenter center: CLLocationCoordinate2D, radius: Double) -> Bool {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let distance = centerLocation.distance(from: point)
        
        return distance <= radius
    }
    
    private static func isPoint(_ point: CLLocationCoordinate2D, insidePolygon polygon: [RadarCoordinate]) -> Bool {
        guard polygon.count >= 3 else { return false }
        
        var inside = false
        var previousIndex = polygon.count - 1
        
        for currentIndex in 0..<polygon.count {
            let currentVertex = polygon[currentIndex].coordinate
            let previousVertex = polygon[previousIndex].coordinate
            
            // Check if a horizontal ray from the point crosses the edge
            // from previousVertex to currentVertex
            let currentAbove = currentVertex.latitude > point.latitude
            let previousAbove = previousVertex.latitude > point.latitude
            
            if currentAbove != previousAbove {
                // Compute where the edge crosses the point's latitude
                let edgeLongitudeAtPointLatitude = previousVertex.longitude
                + (point.latitude - previousVertex.latitude)
                / (currentVertex.latitude - previousVertex.latitude)
                * (currentVertex.longitude - previousVertex.longitude)
                
                if point.longitude < edgeLongitudeAtPointLatitude {
                    inside = !inside
                }
            }
            
            previousIndex = currentIndex
        }
        return inside
    }
    
    private static func distanceToPolygonEdge(from point: CLLocationCoordinate2D, polygon: [RadarCoordinate]) -> Double {
        guard polygon.count >= 3 else { return Double.greatestFiniteMagnitude }
        
        let pointLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
        var minimumDistance = Double.greatestFiniteMagnitude
        
        for currentIndex in 0..<polygon.count {
            let nextIndex = (currentIndex + 1) % polygon.count
            let edgeStart = polygon[currentIndex].coordinate
            let edgeEnd = polygon[nextIndex].coordinate
            
            let distance = distanceFromPoint(pointLocation, toSegmentFrom: edgeStart, to: edgeEnd)
            minimumDistance = min(minimumDistance, distance)
        }
        
        return minimumDistance
    }
    
    private static func distanceFromPoint(_ point: CLLocation, toSegmentFrom segmentStart: CLLocationCoordinate2D, to segmentEnd: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: segmentStart.latitude, longitude: segmentStart.longitude)
        let endLocation = CLLocation(latitude: segmentEnd.latitude, longitude: segmentEnd.longitude)
        
        let distanceToStart = point.distance(from: startLocation)
        let distanceToEnd = point.distance(from: endLocation)
        let segmentLength = startLocation.distance(from: endLocation)
        
        if segmentLength == 0 {
            return distanceToStart
        }
        
        // Project the point onto the segment
        // fractionAlongSegment = 0.0 means closest to segmentStart
        // 1.0 means closest to segmentEnd
        let fractionAlongSegment = max(0, min(1,
            (distanceToStart * distanceToStart - distanceToEnd * distanceToEnd + segmentLength * segmentLength)
            / (2 * segmentLength * segmentLength)
        ))
        
        let closestPointOnSegment = greatCircleInterpolate(from: segmentStart, to: segmentEnd, fraction: fractionAlongSegment)
        let closestLocation = CLLocation(latitude: closestPointOnSegment.latitude, longitude: closestPointOnSegment.longitude)
        
        return point.distance(from: closestLocation)
    }
    
    private static func greatCircleInterpolate(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D, fraction t: Double) -> CLLocationCoordinate2D {
        let lat1 = a.latitude * .pi / 180.0
        let lon1 = a.longitude * .pi / 180.0
        let lat2 = b.latitude * .pi / 180.0
        let lon2 = b.longitude * .pi / 180.0
        
        let deltaLat = lat2 - lat1
        let deltaLon = lon2 - lon1
        let sinHalfDLat = sin(deltaLat / 2)
        let sinHalfDLon = sin(deltaLon / 2)
        let h = sinHalfDLat * sinHalfDLat + cos(lat1) * cos(lat2) * sinHalfDLon * sinHalfDLon
        let angularDistance = 2.0 * atan2(sqrt(h), sqrt(1 - h))

        guard angularDistance > 1e-12 else { return a }
        
        let sinD = sin(angularDistance)
        let aCoeff = sin((1 - t) * angularDistance) / sinD
        let bCoeff = sin(t * angularDistance) / sinD
        
        let x = aCoeff * cos(lat1) * cos(lon1) + bCoeff * cos(lat2) * cos(lon2)
        let y = aCoeff * cos(lat1) * sin(lon1) + bCoeff * cos(lat2) * sin(lon2)
        let z = aCoeff * sin(lat1) + bCoeff * sin(lat2)
        
        let lat = atan2(z, sqrt(x * x + y * y)) * 180.0 / .pi
        let lon = atan2(y, x) * 180.0 / .pi
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    // MARK: - Containment Queries
    
    private static func isLocationInside(
        geofence: RadarGeofence,
        location: CLLocation,
        accuracy: Double,
        checkingForExit: Bool,
        sdkConfig: RadarSdkConfiguration?
    ) -> Bool {
        let shouldBuffer = checkingForExit
            ? (sdkConfig?.bufferGeofenceExits ?? true)
            : (sdkConfig?.bufferGeofenceEntries ?? true)
        if let circleGeometry = geofence.geometry as? RadarCircleGeometry {
            var effectiveRadius = circleGeometry.radius
            if shouldBuffer {
                effectiveRadius += accuracy
            }
            return isPoint(location, insideCircleWithCenter: circleGeometry.center.coordinate, radius: effectiveRadius)
        }
        if let polygonGeometry = geofence.geometry as? RadarPolygonGeometry,
           let coordinates = polygonGeometry._coordinates, !coordinates.isEmpty {
            if isPoint(location.coordinate, insidePolygon: coordinates) {
                return true
            }
            if shouldBuffer {
                // Quick bounding-circle rejection before the more expensive edge-distance check
                let bufferRadius = polygonGeometry.radius + accuracy
                guard isPoint(location, insideCircleWithCenter: polygonGeometry.center.coordinate, radius: bufferRadius) else {
                    return false
                }
                return distanceToPolygonEdge(from: location.coordinate, polygon: coordinates) <= accuracy
            }
            return false
        }
        return false
    }
    
    @objc public static func getGeofences(for location: CLLocation, checkingForExit: Bool = false) -> [RadarGeofence] {
        guard let nearbyGeofences = RadarSwift.bridge?.syncedGeofences(), !nearbyGeofences.isEmpty else {
            return []
        }
        let sdkConfig = RadarSettings.sdkConfiguration
        let accuracy = max(location.horizontalAccuracy, 0)
        return nearbyGeofences.filter {
            isLocationInside(geofence: $0, location: location, accuracy: accuracy, checkingForExit: checkingForExit, sdkConfig: sdkConfig)
        }
    }
    
    @objc public static func getBeacons(for location: CLLocation) -> [RadarBeacon] {
        guard let nearbyBeacons = RadarSwift.bridge?.syncedBeacons(), !nearbyBeacons.isEmpty else {
            return []
        }
        
        var userBeacons: [RadarBeacon] = []
        
        for beacon in nearbyBeacons {
            if let geometry = beacon.geometry {
                let beaconLocation = CLLocation(
                    latitude: geometry.coordinate.latitude,
                    longitude: geometry.coordinate.longitude
                )
                
                let distance = location.distance(from: beaconLocation)
                
                if distance <= beaconRange {
                    userBeacons.append(beacon)
                }
            }
        }
        
        return userBeacons
    }
    
    @objc public static func getPlaces(for location: CLLocation) -> [RadarPlace] {
        guard let nearbyPlaces = RadarSwift.bridge?.syncedPlaces(), !nearbyPlaces.isEmpty else {
            return []
        }
        
        var userPlaces: [RadarPlace] = []
        
        for place in nearbyPlaces {
            if isPoint(location, insideCircleWithCenter: place.location.coordinate, radius: placeDetectionRadius) {
                userPlaces.append(place)
            }
        }
        
        return userPlaces
    }
    
    // MARK: - State Detection
    
    @objc public static func hasGeofenceStateChanged(location: CLLocation) -> Bool {
        let lastKnownGeofenceIds = Set(RadarSwift.bridge?.lastSyncedGeofenceIds() ?? [])
        let currentGeofences = getGeofences(for: location)
        let currentGeofenceIds = Set(currentGeofences.compactMap { $0._id })
        
        if checkForGeofenceEntries(currentGeofences: currentGeofences, currentGeofenceIds: currentGeofenceIds, lastKnownGeofenceIds: lastKnownGeofenceIds) {
            return true
        }
        if checkForGeofenceExits(location: location, lastKnownGeofenceIds: lastKnownGeofenceIds) {
            return true
        }
        if checkForGeofenceDwell(currentGeofences: currentGeofences, currentGeofenceIds: currentGeofenceIds, lastKnownGeofenceIds: lastKnownGeofenceIds) {
            return true
        }
        
        return false
    }
    
    @objc public static func hasBeaconStateChanged(location: CLLocation) -> Bool {
        let lastKnownBeaconIds = Set(RadarSwift.bridge?.lastSyncedBeaconIds() ?? [])
        let currentBeacons = getBeacons(for: location)
        let currentIds = Set(currentBeacons.compactMap { $0._id })
        
        return currentIds != lastKnownBeaconIds
    }
    
    @objc public static func hasPlaceStateChanged(location: CLLocation) -> Bool {
        let lastKnownPlaceIds = Set(RadarSwift.bridge?.lastSyncedPlaceIds() ?? [])
        let currentPlaces = getPlaces(for: location)
        let currentIds = Set(currentPlaces.compactMap { $0._id })
        
        return currentIds != lastKnownPlaceIds
    }

    private static func checkForGeofenceEntries(
        currentGeofences: [RadarGeofence],
        currentGeofenceIds: Set<String>,
        lastKnownGeofenceIds: Set<String>
    ) -> Bool {
        let enteredGeofenceIds = currentGeofenceIds.subtracting(lastKnownGeofenceIds)
        guard !enteredGeofenceIds.isEmpty else { return false }
        
        let sdkConfig = RadarSettings.sdkConfiguration
        let projectStopDetection = sdkConfig?.stopDetection ?? false
        let isStopped = RadarSwift.bridge?.isStopped() ?? false
        
        var timestamps = RadarSwift.bridge?.geofenceEntryTimestamps() ?? [:]
        var hasEntry = false
        
        for id in enteredGeofenceIds {
            let geofence = currentGeofences.first { $0._id == id }
            let requireStop: Bool
            if let geofenceStop = geofence?.geofenceStopDetection {
                requireStop = geofenceStop.boolValue
            } else {
                requireStop = projectStopDetection
            }
            if requireStop && !isStopped {
                RadarLogger.shared.debug("SyncManager: Skipping geofence entry (stop detection, not stopped): \(id)")
                continue
            }
            RadarLogger.shared.debug("SyncManager: Detected geofence entry: \(id)")
            timestamps[id] = Date()
            hasEntry = true
        }
        if hasEntry {
            RadarSwift.bridge?.setGeofenceEntryTimestamps(timestamps)
        }
        return hasEntry
    }
    
    private static func checkForGeofenceExits(
        location: CLLocation,
        lastKnownGeofenceIds: Set<String>
    ) -> Bool {
        let exitCheckGeofences = getGeofences(for: location, checkingForExit: true)
        let exitCheckGeofenceIds = Set(exitCheckGeofences.compactMap { $0._id })
        let exitedGeofenceIds = lastKnownGeofenceIds.subtracting(exitCheckGeofenceIds)
        
        guard !exitedGeofenceIds.isEmpty else { return false }
        
        var timestamps = RadarSwift.bridge?.geofenceEntryTimestamps() ?? [:]
        var dwellFired = Set(RadarSwift.bridge?.dwellEventsFired() ?? [])
        
        for id in exitedGeofenceIds {
            RadarLogger.shared.debug("SyncManager: Detected geofence exit: \(id)")
            timestamps.removeValue(forKey: id)
            dwellFired.remove(id)
        }
        
        RadarSwift.bridge?.setGeofenceEntryTimestamps(timestamps)
        RadarSwift.bridge?.setDwellEventsFired(Array(dwellFired))
        return true
    }
    
    private static func checkForGeofenceDwell(
        currentGeofences: [RadarGeofence],
        currentGeofenceIds: Set<String>,
        lastKnownGeofenceIds: Set<String>
    ) -> Bool {
        let sdkConfig = RadarSettings.sdkConfiguration
        let projectDwellThreshold = sdkConfig?.defaultGeofenceDwellThreshold ?? 0
        let anyGeofenceHasDwell = currentGeofences.contains { $0.dwellThreshold != nil }
        
        guard projectDwellThreshold > 0 || anyGeofenceHasDwell else { return false }
        
        let timestamps = RadarSwift.bridge?.geofenceEntryTimestamps() ?? [:]
        let dwellFired = Set(RadarSwift.bridge?.dwellEventsFired() ?? [])
        
        for id in currentGeofenceIds.intersection(lastKnownGeofenceIds) {
            if dwellFired.contains(id) { continue }
            guard let entryTime = timestamps[id] else { continue }
            
            // Per-geofence threshold overrides project default
            let geofence = currentGeofences.first { $0._id == id }
            let thresholdMinutes: Double
            if let perGeofenceThreshold = geofence?.dwellThreshold {
                thresholdMinutes = perGeofenceThreshold.doubleValue
            } else if projectDwellThreshold > 0 {
                thresholdMinutes = Double(projectDwellThreshold)
            } else {
                continue
            }
            
            let elapsedMinutes = Date().timeIntervalSince(entryTime) / 60.0
            
            if elapsedMinutes >= thresholdMinutes {
                RadarLogger.shared.debug("SyncManager: Dwell threshold reached for geofence: \(id)")
                var updateDwellFired = dwellFired
                updateDwellFired.insert(id)
                RadarSwift.bridge?.setDwellEventsFired(Array(updateDwellFired))
                return true
            }
        }
        
        return false
    }
    
    private static func updateLastKnownSyncState(location: CLLocation) {
        // For geofences, only include those that passed stop detection (have entry timestamps)
        let timestamps = RadarSwift.bridge?.geofenceEntryTimestamps() ?? [:]
        
        let acceptedGeofenceIds = Array(timestamps.keys)
        RadarSwift.bridge?.setLastSyncedGeofenceIds(acceptedGeofenceIds)
        
        let currentPlaces = getPlaces(for: location)
        RadarSwift.bridge?.setLastSyncedPlaceIds(currentPlaces.compactMap { $0._id })
        
        let currentBeacons = getBeacons(for: location)
        RadarSwift.bridge?.setLastSyncedBeaconIds(currentBeacons.compactMap { $0._id })
    }
}
