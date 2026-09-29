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

    var permissionsHelper: RadarPermissionsHelping = RadarPermissionsHelperSwift()
    var now: () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    var notificationCenter: NotificationCenter = .default

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    private(set) var requested = false
    private(set) var ranging = false
    private(set) var warmedUp = false
    private(set) var constraints: [CLBeaconIdentityConstraint] = []
    private var cache: [String: (beacon: RadarBeacon, lastSeen: TimeInterval)] = [:]
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
    }

    // MARK: - Public

    @objc func start() {
        guard !requested else {
            RadarLogger.shared.log(level: .debug, message: "Beacon ranging cache already started")
            return
        }

        RadarLogger.shared.log(level: .debug, message: "Starting beacon ranging cache")

        requested = true
        addObservers()
        resume()
    }

    @objc func stop() {
        RadarLogger.shared.log(level: .debug, message: "Stopping beacon ranging cache")

        requested = false
        removeObservers()
        pause()
        constraints = []
    }

    /// Replaces the beacons being ranged. UUIDs take precedence over specific beacons, matching
    /// the one-shot ranging path. No-op unless the cache has been started.
    @objc(updateBeacons:uuids:)
    func update(beacons: [RadarBeacon]?, uuids: [String]?) {
        guard requested else { return }

        let newConstraints: [CLBeaconIdentityConstraint]
        if let uuids, !uuids.isEmpty {
            newConstraints = uuids.compactMap { UUID(uuidString: $0).map { CLBeaconIdentityConstraint(uuid: $0) } }
        } else {
            newConstraints = (beacons ?? []).compactMap(Self.constraint(for:))
        }

        guard Self.keys(for: newConstraints) != Self.keys(for: constraints) || !ranging else { return }

        constraints = newConstraints
        startRanging()
    }

    /// Beacons ranged within `maxBeaconAge`, or `nil` if the cache is not ranging or has not yet
    /// received a ranging callback. An empty array means no beacons are nearby.
    @objc func cachedBeacons() -> [RadarBeacon]? {
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

        bridge.searchBeacons(near: location, radius: Self.searchRadius, limit: Self.searchLimit) { [weak self] status, beacons, uuids in
            Task { @MainActor in
                guard status == .success else {
                    RadarLogger.shared.log(level: .debug, message: "Beacon ranging cache search failed | status = \(status.rawValue)")
                    return
                }
                self?.update(beacons: beacons, uuids: uuids)
            }
        }
    }

    private func pause() {
        for constraint in constraints {
            locationManager.stopRangingBeacons(satisfying: constraint)
        }
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

    // MARK: - Helpers

    private static func constraint(for beacon: RadarBeacon) -> CLBeaconIdentityConstraint? {
        guard let uuid = UUID(uuidString: beacon.uuid),
            let major = CLBeaconMajorValue(beacon.major),
            let minor = CLBeaconMinorValue(beacon.minor)
        else { return nil }
        return CLBeaconIdentityConstraint(uuid: uuid, major: major, minor: minor)
    }

    private static func keys(for constraints: [CLBeaconIdentityConstraint]) -> Set<String> {
        Set(constraints.map { "\($0.uuid.uuidString)-\($0.major.map { "\($0)" } ?? "")-\($0.minor.map { "\($0)" } ?? "")" })
    }

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
