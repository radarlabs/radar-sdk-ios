//
//  RadarContinuousBeaconManager+Delegate.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

extension RadarContinuousBeaconManager {

    // MARK: - Helpers

    struct BeaconIdentity {
        let uuid: String
        let major: String
        let minor: String
    }

    struct SearchResult {
        /// iBeacon proximity UUIDs. Ranging one matches every iBeacon with that UUID, whatever its
        /// major and minor.
        let uuids: [String]
        /// Specific beacons, ranged only when there are no UUIDs.
        let beacons: [BeaconIdentity]

        /// UUIDs take precedence over specific beacons, matching one-shot ranging. Beacons that
        /// aren't valid iBeacons, such as Eddystone beacons from the Objective-C search, are
        /// skipped.
        var constraints: [CLBeaconIdentityConstraint] {
            if !uuids.isEmpty {
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
    }

    static func keys(for constraints: [CLBeaconIdentityConstraint]) -> Set<String> {
        Set(constraints.map(key(for:)))
    }

    nonisolated static func key(for constraint: CLBeaconIdentityConstraint) -> String {
        "uuid = \(constraint.uuid.uuidString); major = \(constraint.major.map { "\($0)" } ?? "nil"); minor = \(constraint.minor.map { "\($0)" } ?? "nil")"
    }
}

extension RadarContinuousBeaconManager.SearchResult {
    init(_ response: RadarAPIClient.SearchBeaconsResponse) {
        self.init(
            uuids: response.uuids,
            beacons: response.beacons.map { .init(uuid: $0.uuid, major: $0.major, minor: $0.minor) })
    }

    /// The result of an Objective-C search, or `nil` if it failed.
    init?(status: RadarStatus, uuids: [String]?, beacons: [RadarBeacon]?) {
        guard status == .success else { return nil }
        self.init(
            uuids: uuids ?? [],
            beacons: (beacons ?? []).map { .init(uuid: $0.uuid, major: $0.major, minor: $0.minor) })
    }
}

extension RadarContinuousBeaconManager {

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
        let constraintKey = Self.key(for: beaconConstraint)
        MainActor.assumeIsolated {
            handleRangingFailed(constraintKey, error: error)
        }
    }
}
