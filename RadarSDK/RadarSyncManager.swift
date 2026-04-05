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
    
    static let syncStore = RadarFileStorage<RadarSyncState>(fileName: "radar_sync_state.json")
    
    private static let placeDetectionRadius: Double = 100.0
    private static let beaconRange: Double = 100.0
    private static let boundaryThresholdFraction: Double = 0.2
    private static let syncRegionIdentifierPrefix = "radar_synced_"
    nonisolated(unsafe) private static var syncTimer: Timer?
    
    nonisolated(unsafe) private static var previousSyncedGeofenceIds: [String]?
    nonisolated(unsafe) private static var previousSyncedBeaconIds: [String]?
    nonisolated(unsafe) private static var previousSyncedPlaceIds: [String]?
    
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
        
        if #available(iOS 13.0, *) {
            Task{
                do {
                    let response = try await RadarAPIClient.shared.fetchSyncRegion(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                    
                    let currentState = syncStore.read()
                    
                    if let center = response.regionCenter, let radius = response.regionRadius {
                        if currentState?.syncedRegionCenter == nil {
                            
                            RadarLogger.shared.info("SyncManager: Initial sync region set | lat = \(center.latitude); lng = \(center.longitude); radius = \(radius)")
                        } else if currentState?.syncedRegionCenter?.latitude != center.latitude ||
                                  currentState?.syncedRegionCenter?.longitude != center.longitude ||
                                  currentState?.syncedRegionRadius != radius {
                            
                            RadarLogger.shared.info("SyncManager: Sync region changed | lat = \(center.latitude); lng = \(center.longitude); radius = \(radius)")
                        }
                    } else {
                        if currentState?.syncedRegionCenter != nil {
                            RadarLogger.shared.info("SyncManager: Sync region cleared")
                        }
                    }
                    
                    syncStore.modify { state in
                        if state == nil { state = RadarSyncState() }
                        state?.syncedGeofences = response.geofences
                        state?.syncedPlaces = response.places
                        state?.syncedBeacons = response.beacons
                        state?.syncedRegionCenter = response.regionCenter
                        state?.syncedRegionRadius = response.regionRadius
                    }
                } catch {
                    RadarLogger.shared.warning("SyncManager: Sync region request failed")
                }
            }
        }
    }
    
    // MARK: - Track Decision
    
    @objc public static func shouldTrack(location: CLLocation, options: RadarTrackingOptions) -> Bool {
        guard options.syncLocations == .events else {
            RadarLogger.shared.debug("SyncManager: shouldTrack = YES | reason: syncLocations != events")
            return true
        }
        
        guard hasSyncedRegion() else {
            RadarLogger.shared.info("SyncManager: No synced region, should track")
            return true
        }
        
        if isNearSyncedRegionBoundary(location: location) {
            RadarLogger.shared.info("SyncManager: Near synced region boundary, refreshing")
            fetchSyncRegion()
        }
        
        if isOutsideSyncedRegion(location: location) {
            RadarLogger.shared.info("SyncManager: Outside synced region, should track")
            return true
        }
        
        if Radar.getTripOptions() != nil  && options.type != .onTrip {
            RadarLogger.shared.info("SyncManager: On active trip, should track")
            return true
        }
        
        let geofenceChanged = hasGeofenceStateChanged(location: location)
        let placeChanged = hasPlaceStateChanged(location: location)
        
        if geofenceChanged || placeChanged {
            RadarLogger.shared.info("SyncManager: shouldTrack = YES | reason: state changed (geofence=\(geofenceChanged), place=\(placeChanged)))")
            saveAndUpdateSyncState(location: location)
            return true
        }
        
        RadarLogger.shared.info("SyncManager: No state change detected, skipping track")
        return false
    }
    
    @objc public static func isNearSyncedRegionBoundary(location: CLLocation) -> Bool {
        guard let state = syncStore.read(),
              let center = state.syncedRegionCenter,
              let radius = state.syncedRegionRadius, radius > 0 else {
            return false
        }
        
        let regionCenter = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let distanceFromCenter = location.distance(from: regionCenter)
        let distanceFromEdge = radius - distanceFromCenter
        
        return distanceFromEdge <= (radius * boundaryThresholdFraction)
    }

    @objc public static func isOutsideSyncedRegion(location: CLLocation) -> Bool {
        guard let state = syncStore.read(),
              let center = state.syncedRegionCenter,
              let radius = state.syncedRegionRadius, radius > 0 else {
            return true
        }
        
        let regionCenter = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return location.distance(from: regionCenter) > radius
    }
    
    // MARK: - Geometry Helpers

    @objc public static func isPoint(_ point: CLLocation, insideCircleWithCenter center: CLLocationCoordinate2D, radius: Double) -> Bool {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let distance = centerLocation.distance(from: point)
        
        return distance <= radius
    }
    
    private static func isPoint(_ point: CLLocationCoordinate2D, insidePolygon polygon: [RadarCoordinateSwift]) -> Bool {
        guard polygon.count >= 3 else { return false }
        
        var inside = false
        var previousIndex = polygon.count - 1
        
        for currentIndex in 0..<polygon.count {
            let currentVertex = polygon[currentIndex].clLocationCoordinate2D
            let previousVertex = polygon[previousIndex].clLocationCoordinate2D
            
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
    
    private static func distanceToPolygonEdge(from point: CLLocationCoordinate2D, polygon: [RadarCoordinateSwift]) -> Double {
        guard polygon.count >= 3 else { return Double.greatestFiniteMagnitude }
        
        let pointLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
        var minimumDistance = Double.greatestFiniteMagnitude
        
        for currentIndex in 0..<polygon.count {
            let nextIndex = (currentIndex + 1) % polygon.count
            let edgeStart = polygon[currentIndex].clLocationCoordinate2D
            let edgeEnd = polygon[nextIndex].clLocationCoordinate2D
            
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
        geofence: RadarGeofenceSwift,
        location: CLLocation,
        accuracy: Double,
        checkingForExit: Bool,
        sdkConfig: RadarSdkConfiguration?
    ) -> Bool {
        let shouldBuffer = checkingForExit
            ? (sdkConfig?.bufferGeofenceExits ?? true)
            : (sdkConfig?.bufferGeofenceEntries ?? true)
        
        switch geofence.geometry {
        case .circle(let center, let radius):
            var effectiveRadius = radius
            if shouldBuffer { effectiveRadius += accuracy }
            return isPoint(location, insideCircleWithCenter: center.clLocationCoordinate2D, radius: effectiveRadius)
        case .polygon(let coordinates, let center, let radius):
            if isPoint(location.coordinate, insidePolygon: coordinates) {
                return true
            }
            if shouldBuffer {
                let bufferRadius = radius + accuracy
                guard isPoint(location, insideCircleWithCenter: center.clLocationCoordinate2D, radius: bufferRadius) else {
                    return false
                }
                return distanceToPolygonEdge(from: location.coordinate, polygon: coordinates) <= accuracy
            }
            return false
        }
    }
    
    static func getGeofences(for location: CLLocation, checkingForExit: Bool = false) -> [RadarGeofenceSwift] {
        guard let geofences = syncStore.read()?.syncedGeofences, !geofences.isEmpty else {
            return []
        }
        let sdkConfig = RadarSettings.sdkConfiguration
        let accuracy = max(location.horizontalAccuracy, 0)
        return geofences.filter {
            isLocationInside(geofence: $0, location: location, accuracy: accuracy, checkingForExit: checkingForExit, sdkConfig: sdkConfig)
        }
    }
    
    static func getBeacons(for location: CLLocation) -> [RadarBeaconSwift] {
        guard let beacons = syncStore.read()?.syncedBeacons, !beacons.isEmpty else {
            return []
        }
        
        return beacons.filter { beacon in
            guard let geometry = beacon.geometry else { return false }
            let beaconLocation = CLLocation(latitude: geometry.latitude, longitude: geometry.longitude)
            return location.distance(from: beaconLocation) <= beaconRange
        }
    }
    
    static func getPlaces(for location: CLLocation) -> [RadarPlaceSwift] {
        guard let places = syncStore.read()?.syncedPlaces, !places.isEmpty else {
            return []
        }
        
        return places.filter {
            isPoint(location, insideCircleWithCenter: $0.location.clLocationCoordinate2D, radius: placeDetectionRadius)
        }
    }
    
    // MARK: - State Detection
    
    @objc public static func hasSyncedRegion() -> Bool {
        let state = syncStore.read()
        return state?.syncedRegionCenter != nil && (state?.syncedRegionRadius ?? 0) > 0
    }
    
    @objc public static func hasGeofenceStateChanged(location: CLLocation) -> Bool {
        let state = syncStore.read() ?? RadarSyncState()
        let lastKnownGeofenceIds = Set(state.lastSyncedGeofenceIds)
        let currentGeofences = getGeofences(for: location)
        let currentGeofenceIds = Set(currentGeofences.map { $0.id })
        
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
    
    @objc public static func hasBeaconStateChanged(rangedBeaconIds: Set<String>) -> Bool {
        let state = syncStore.read() ?? RadarSyncState()
        let lastKnownBeaconIds = Set(state.lastSyncedBeaconIds)
        
        let enteredBeaconIds = rangedBeaconIds.subtracting(lastKnownBeaconIds)
        let exitedBeaconIds = lastKnownBeaconIds.subtracting(rangedBeaconIds)
        
        if !enteredBeaconIds.isEmpty {
            RadarLogger.shared.info("SyncManager: Detected beacon entry (BLE confirmed): \(enteredBeaconIds)")
        }
        
        if !exitedBeaconIds.isEmpty {
            RadarLogger.shared.info("SyncManager: Detected beacon exit (BLE confirmed): \(exitedBeaconIds)")
        }
        
        return rangedBeaconIds != lastKnownBeaconIds
    }
    
    @objc public static func hasPlaceStateChanged(location: CLLocation) -> Bool {
        let state = syncStore.read() ?? RadarSyncState()
        let lastKnownPlaceIds = Set(state.lastSyncedPlaceIds)
        let currentPlaces = getPlaces(for: location)
        let currentIds = Set(currentPlaces.compactMap { $0.id })
        
        let enteredPlaceIds = currentIds.subtracting(lastKnownPlaceIds)
        let exitedPlaceIds = lastKnownPlaceIds.subtracting(currentIds)
        
        if !enteredPlaceIds.isEmpty {
            RadarLogger.shared.info("SyncManager: Detected place entry: \(enteredPlaceIds)")
        }
        
        if !exitedPlaceIds.isEmpty {
            RadarLogger.shared.info("SyncManager: Detected place exit: \(exitedPlaceIds)")
        }
        
        return currentIds != lastKnownPlaceIds
    }

    private static func checkForGeofenceEntries(
        currentGeofences: [RadarGeofenceSwift],
        currentGeofenceIds: Set<String>,
        lastKnownGeofenceIds: Set<String>
    ) -> Bool {
        let enteredGeofenceIds = currentGeofenceIds.subtracting(lastKnownGeofenceIds)
        guard !enteredGeofenceIds.isEmpty else { return false }
        
        let sdkConfig = RadarSettings.sdkConfiguration
        let projectStopDetection = sdkConfig?.stopDetection ?? false
        let isStopped = RadarSwift.bridge?.isStopped() ?? false
        
        var timestamps = syncStore.read()?.geofenceEntryTimestamps ?? [:]
        var hasEntry = false
        
        for id in enteredGeofenceIds {
            let geofence = currentGeofences.first { $0.id == id }
            let requireStop: Bool
            if let geofenceStop = geofence?.geofenceStopDetection {
                requireStop = geofenceStop
            } else {
                requireStop = projectStopDetection
            }
            if requireStop && !isStopped {
                RadarLogger.shared.debug("SyncManager: Skipping geofence entry (stop detection, not stopped): \(id)")
                continue
            }
            RadarLogger.shared.debug("SyncManager: Detected geofence entry: \(id)")
            timestamps[id] = Date().timeIntervalSince1970
            hasEntry = true
        }
        if hasEntry {
            syncStore.modify { state in
                if state == nil { state = RadarSyncState() }
                state?.geofenceEntryTimestamps = timestamps
            }
        }
        return hasEntry
    }
    
    private static func checkForGeofenceExits(
        location: CLLocation,
        lastKnownGeofenceIds: Set<String>
    ) -> Bool {
        let exitCheckGeofences = getGeofences(for: location, checkingForExit: true)
        let exitCheckGeofenceIds = Set(exitCheckGeofences.map { $0.id })
        let exitedGeofenceIds = lastKnownGeofenceIds.subtracting(exitCheckGeofenceIds)
        
        guard !exitedGeofenceIds.isEmpty else { return false }
        
        for id in exitedGeofenceIds {
            RadarLogger.shared.debug("SyncManager: Detected geofence exit: \(id)")
        }
        
        syncStore.modify { state in
            guard state != nil else { return }
            for id in exitedGeofenceIds {
                state?.geofenceEntryTimestamps.removeValue(forKey: id)
                state?.dwellEventsFired.removeAll { $0 == id }
            }
        }
        return true
    }
    
    private static func checkForGeofenceDwell(
        currentGeofences: [RadarGeofenceSwift],
        currentGeofenceIds: Set<String>,
        lastKnownGeofenceIds: Set<String>
    ) -> Bool {
        let sdkConfig = RadarSettings.sdkConfiguration
        let projectDwellThreshold = sdkConfig?.defaultGeofenceDwellThreshold ?? 0
        let anyGeofenceHasDwell = currentGeofences.contains { $0.dwellThreshold != nil }
        
        guard projectDwellThreshold > 0 || anyGeofenceHasDwell else { return false }
        
        let state = syncStore.read() ?? RadarSyncState()
        let timestamps = state.geofenceEntryTimestamps
        let dwellFired = Set(state.dwellEventsFired)
        
        for id in currentGeofenceIds.intersection(lastKnownGeofenceIds) {
            if dwellFired.contains(id) { continue }
            guard let entryTimestamp = timestamps[id] else { continue }
            
            // Per-geofence threshold overrides project default
            let geofence = currentGeofences.first { $0.id == id }
            let thresholdMinutes: Double
            if let perGeofenceThreshold = geofence?.dwellThreshold {
                thresholdMinutes = perGeofenceThreshold
            } else if projectDwellThreshold > 0 {
                thresholdMinutes = Double(projectDwellThreshold)
            } else {
                continue
            }
            
            let entryDate = Date(timeIntervalSince1970: entryTimestamp)
            let elapsedMinutes = Date().timeIntervalSince(entryDate) / 60.0
            
            if elapsedMinutes >= thresholdMinutes {
                RadarLogger.shared.debug("SyncManager: Dwell threshold reached for geofence: \(id)")
                syncStore.modify { state in
                    state?.dwellEventsFired.append(id)
                }
                return true
            }
        }
        
        return false
    }
    
    private static func updateLastKnownSyncState(location: CLLocation) {
        // For geofences, only include those that passed stop detection (have entry timestamps)
        let timestamps = syncStore.read()?.geofenceEntryTimestamps ?? [:]
        let acceptedGeofenceIds = Array(timestamps.keys)
        let currentPlaceIds = getPlaces(for: location).map { $0.id }
        
        RadarLogger.shared.info(
            "SyncManager: Optimistic update | " +
            "geofences=\(acceptedGeofenceIds) " +
            "places=\(currentPlaceIds) "
        )
        
        syncStore.modify { state in
            if state == nil { state = RadarSyncState() }
            state?.lastSyncedGeofenceIds = acceptedGeofenceIds
            state?.lastSyncedPlaceIds = currentPlaceIds
        }
    }
    
    // MARK: - Server reconciliation
    
    private static func saveAndUpdateSyncState(location: CLLocation) {
        let state = syncStore.read() ?? RadarSyncState()
        previousSyncedGeofenceIds = state.lastSyncedGeofenceIds
        previousSyncedPlaceIds = state.lastSyncedPlaceIds
        
        RadarLogger.shared.info(
            "SyncManager: Saving previous state before optimistic update | " +
            "geofences=\(previousSyncedGeofenceIds?.count ?? 0) " +
            "places=\(previousSyncedPlaceIds?.count ?? 0) "
        )
        
        updateLastKnownSyncState(location: location)
    }
    
    @objc public static func reconcileSyncState(user: RadarUser) {
        let serverGeofenceIds = user.geofences?.compactMap { $0._id } ?? []
        let serverPlaceIds: [String] = user.place?._id != nil ? [user.place!._id] : []
        let serverBeaconIds = user.beacons?.compactMap { $0._id } ?? []
        
        let state = syncStore.read() ?? RadarSyncState()
        let clientGeofenceIds = state.lastSyncedGeofenceIds
        let clientPlaceIds = state.lastSyncedPlaceIds
        let clientBeaconIds = state.lastSyncedBeaconIds
        
        let geofenceMismatch = Set(serverGeofenceIds) != Set(clientGeofenceIds)
        let placeMismatch = Set(serverPlaceIds) != Set(clientPlaceIds)
        let beaconMismatch = Set(serverBeaconIds) != Set(clientBeaconIds)
        
        if geofenceMismatch || placeMismatch || beaconMismatch {
            
            if geofenceMismatch {
                let serverOnly = Set(serverGeofenceIds).subtracting(Set(clientGeofenceIds))
                let clientOnly = Set(clientGeofenceIds).subtracting(Set(serverGeofenceIds))
                if !serverOnly.isEmpty {
                    RadarLogger.shared.info("SyncManager: Server added geofences: \(serverOnly)")
                }
                if !clientOnly.isEmpty {
                    RadarLogger.shared.info("SyncManager: Server removed geofences: \(clientOnly)")
                }
            }
            
            if beaconMismatch {
                let serverOnly = Set(serverBeaconIds).subtracting(Set(clientBeaconIds))
                let clientOnly = Set(clientBeaconIds).subtracting(Set(serverBeaconIds))
                if !serverOnly.isEmpty {
                    RadarLogger.shared.info("SyncManager: Server added beacons: \(serverOnly)")
                }
                if !clientOnly.isEmpty {
                    RadarLogger.shared.info("SyncManager: Server removed beacons: \(clientOnly)")
                }
            }
            
            if placeMismatch {
                let serverOnly = Set(serverPlaceIds).subtracting(Set(clientPlaceIds))
                let clientOnly = Set(clientPlaceIds).subtracting(Set(serverPlaceIds))
                if !serverOnly.isEmpty {
                    RadarLogger.shared.info("SyncManager: Server added places: \(serverOnly)")
                }
                if !clientOnly.isEmpty {
                    RadarLogger.shared.info("SyncManager: Server removed places: \(clientOnly)")
                }
            }
            
            syncStore.modify { state in
                if state == nil { state = RadarSyncState() }
                state?.lastSyncedGeofenceIds = serverGeofenceIds
                state?.lastSyncedPlaceIds = serverPlaceIds
                state?.lastSyncedBeaconIds = serverBeaconIds
                
                // Clean up timestamps for geofences the server doesn't recognize
                let serverSet = Set(serverGeofenceIds)
                let cleanedTimestamps = state?.geofenceEntryTimestamps.filter { serverSet.contains($0.key) } ?? [:]
                let cleanedDwell = state?.dwellEventsFired.filter { serverSet.contains($0) } ?? []
                state?.geofenceEntryTimestamps = cleanedTimestamps
                state?.dwellEventsFired = cleanedDwell
            }
        } else {
            RadarLogger.shared.info("SyncManager: Client state matches server")
        }
        clearPreviousState()
    }
    
    @objc public static func saveBeaconState(beaconIds: [String]) {
        previousSyncedBeaconIds = syncStore.read()?.lastSyncedBeaconIds
        
        RadarLogger.shared.info("SyncManager: Saving beacon state | previous=\(previousSyncedBeaconIds?.count ?? 0) new=\(beaconIds.count)")

        syncStore.modify { state in
            if state == nil { state = RadarSyncState() }
            state?.lastSyncedBeaconIds = beaconIds
        }
    }
    
    @objc public static func rollbackSyncState() {
        guard previousSyncedGeofenceIds != nil || previousSyncedPlaceIds != nil || previousSyncedBeaconIds != nil else { return }

        RadarLogger.shared.info("SyncManager: Track failed, rolling back to previous sync state")
        
        syncStore.modify { state in
            if state == nil { state = RadarSyncState() }
            if let ids = previousSyncedGeofenceIds { state?.lastSyncedGeofenceIds = ids }
            if let ids = previousSyncedPlaceIds { state?.lastSyncedPlaceIds = ids }
            if let ids = previousSyncedBeaconIds { state?.lastSyncedBeaconIds = ids }
        }
        clearPreviousState()
    }
    
    private static func clearPreviousState() {
        previousSyncedGeofenceIds = nil
        previousSyncedPlaceIds = nil
        previousSyncedBeaconIds = nil
    }
    
    // MARK: - Beacon Bridging
    
    @objc public static func getObjCBeacons(for location: CLLocation) -> [RadarBeacon] {
        return getBeacons(for: location).compactMap { swiftBeacon in
            let geometry = RadarCoordinate(coordinate: CLLocationCoordinate2D(
                latitude: swiftBeacon.geometry?.latitude ?? 0,
                longitude: swiftBeacon.geometry?.longitude ?? 0
            ))!
            return RadarBeacon(
                id: swiftBeacon.id,
                description: swiftBeacon.description,
                tag: swiftBeacon.tag ?? "",
                externalId: swiftBeacon.externalId ?? "",
                uuid: swiftBeacon.uuid,
                major: swiftBeacon.major,
                minor: swiftBeacon.minor,
                metadata: nil,
                geometry: geometry
            )
        }
    }
}
