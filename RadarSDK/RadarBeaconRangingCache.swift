//
//  RadarBeaconRangingCache.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit

/// Continuously ranges nearby beacons while the app is in the foreground so `trackVerified` can
/// attach beacons without waiting on a one-shot ranging window.
///
/// Uses its own `CLLocationManager` so it never shares state with the one-shot ranging in
/// `RadarBeaconManagerSwift`. Ranging pauses when the app enters the background and resumes when
/// it returns to the foreground, until `stop()` is called.
@MainActor
@objc(RadarBeaconRangingCache)
class RadarBeaconRangingCache: NSObject, CLLocationManagerDelegate {

    @objc static let shared = RadarBeaconRangingCache()

    /// Beacons not ranged within this many seconds are treated as out of range.
    static let maxBeaconAge: TimeInterval = 5
    static let searchRadius = 1000
    static let searchLimit = 10
    /// About the farthest a device can range a beacon. Cached beacons are only used where the
    /// search included every beacon within this distance of the device.
    static let beaconRange: CLLocationDistance = 100

    var permissionsHelper: RadarPermissionsHelping = RadarPermissionsHelperSwift()
    var now: () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    var notificationCenter: NotificationCenter = .default
    var searchBeacons: @MainActor (CLLocation) async throws -> SearchResult = { location in
        let response = try await RadarAPIClient.shared.searchBeacons(
            near: location,
            radius: RadarBeaconRangingCache.searchRadius,
            limit: RadarBeaconRangingCache.searchLimit
        )
        return SearchResult(
            uuids: response.uuids,
            beacons: response.beacons.map {
                BeaconIdentity(uuid: $0.uuid, major: $0.major, minor: $0.minor, location: $0.geometry?.clLocation)
            }
        )
    }

    private(set) lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    private(set) var requested = false
    private(set) var ranging = false
    private(set) var warmedUp = false
    private(set) var constraints: [CLBeaconIdentityConstraint] = []
    // Where `constraints` were searched from, if known.
    private(set) var searchLocation: CLLocation?
    // The search result `constraints` came from, used to tell how far from `searchLocation` it
    // included every beacon.
    private var searchResult: SearchResult?
    // Incremented to invalidate a search that's still running.
    private var searchGeneration = 0
    // What CoreLocation is actually ranging, which can differ from `constraints` while they're
    // being replaced.
    private var rangingConstraints: [CLBeaconIdentityConstraint] = []
    private var cache: [String: (beacon: RadarBeacon, lastSeen: TimeInterval)] = [:]
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
    }

    // MARK: - Control

    func start() {
        guard !requested else {
            RadarLogger.shared.log(level: .debug, message: "Beacon ranging cache already started")
            return
        }

        RadarLogger.shared.log(level: .debug, message: "Starting beacon ranging cache")

        requested = true
        addObservers()
        resume()
    }

    func stop() {
        RadarLogger.shared.log(level: .debug, message: "Stopping beacon ranging cache")

        requested = false
        removeObservers()
        pause()
        constraints = []
        searchLocation = nil
        searchResult = nil
        searchGeneration += 1
    }

    /// Replaces the beacons being ranged. No-op unless the cache has been started.
    func update(_ result: SearchResult, searchedFrom location: CLLocation? = nil) {
        guard requested else { return }
        searchLocation = location ?? searchLocation
        searchResult = result
        let newConstraints = result.constraints
        guard Self.keys(for: newConstraints) != Self.keys(for: constraints) || !ranging else { return }

        constraints = newConstraints
        startRanging()
    }

    /// Uses the beacons from a one-shot ranging request when the cache has started but has no
    /// beacons yet, for example because there was no location to search from.
    func seedIfNeeded(uuids: [String]?, beacons: [RadarBeacon]?) {
        guard requested, constraints.isEmpty else { return }

        update(
            SearchResult(
                uuids: uuids ?? [],
                beacons: (beacons ?? []).map {
                    BeaconIdentity(uuid: $0.uuid, major: $0.major, minor: $0.minor, location: $0.geometry?.clLocation)
                }
            )
        )
    }

    /// Like `cachedBeacons()`, but `nil` if the search didn't include every beacon in range of
    /// `location`. In that case the beacons are cleared, so the one-shot ranging request that
    /// follows searches near `location` and seeds the cache.
    @objc(cachedBeaconsNear:)
    func cachedBeacons(near location: CLLocation) -> [RadarBeacon]? {
        guard requested else { return nil }

        if let searchLocation, location.distance(from: searchLocation) + Self.beaconRange > coverageRadius {
            RadarLogger.shared.log(
                level: .debug,
                message:
                    "Beacon ranging cache search doesn't cover location | distance = \(Int(location.distance(from: searchLocation)))m; coverage = \(Int(min(coverageRadius, 1_000_000)))m"
            )
            pause()
            constraints = []
            searchResult = nil
            self.searchLocation = location
            searchGeneration += 1
            return nil
        }

        if searchLocation == nil {
            searchLocation = location
        }
        return cachedBeacons()
    }

    /// Beacons ranged within `maxBeaconAge`, or `nil` if the cache is not ranging or has not yet
    /// received a ranging callback. An empty array means no beacons are nearby.
    func cachedBeacons() -> [RadarBeacon]? {
        guard ranging, warmedUp else { return nil }

        let cutoff = now() - Self.maxBeaconAge
        cache = cache.filter { $0.value.lastSeen >= cutoff }
        return cache.values.map(\.beacon)
    }

    // MARK: - Ranging

    private func resume() {
        guard requested, !ranging else { return }

        let status = permissionsHelper.locationAuthorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            RadarLogger.shared.log(level: .debug, message: "Beacon ranging cache not started: location not authorized")
            return
        }

        guard permissionsHelper.isRangingAvailable() else {
            RadarLogger.shared.log(level: .debug, message: "Beacon ranging cache not started: ranging not available")
            return
        }

        guard let bridge = RadarSwift.bridge, bridge.isForeground() else { return }

        if !constraints.isEmpty {
            startRanging()
        }

        guard let location = bridge.lastLocation() else {
            RadarLogger.shared.log(level: .debug, message: "Beacon ranging cache waiting for a location to search beacons")
            return
        }

        searchGeneration += 1
        let generation = searchGeneration
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await searchBeacons(location)
                guard generation == searchGeneration else {
                    RadarLogger.shared.log(level: .debug, message: "Beacon ranging cache ignoring stale search")
                    return
                }
                update(result, searchedFrom: location)
            } catch {
                RadarLogger.shared.log(level: .debug, message: "Beacon ranging cache search failed | error = \(error.localizedDescription)")
            }
        }
    }

    private func pause() {
        for constraint in rangingConstraints {
            locationManager.stopRangingBeacons(satisfying: constraint)
        }
        rangingConstraints = []
        ranging = false
        warmedUp = false
        cache.removeAll()
    }

    private func startRanging() {
        guard RadarSwift.bridge?.isForeground() ?? false else { return }

        pause()
        guard !constraints.isEmpty else { return }

        ranging = true
        for constraint in constraints {
            RadarLogger.shared.log(
                level: .debug,
                message:
                    "Beacon ranging cache ranging | uuid = \(constraint.uuid.uuidString); major = \(constraint.major.map { "\($0)" } ?? "nil"); minor = \(constraint.minor.map { "\($0)" } ?? "nil")")
            locationManager.startRangingBeacons(satisfying: constraint)
        }
        rangingConstraints = constraints
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

        warmedUp = true

        let timestamp = now()
        for entry in entries where entry.rssi != 0 {
            let key = "\(entry.uuid.uppercased())-\(entry.major)-\(entry.minor)"
            if let existing = cache[key] {
                bridge.setRssi(entry.rssi, onBeacon: existing.beacon)
                cache[key] = (existing.beacon, timestamp)
            } else {
                let beacon = bridge.createBeacon(uuid: entry.uuid, major: entry.major, minor: entry.minor, rssi: entry.rssi)
                cache[key] = (beacon, timestamp)
            }
        }
    }

    // MARK: - Lifecycle

    private func addObservers() {
        guard observers.isEmpty else { return }

        observers.append(
            notificationCenter.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    RadarLogger.shared.log(level: .debug, message: "Pausing beacon ranging cache in background")
                    self?.pause()
                }
            })
        observers.append(
            notificationCenter.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    RadarLogger.shared.log(level: .debug, message: "Resuming beacon ranging cache in foreground")
                    self?.resume()
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

extension RadarBeaconRangingCache {

    // MARK: - Helpers

    struct BeaconIdentity {
        let uuid: String
        let major: String
        let minor: String
        var location: CLLocation?
    }

    struct SearchResult {
        let uuids: [String]
        let beacons: [BeaconIdentity]

        var constraints: [CLBeaconIdentityConstraint] {
            RadarBeaconRangingCache.constraints(uuids: uuids, beacons: beacons)
        }
    }

    /// How far from `searchLocation` the search result included every beacon.
    private var coverageRadius: CLLocationDistance {
        guard let searchResult else { return 0 }
        // UUID ranging matches every beacon with those UUIDs, wherever the device is.
        if !searchResult.uuids.isEmpty { return .infinity }
        // Fewer beacons than the limit means the search returned every beacon in its radius.
        if searchResult.beacons.count < Self.searchLimit { return CLLocationDistance(Self.searchRadius) }
        // A full result is the nearest beacons, so it only covers out to the farthest one.
        guard let searchLocation else { return 0 }
        return searchResult.beacons.compactMap { $0.location?.distance(from: searchLocation) }.max() ?? 0
    }

    /// UUIDs take precedence over specific beacons, matching the one-shot ranging path.
    nonisolated static func constraints(uuids: [String]?, beacons: [BeaconIdentity]) -> [CLBeaconIdentityConstraint] {
        if let uuids, !uuids.isEmpty {
            return uuids.compactMap { UUID(uuidString: $0).map { CLBeaconIdentityConstraint(uuid: $0) } }
        }
        return beacons.compactMap { beacon in
            guard let uuid = UUID(uuidString: beacon.uuid),
                let major = CLBeaconMajorValue(beacon.major),
                let minor = CLBeaconMinorValue(beacon.minor)
            else { return nil }
            return CLBeaconIdentityConstraint(uuid: uuid, major: major, minor: minor)
        }
    }

    private static func keys(for constraints: [CLBeaconIdentityConstraint]) -> Set<String> {
        Set(constraints.map { "\($0.uuid.uuidString)-\($0.major.map { "\($0)" } ?? "")-\($0.minor.map { "\($0)" } ?? "")" })
    }
}

extension RadarBeaconRangingCache {

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didRange beacons: [CLBeacon],
        satisfying beaconConstraint: CLBeaconIdentityConstraint
    ) {
        let entries = beacons.map {
            RangedBeacon(uuid: $0.uuid.uuidString, major: "\($0.major)", minor: "\($0.minor)", rssi: $0.rssi)
        }
        MainActor.assumeIsolated {
            handleRanged(entries)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint,
        error: Error
    ) {
        let uuid = beaconConstraint.uuid.uuidString
        let description = error.localizedDescription
        MainActor.assumeIsolated {
            RadarLogger.shared.log(level: .debug, message: "Beacon ranging cache failed to range | uuid = \(uuid); error = \(description)")
        }
    }
}
