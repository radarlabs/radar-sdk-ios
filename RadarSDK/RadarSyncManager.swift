//
//  RadarSyncManager.swift
//  RadarSDK
//
//  Created by Alan Charles on 1/29/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

@objc(RadarSyncManager)
public final class RadarSyncManager: NSObject {

    static let syncStore = RadarFileStorageObject<RadarSyncState>(fileName: "radar_sync_state.json")

    private static let placeDetectionRadius: Double = 75.0
    private static let beaconRange: Double = 100.0
    private static let placeExitBuffer: Double = 50.0
    private static let boundaryThresholdFraction: Double = 0.2
    private static let syncRegionIdentifierPrefix = "radar_synced_"
    nonisolated(unsafe) private static var syncTimer: Timer?

    nonisolated(unsafe) private static var previousSyncedGeofenceIds: [String]?
    nonisolated(unsafe) private static var previousSyncedBeaconIds: [String]?
    nonisolated(unsafe) private static var previousSyncedPlaceIds: [String]?

    nonisolated(unsafe) static var rejectedPlaceIds: Set<String> = []
    nonisolated(unsafe) static var rejectedAtLocation: CLLocation?
    nonisolated(unsafe) static var lastPlaceCheckLocation: CLLocation?

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

        Task {
            do {
                let response = try await RadarAPIClient.shared.fetchSyncRegion(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )

                let currentState = syncStore.read()

                if let center = response.regionCenter, let radius = response.regionRadius {
                    if currentState?.syncedRegionCenter == nil {

                        RadarLogger.shared.info("SyncManager: Initial sync region set | lat = \(center.latitude); lng = \(center.longitude); radius = \(radius)")
                    } else if currentState?.syncedRegionCenter?.latitude != center.latitude || currentState?.syncedRegionCenter?.longitude != center.longitude
                        || currentState?.syncedRegionRadius != radius
                    {

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
            fetchSyncRegion()
            return true
        }

        if Radar.getTripOptions() != nil && options.type != .onTrip {
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
            let radius = state.syncedRegionRadius, radius > 0
        else {
            return false
        }

        let regionCenter = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let distanceFromCenter = location.distance(from: regionCenter)
        let distanceFromEdge = radius - distanceFromCenter

        return distanceFromEdge >= 0 && distanceFromEdge <= (radius * boundaryThresholdFraction)
    }

    @objc public static func isOutsideSyncedRegion(location: CLLocation) -> Bool {
        guard let state = syncStore.read(),
            let center = state.syncedRegionCenter,
            let radius = state.syncedRegionRadius, radius > 0
        else {
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
                let edgeLongitudeAtPointLatitude =
                    previousVertex.longitude
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
        let fractionAlongSegment = max(
            0,
            min(
                1,
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
        let shouldBuffer =
            checkingForExit
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
        let isStopped = RadarSwift.bridge?.isStopped() ?? false
        if !isStopped { return [] }

        let closest =
            places
            .compactMap { place -> (RadarPlaceSwift, Double)? in
                let radius = (place.geometryRadius ?? 0.0) + placeDetectionRadius
                let placeLocation = CLLocation(latitude: place.location.latitude, longitude: place.location.longitude)
                let distance = location.distance(from: placeLocation)
                return distance <= radius ? (place, distance) : nil
            }
            .min { $0.1 < $1.1 }
            .map { $0.0 }

        if let matched = closest {
            RadarLogger.shared.debug("SyncManager: getPlaces matched \(matched.id) (geoR=\(String(describing: matched.geometryRadius)))")
            return [matched]
        }
        return []
    }

    // MARK: - State Detection

    @objc public static func hasSyncedRegion() -> Bool {
        let state = syncStore.read()
        return state?.syncedRegionCenter != nil && (state?.syncedRegionRadius ?? 0) > 0
    }

    @objc public static func hasGeofenceStateChanged(location: CLLocation) -> Bool {
        let state = syncStore.read() ?? RadarSyncState()
        let lastKnownIds = Set(state.lastSyncedGeofenceIds)

        let entries = getGeofenceEntries(for: location, against: lastKnownIds)
        if !entries.isEmpty {
            let ids = entries.map { $0.id }
            RadarLogger.shared.debug("SyncManager: Detected geofence entries: \(ids)")
            recordGeofenceEntryTimestamps(ids)
            return true
        }

        let exits = getGeofenceExits(for: location, against: lastKnownIds)
        if !exits.isEmpty {
            let ids = exits.map { $0.id }
            RadarLogger.shared.debug("SyncManager: Detected geofence exits: \(ids)")
            clearGeofenceEntryState(ids)
            return true
        }

        let dwells = getGeofenceDwells(for: location, against: lastKnownIds)
        if !dwells.isEmpty {
            for geofence in dwells {
                RadarLogger.shared.debug("SyncManager: Dwell threshold reached for geofence: \(geofence.id)")
                markDwellFired(geofence.id)
            }
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
        lastPlaceCheckLocation = location

        if let rejectedLocation = rejectedAtLocation, !rejectedPlaceIds.isEmpty {
            let moved = location.distance(from: rejectedLocation) > max(rejectedLocation.horizontalAccuracy, 15.0)
            let accuracyImproved = rejectedLocation.horizontalAccuracy > 100.0 && location.horizontalAccuracy < 50.0
            if moved || accuracyImproved {
                RadarLogger.shared.debug(
                    "SyncManager: Clearing place rejections | moved=\(location.distance(from: rejectedLocation)) accuracy=\(location.horizontalAccuracy) wasAccuracy=\(rejectedLocation.horizontalAccuracy)"
                )
                rejectedPlaceIds = []
                rejectedAtLocation = nil
            }
        }

        let state = syncStore.read() ?? RadarSyncState()
        let lastKnownPlaceIds = Set(state.lastSyncedPlaceIds)
        let allPlaces = state.syncedPlaces ?? []

        // Check for exits — user moved beyond geometryRadius + 50m
        if !lastKnownPlaceIds.isEmpty {
            if let lastPlace = allPlaces.first(where: { lastKnownPlaceIds.contains($0.id) }) {
                let exitRadius = (lastPlace.geometryRadius ?? 0.0) + placeExitBuffer
                let placeLocation = CLLocation(latitude: lastPlace.location.latitude, longitude: lastPlace.location.longitude)
                if location.distance(from: placeLocation) > exitRadius {
                    RadarLogger.shared.info("SyncManager: Detected place exit: \(lastPlace.id)")
                    return true
                }
            }
        }

        // Check for entries — stopped + within geometryRadius + 75m, excluding rejected places
        let currentPlaces = getPlaces(for: location)
        let currentIds = Set(currentPlaces.compactMap { $0.id })
        let enteredPlaceIds = currentIds.subtracting(lastKnownPlaceIds).subtracting(rejectedPlaceIds)

        if !enteredPlaceIds.isEmpty {
            if !lastKnownPlaceIds.isEmpty {
                if let lastPlace = allPlaces.first(where: { lastKnownPlaceIds.contains($0.id) }) {
                    let exitRadius = (lastPlace.geometryRadius ?? 0.0) + placeExitBuffer
                    let placeLocation = CLLocation(latitude: lastPlace.location.latitude, longitude: lastPlace.location.longitude)
                    if location.distance(from: placeLocation) <= exitRadius {
                        RadarLogger.shared.debug("SyncManager: Skipping place switch (still within exit radius of last place)")
                        return false
                    }
                }
            }
            RadarLogger.shared.info("SyncManager: Detected place entry: \(enteredPlaceIds)")
            return true
        }

        return false
    }

    private static func updateLastKnownSyncState(location: CLLocation) {
        // For geofences, only include those that passed stop detection (have entry timestamps)
        let timestamps = syncStore.read()?.geofenceEntryTimestamps ?? [:]
        let acceptedGeofenceIds = Array(timestamps.keys)
        let currentPlaceIds = getPlaces(for: location).map { $0.id }.filter { !rejectedPlaceIds.contains($0) }

        RadarLogger.shared.info(
            "SyncManager: Optimistic update | " + "geofences=\(acceptedGeofenceIds) " + "places=\(currentPlaceIds) "
        )

        syncStore.modify { state in
            if state == nil { state = RadarSyncState() }
            state?.lastSyncedGeofenceIds = acceptedGeofenceIds
            state?.lastSyncedPlaceIds = currentPlaceIds
        }
    }

    // MARK: - Geofence Diff

    static func getGeofenceEntries(for location: CLLocation, against lastKnownIds: Set<String>) -> [RadarGeofenceSwift] {
        let currentGeofences = getGeofences(for: location)
        let currentGeofenceIds = Set(currentGeofences.map { $0.id })
        let enteredIds = currentGeofenceIds.subtracting(lastKnownIds)
        guard !enteredIds.isEmpty else { return [] }

        let projectStopDetection = RadarSettings.sdkConfiguration?.stopDetection ?? false
        let isStopped = RadarSwift.bridge?.isStopped() ?? false

        return currentGeofences.filter { geofence in
            guard enteredIds.contains(geofence.id) else { return false }
            let requireStop = geofence.geofenceStopDetection ?? projectStopDetection
            if requireStop && !isStopped {
                RadarLogger.shared.debug("SyncManager: Skipping geofence entry (stop detection, not stopped): \(geofence.id)")
                return false
            }
            return true
        }
    }

    static func getGeofenceExits(for location: CLLocation, against lastKnownIds: Set<String>) -> [RadarGeofenceSwift] {
        let exitCheckGeofences = getGeofences(for: location, checkingForExit: true)
        let exitCheckIds = Set(exitCheckGeofences.map { $0.id })
        let exitedIds = lastKnownIds.subtracting(exitCheckIds)
        guard !exitedIds.isEmpty else { return [] }

        let allSyncedGeofences = syncStore.read()?.syncedGeofences ?? []
        return allSyncedGeofences.filter { exitedIds.contains($0.id) }
    }

    static func getGeofenceDwells(for location: CLLocation, against lastKnownIds: Set<String>) -> [RadarGeofenceSwift] {
        let projectDwellThreshold = RadarSettings.sdkConfiguration?.defaultGeofenceDwellThreshold ?? 0
        let currentGeofences = getGeofences(for: location)
        let currentGeofenceIds = Set(currentGeofences.map { $0.id })
        let anyGeofenceHasDwell = currentGeofences.contains { $0.dwellThreshold != nil }

        guard projectDwellThreshold > 0 || anyGeofenceHasDwell else { return [] }

        let state = syncStore.read() ?? RadarSyncState()
        let timestamps = state.geofenceEntryTimestamps
        let dwellFired = Set(state.dwellEventsFired)
        let now = Date()

        return currentGeofences.filter { geofence in
            guard currentGeofenceIds.intersection(lastKnownIds).contains(geofence.id) else { return false }
            guard !dwellFired.contains(geofence.id) else { return false }
            guard let entryTimestamp = timestamps[geofence.id] else { return false }

            let thresholdMinutes: Double
            if let perGeofenceThreshold = geofence.dwellThreshold {
                thresholdMinutes = perGeofenceThreshold
            } else if projectDwellThreshold > 0 {
                thresholdMinutes = Double(projectDwellThreshold)
            } else {
                return false
            }

            let elapsedMinutes = now.timeIntervalSince(Date(timeIntervalSince1970: entryTimestamp)) / 60.0
            return elapsedMinutes >= thresholdMinutes
        }
    }

    // MARK: - Beacon Diff

    static func getBeaconEntries(for location: CLLocation, against lastKnownIds: Set<String>) -> [RadarBeaconSwift] {
        let currentBeacons = getBeacons(for: location)
        let currentBeaconIds = Set(currentBeacons.map { $0.id })
        let enteredIds = currentBeaconIds.subtracting(lastKnownIds)

        guard !enteredIds.isEmpty else { return [] }
        return currentBeacons.filter { enteredIds.contains($0.id) }
    }

    static func getBeaconExits(for location: CLLocation, against lastKnownIds: Set<String>) -> [RadarBeaconSwift] {
        let currentBeacons = getBeacons(for: location)
        let currentIds = Set(currentBeacons.map { $0.id })
        let exitedIds = lastKnownIds.subtracting(currentIds)

        guard !exitedIds.isEmpty else { return [] }

        let allSyncedBeacons = syncStore.read()?.syncedBeacons ?? []
        return allSyncedBeacons.filter { exitedIds.contains($0.id) }
    }

    // MARK: - Geofence State Mutations

    static func recordGeofenceEntryTimestamps(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        syncStore.modify { state in
            if state == nil { state = RadarSyncState() }
            for id in ids {
                state?.geofenceEntryTimestamps[id] = now
            }
        }
    }

    static func clearGeofenceEntryState(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        syncStore.modify { state in
            guard state != nil else { return }
            for id in ids {
                state?.geofenceEntryTimestamps.removeValue(forKey: id)
                state?.dwellEventsFired.removeAll { $0 == id }
            }
        }
    }

    // MARK: - Server reconciliation

    private static func saveAndUpdateSyncState(location: CLLocation) {
        let state = syncStore.read() ?? RadarSyncState()
        previousSyncedGeofenceIds = state.lastSyncedGeofenceIds
        previousSyncedPlaceIds = state.lastSyncedPlaceIds

        RadarLogger.shared.info(
            "SyncManager: Saving previous state before optimistic update | " + "geofences=\(previousSyncedGeofenceIds?.count ?? 0) " + "places=\(previousSyncedPlaceIds?.count ?? 0) "
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
                    rejectedPlaceIds = rejectedPlaceIds.union(clientOnly)
                    rejectedAtLocation = lastPlaceCheckLocation
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

    @objc public static func markDwellFired(_ geofenceId: String) {
        syncStore.modify { state in
            guard state != nil else { return }
            if !(state?.dwellEventsFired.contains(geofenceId) ?? false) {
                state?.dwellEventsFired.append(geofenceId)
            }
        }
    }

    // MARK: - Beacon Bridging

    @objc public static func getObjCBeacons(for location: CLLocation) -> [RadarBeacon] {
        return getBeacons(for: location).compactMap { swiftBeacon in
            let geometry = RadarCoordinate(
                coordinate: CLLocationCoordinate2D(
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
    
    // MARK: - QA map display surface
    // Read-only snapshot accessors over the locally-cached synced data, exposed
    // for the example app's MapView.

    public static func getSyncedRegion() -> CLCircularRegion? {
        guard let state = syncStore.read(),
            let center = state.syncedRegionCenter,
            let radius = state.syncedRegionRadius, radius > 0
        else { return nil }
        return CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude),
            radius: radius,
            identifier: "\(syncRegionIdentifierPrefix)region"
        )
    }

    public static func getSyncedGeofences() -> [RadarSyncedGeofenceSnapshot] {
        syncStore.read()?.syncedGeofences?.map(RadarSyncedGeofenceSnapshot.init(from:)) ?? []
    }

    public static func getSyncedPlaces() -> [RadarSyncedPlaceSnapshot] {
        syncStore.read()?.syncedPlaces?.map(RadarSyncedPlaceSnapshot.init(from:)) ?? []
    }

    public static func getSyncedBeacons() -> [RadarSyncedBeaconSnapshot] {
        syncStore.read()?.syncedBeacons?.map(RadarSyncedBeaconSnapshot.init(from:)) ?? []
    }
}

// MARK: - Snapshot types

public struct RadarSyncedGeofenceSnapshot {
    public let id: String
    public let description: String
    public let tag: String?
    public let externalId: String?
    public let geometry: Geometry

    public enum Geometry {
        case circle(center: CLLocationCoordinate2D, radius: Double)
        case polygon(
            coordinates: [CLLocationCoordinate2D],
            center: CLLocationCoordinate2D,
            radius: Double
        )

        public var center: CLLocationCoordinate2D {
            switch self {
            case .circle(let c, _): return c
            case .polygon(_, let c, _): return c
            }
        }
    }

    init(from swift: RadarGeofenceSwift) {
        self.id = swift.id
        self.description = swift.description
        self.tag = swift.tag
        self.externalId = swift.externalId
        switch swift.geometry {
        case .circle(let c, let r):
            self.geometry = .circle(
                center: CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude),
                radius: r
            )
        case .polygon(let coords, let c, let r):
            self.geometry = .polygon(
                coordinates: coords.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                },
                center: CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude),
                radius: r
            )
        }
    }
}

public struct RadarSyncedPlaceSnapshot {
    public let id: String
    public let name: String
    public let categories: [String]
    public let group: String?
    public let location: CLLocationCoordinate2D

    init(from swift: RadarPlaceSwift) {
        self.id = swift.id
        self.name = swift.name
        self.categories = swift.categories
        self.group = swift.group
        self.location = CLLocationCoordinate2D(
            latitude: swift.location.latitude,
            longitude: swift.location.longitude
        )
    }
}

public struct RadarSyncedBeaconSnapshot {
    public let id: String
    public let description: String?
    public let tag: String?
    public let uuid: String
    public let major: String
    public let minor: String
    public let location: CLLocationCoordinate2D?

    init(from swift: RadarBeaconSwift) {
        self.id = swift.id
        self.description = swift.description
        self.tag = swift.tag
        self.uuid = swift.uuid
        self.major = swift.major
        self.minor = swift.minor
        if let geom = swift.geometry {
            self.location = CLLocationCoordinate2D(latitude: geom.latitude, longitude: geom.longitude)
        } else {
            self.location = nil
        }
    }
}
