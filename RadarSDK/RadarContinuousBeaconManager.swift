//
//  RadarContinuousBeaconManager.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit

/// Continuously ranges nearby beacons while the app is in the foreground, so `trackVerified` can
/// attach the last ranging result without waiting on a one-shot ranging window.
///
/// Uses its own searches and `CLLocationManager`, separate from the one-shot ranging in
/// `RadarOneShotBeaconManager`. It searches for up to `RadarNearbyBeaconSearch.limit` nearby
/// beacons, ranges them, and searches again every `refreshInterval`. Ranging pauses when the app
/// enters the background and resumes when it returns to the foreground, until `stop()` is called.
@MainActor
@objc(RadarContinuousBeaconManager)
class RadarContinuousBeaconManager: NSObject, CLLocationManagerDelegate {

    @objc static let shared = RadarContinuousBeaconManager()

    /// Beacons not ranged within this many seconds are treated as out of range.
    static let maxBeaconAge: TimeInterval = 5

    /// How often the beacons being ranged are searched again, so they follow the device.
    static let refreshInterval: TimeInterval = 60

    /// Requests farther than this from where the beacons were searched aren't served, since the
    /// beacons near them may not have been searched. A fast-moving device would otherwise get
    /// another place's beacons until the next refresh.
    static let maxSearchDistance: CLLocationDistance = 100

    /// How long ranging runs before its beacons are used, matching the one-shot ranging window.
    /// Until then, an empty result could just mean CoreLocation hasn't heard the beacons yet.
    static let minRangingDuration: TimeInterval = 5

    var permissionsHelper: RadarPermissionsHelping = RadarPermissionsHelperSwift()
    var now: () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    var notificationCenter: NotificationCenter = .default
    var sleep: @MainActor (TimeInterval) async -> Void = { seconds in
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
    /// Searches beacons near a location, or returns `nil` if the search failed.
    var searchBeacons: @MainActor (CLLocation) async -> SearchResult? = { location in
        do {
            return SearchResult(try await RadarNearbyBeaconSearch.search(near: location))
        } catch is CancellationError {
            // A newer search replaced this one.
            return nil
        } catch let error as URLError where error.code == .cancelled {
            return nil
        } catch {
            RadarLogger.shared.log(
                level: .debug, message: "Continuous beacon manager search failed | error = \(error.localizedDescription)")
            return nil
        }
    }

    private(set) lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    private(set) var started = false

    // Where and when `searchResult` was searched.
    private(set) var searchLocation: CLLocation?
    private(set) var searchedAt: TimeInterval?

    // The beacons being ranged, and the search they came from.
    private(set) var searchResult: SearchResult?

    // The running search, if any. Cancelled when a newer search replaces it.
    private var searchTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?

    // What CoreLocation is ranging, and when it started.
    private var rangingConstraints: [CLBeaconIdentityConstraint] = []
    private var rangingStartedAt: TimeInterval = 0

    // The last ranging result: each beacon ranged, and when it was last ranged.
    private var rangedBeacons: [String: (beacon: RadarBeacon, lastRanged: TimeInterval)] = [:]
    private var observers: [NSObjectProtocol] = []

    var ranging: Bool { !rangingConstraints.isEmpty }

    // MARK: - Control

    func start() {
        guard !started else {
            RadarLogger.shared.log(level: .debug, message: "Continuous beacon manager already started")
            return
        }

        RadarLogger.shared.log(level: .debug, message: "Starting continuous beacon manager")

        started = true
        addObservers()
        resume()
    }

    func stop() {
        RadarLogger.shared.log(level: .debug, message: "Stopping continuous beacon manager")

        started = false
        removeObservers()
        reset()
    }

    /// Beacons ranged near `location` within `maxBeaconAge`. An empty array means no beacons are
    /// nearby.
    ///
    /// Returns `nil` if continuous ranging can't serve the request: it's stopped, it isn't
    /// ranging, it has ranged for less than `minRangingDuration`, or its beacons were searched
    /// more than `maxSearchDistance` from `location`. Range beacons once instead, with a
    /// `RadarNearbyBeaconSearch` from `location`, and pass the result to `onSearched` so later
    /// requests there can be served.
    @objc(beaconsNear:)
    func beacons(near location: CLLocation) -> [RadarBeacon]? {
        guard started else { return nil }

        if ranging, isNearSearchLocation(location) {
            guard now() - rangingStartedAt >= Self.minRangingDuration else {
                RadarLogger.shared.log(level: .debug, message: "Continuous beacon manager ranging not ready")
                return nil
            }
            return currentBeacons()
        }

        // Forget the old search, and wait for the caller's search from `location`.
        reset()
        return nil
    }

    /// Ranges the beacons from a `RadarNearbyBeaconSearch` made from `location`, or `nil` if it
    /// failed, replacing any search still running. Schedules the next refresh.
    func onSearched(from location: CLLocation, result: SearchResult?) {
        guard started else { return }

        searchTask?.cancel()
        searchTask = nil
        scheduleRefresh(after: Self.refreshInterval)
        guard let result else {
            RadarLogger.shared.log(level: .debug, message: "Continuous beacon manager search failed")
            return
        }

        guard permissionsGranted() else { return }

        update(result, searchedFrom: location)
    }

    /// `onSearched` for the Objective-C search in `trackVerified`.
    @objc(handleSearchFrom:status:beaconUUIDs:beacons:)
    func handleSearch(from location: CLLocation, status: RadarStatus, beaconUUIDs: [String]?, beacons: [RadarBeacon]?) {
        onSearched(from: location, result: SearchResult(status: status, uuids: beaconUUIDs, beacons: beacons))
    }

    /// Replaces the beacons being ranged with `result`, searched from `location`.
    func update(_ result: SearchResult, searchedFrom location: CLLocation) {
        guard started else { return }

        let previousKeys = searchResult.map { Self.keys(for: $0.constraints) } ?? []
        searchLocation = location
        searchedAt = now()
        searchResult = result
        if Self.keys(for: result.constraints) == previousKeys, ranging {
            return
        }

        startRanging()
    }

    private func currentBeacons() -> [RadarBeacon] {
        let cutoff = now() - Self.maxBeaconAge
        rangedBeacons = rangedBeacons.filter { $0.value.lastRanged >= cutoff }
        return rangedBeacons.values.map(\.beacon)
    }

    /// Stops ranging and forgets the beacons, invalidating any search that's still running.
    private func reset() {
        pause()
        refreshTask?.cancel()
        refreshTask = nil
        searchResult = nil
        searchLocation = nil
        searchedAt = nil
        searchTask?.cancel()
        searchTask = nil
    }

    // MARK: - Searching

    /// Resumes ranging the last search's beacons, if any, and searches again from the last known
    /// location, unless the last search is less than `refreshInterval` old.
    private func resume() {
        guard started, !ranging else { return }

        guard permissionsGranted() else { return }

        guard permissionsHelper.isRangingAvailable() else {
            RadarLogger.shared.log(level: .debug, message: "Continuous beacon manager not started: ranging not available")
            return
        }

        guard isForeground() else { return }

        if let searchResult, !searchResult.constraints.isEmpty {
            startRanging()
        }

        if let searchedAt, now() - searchedAt < Self.refreshInterval {
            scheduleRefresh(after: Self.refreshInterval - (now() - searchedAt))
            return
        }

        guard let location = RadarSwift.bridge?.lastLocation() else {
            RadarLogger.shared.log(level: .debug, message: "Continuous beacon manager waiting for a location to search beacons")
            return
        }

        search(from: location)
    }

    /// Searches beacons near `location` and ranges them, then schedules the next search.
    private func search(from location: CLLocation) {
        refreshTask?.cancel()
        refreshTask = nil
        searchTask?.cancel()
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await searchBeacons(location)
            guard !Task.isCancelled else {
                RadarLogger.shared.log(level: .debug, message: "Continuous beacon manager ignoring stale search")
                return
            }
            searchTask = nil
            onSearched(from: location, result: result)
        }
    }

    private func scheduleRefresh(after delay: TimeInterval) {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor [weak self] in
            await self?.sleep(delay)
            guard !Task.isCancelled, let self else { return }
            guard started, isForeground(), permissionsHelper.isRangingAvailable(),
                let location = RadarSwift.bridge?.lastLocation()
            else { return }
            search(from: location)
        }
    }

    private func permissionsGranted() -> Bool {
        let status = permissionsHelper.locationAuthorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            RadarLogger.shared.log(level: .debug, message: "Continuous beacon manager not started: location not authorized")
            return false
        }
        return true
    }

    private func isForeground() -> Bool {
        RadarSwift.bridge?.isForeground() ?? false
    }

    private func isNearSearchLocation(_ location: CLLocation) -> Bool {
        guard let searchLocation else { return false }
        let distance = location.distance(from: searchLocation)
        guard distance <= Self.maxSearchDistance else {
            RadarLogger.shared.log(
                level: .debug, message: "Continuous beacon manager searched too far from location | distance = \(Int(distance))m")
            return false
        }
        return true
    }

    // MARK: - Ranging

    /// Stops ranging and forgets the last ranging result.
    private func pause() {
        for constraint in rangingConstraints {
            locationManager.stopRangingBeacons(satisfying: constraint)
        }
        rangingConstraints = []
        rangedBeacons.removeAll()
    }

    private func startRanging() {
        guard isForeground() else {
            // Don't keep ranging beacons from an older search.
            pause()
            return
        }

        pause()
        let constraints = searchResult?.constraints ?? []
        guard !constraints.isEmpty else { return }

        for constraint in constraints {
            RadarLogger.shared.log(level: .debug, message: "Continuous beacon manager ranging | \(Self.key(for: constraint))")
            locationManager.startRangingBeacons(satisfying: constraint)
        }
        rangingConstraints = constraints
        rangingStartedAt = now()
    }

    /// A ranged beacon reading, copied out of `CLBeacon` so it can cross to the main actor.
    struct RangedBeacon: Sendable {
        let uuid: String
        let major: String
        let minor: String
        let rssi: Int
    }

    func handleRanged(_ entries: [RangedBeacon]) {
        guard ranging, let bridge = RadarSwift.bridge else { return }

        let timestamp = now()
        for entry in entries where entry.rssi != 0 {
            let key = "\(entry.uuid.uppercased())-\(entry.major)-\(entry.minor)"
            if let existing = rangedBeacons[key] {
                bridge.setRssi(entry.rssi, onBeacon: existing.beacon)
                rangedBeacons[key] = (existing.beacon, timestamp)
            } else {
                let beacon = bridge.createBeacon(uuid: entry.uuid, major: entry.major, minor: entry.minor, rssi: entry.rssi)
                rangedBeacons[key] = (beacon, timestamp)
            }
        }
    }

    /// CoreLocation reports `rangingUnavailable` when Bluetooth or Location Services is off, and
    /// then stops reporting beacons, so ranging would otherwise keep reporting that no beacons are
    /// nearby. There's no callback when ranging becomes available again, so it resumes on the next
    /// foreground, refresh, or `trackVerified` search.
    func handleRangingFailed(_ constraintKey: String, error: Error) {
        RadarLogger.shared.log(
            level: .debug,
            message: "Continuous beacon manager failed to range | \(constraintKey); error = \(error.localizedDescription)")

        guard (error as? CLError)?.code == .rangingUnavailable,
            rangingConstraints.contains(where: { Self.key(for: $0) == constraintKey })
        else { return }

        RadarLogger.shared.log(level: .debug, message: "Pausing continuous beacon manager: ranging unavailable")
        pause()
    }
}

extension RadarContinuousBeaconManager {

    // MARK: - Lifecycle

    private func addObservers() {
        guard observers.isEmpty else { return }

        observe(UIApplication.didEnterBackgroundNotification) { manager in
            RadarLogger.shared.log(level: .debug, message: "Pausing continuous beacon manager in background")
            manager.pause()
        }
        observe(UIApplication.willEnterForegroundNotification) { manager in
            guard manager.started, !manager.ranging else { return }
            RadarLogger.shared.log(level: .debug, message: "Resuming continuous beacon manager in foreground")
            manager.resume()
        }
    }

    private func observe(_ name: Notification.Name, _ action: @escaping @MainActor (RadarContinuousBeaconManager) -> Void) {
        observers.append(
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    if let self { action(self) }
                }
            })
    }

    private func removeObservers() {
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
    }
}
