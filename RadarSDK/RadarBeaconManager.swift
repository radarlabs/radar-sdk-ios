//
//  RadarBeaconManager.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/10/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

@MainActor
@objc(RadarBeaconManagerSwift)
class RadarBeaconManagerSwift: NSObject, CLLocationManagerDelegate {

    @objc static let shared = RadarBeaconManagerSwift()

    var permissionsHelper: RadarPermissionsHelping = RadarPermissionsHelperSwift()

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    var started = false
    var completionHandlers: [RadarBeaconCompletionHandler] = []
    var nearbyBeaconIdentifiers: Set<String> = []
    var failedBeaconIdentifiers: Set<String> = []
    var nearbyBeacons: Set<RadarBeacon> = []
    var beacons: [RadarBeacon] = []
    var beaconUUIDs: [String] = []
    var constraintIdentifierMap: [String: String] = [:]

    static let beaconNotificationIdentifierPrefix = "radar_beacon_notification_"

    private override init() {
        super.init()
    }

    // MARK: - Region Helpers

    private func region(for beacon: RadarBeacon) -> CLBeaconRegion? {
        guard let uuid = UUID(uuidString: beacon.uuid) else { return nil }
        guard let major = CLBeaconMajorValue(beacon.major),
            let minor = CLBeaconMinorValue(beacon.minor)
        else { return nil }

        let constraint = CLBeaconIdentityConstraint(
            uuid: uuid, major: major, minor: minor
        )
        return CLBeaconRegion(
            beaconIdentityConstraint: constraint,
            identifier: beacon._id ?? beacon.uuid
        )
    }

    private func region(for uuidString: String) -> CLBeaconRegion? {
        guard let uuid = UUID(uuidString: uuidString) else { return nil }

        let constraint = CLBeaconIdentityConstraint(uuid: uuid)
        return CLBeaconRegion(
            beaconIdentityConstraint: constraint,
            identifier: uuidString
        )
    }
    
    func constraintKey(uuid: String, major: String? = nil, minor: String? = nil) -> String {
        var key = uuid
        if let major  { key += "-\(major)" }
        if let minor  { key += "-\(minor)" }
        return key
    }

    // MARK: - Timeout

    private var timeoutTask: Task<Void, Never>?

    // MARK: - Completion Handler Management

    private func addCompletionHandler(_ handler: @escaping RadarBeaconCompletionHandler) {
        completionHandlers.append(handler)

        if timeoutTask == nil {
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }

                RadarLogger.shared.log(level: .debug, message: "Beacon ranging timeout")

                self.stopRanging()
            }
        }
    }

    private func cancelTimeouts() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    private func callCompletionHandlers(
        status: RadarStatus,
        nearbyBeacons: [RadarBeacon]?
    ) {
        guard !completionHandlers.isEmpty else { return }

        RadarLogger.shared.log(level: .debug, message: "Calling completion handlers | completionHandlers.count = \(completionHandlers.count)")

        let handlers = completionHandlers
        completionHandlers.removeAll()

        for handler in handlers {
            handler(status, nearbyBeacons)
        }
    }

    // MARK: - Ranging

    @objc func rangeBeacons(
        _ beacons: [RadarBeacon],
        completionHandler: @escaping RadarBeaconCompletionHandler
    ) {
        let status = permissionsHelper.locationAuthorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            RadarSwift.bridge?.didFail(status: .errorPermissions)
            completionHandler(.errorPermissions, nil)
            return
        }

        guard permissionsHelper.isRangingAvailable() else {
            RadarSwift.bridge?.didFail(status: .errorBluetooth)
            RadarLogger.shared.log(level: .debug, message: "Bluetooth ranging not available")
            completionHandler(.errorBluetooth, nil)
            return
        }

        guard !beacons.isEmpty else {
            RadarLogger.shared.log(level: .debug, message: "No beacons to range")
            completionHandler(.success, [])
            return
        }

        addCompletionHandler(completionHandler)

        guard !started else {
            RadarLogger.shared.log(level: .debug, message: "Already ranging beacons")
            return
        }

        self.beacons = beacons
        started = true

        for beacon in beacons {
            if let region = region(for: beacon) {
                RadarLogger.shared.log(
                    level: .debug,
                    message: "Starting ranging beacon | _id = \(beacon._id ?? "nil"); uuid = \(beacon.uuid); major = \(beacon.major); minor = \(beacon.minor)"
                )
                
                let key = constraintKey(uuid: beacon.uuid, major: beacon.major, minor: beacon.minor)
                constraintIdentifierMap[key] = beacon._id ?? beacon.uuid

                locationManager.startRangingBeacons(satisfying: region.beaconIdentityConstraint)

            } else {
                RadarLogger.shared.log(
                    level: .debug,
                    message: "Error starting ranging beacon | _id = \(beacon._id ?? "nil"); uuid = \(beacon.uuid); major = \(beacon.major); minor = \(beacon.minor)"
                )
            }
        }
    }

    @objc func rangeBeaconUUIDs(
        _ beaconUUIDs: [String],
        completionHandler: @escaping RadarBeaconCompletionHandler
    ) {
        let status = permissionsHelper.locationAuthorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            RadarSwift.bridge?.didFail(status: .errorPermissions)
            completionHandler(.errorPermissions, nil)
            return
        }

        guard permissionsHelper.isRangingAvailable() else {
            RadarSwift.bridge?.didFail(status: .errorBluetooth)
            RadarLogger.shared.log(level: .debug, message: "Bluetooth ranging not available")
            completionHandler(.errorBluetooth, nil)
            return
        }

        guard !beaconUUIDs.isEmpty else {
            RadarLogger.shared.log(level: .debug, message: "No UUIDs to range")
            completionHandler(.success, [])
            return
        }

        addCompletionHandler(completionHandler)

        guard !started else {
            RadarLogger.shared.log(level: .debug, message: "Already ranging beacons")
            return
        }

        self.beaconUUIDs = beaconUUIDs
        started = true

        for uuidString in beaconUUIDs {
            if let region = region(for: uuidString) {
                RadarLogger.shared.log(level: .debug, message: "Starting ranging UUID | beaconUUID = \(uuidString)")

                locationManager.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
            } else {
                RadarLogger.shared.log(
                    level: .debug,
                    message: "Error starting ranging UUID | beaconUUID = \(uuidString)"
                )
            }
        }
    }

    // MARK: - Stop Ranging

    @objc func stopRanging() {
        RadarLogger.shared.log(level: .debug, message: "Stopped ranging")

        cancelTimeouts()

        for beacon in beacons {
            if let region = region(for: beacon) {
                locationManager.stopRangingBeacons(satisfying: region.beaconIdentityConstraint)
            }
        }

        for uuidString in beaconUUIDs {
            if let region = region(for: uuidString) {
                locationManager.stopRangingBeacons(satisfying: region.beaconIdentityConstraint)
            }
        }

        callCompletionHandlers(status: .success, nearbyBeacons: Array(nearbyBeacons))

        beacons = []
        beaconUUIDs = []
        started = false
        nearbyBeaconIdentifiers.removeAll()
        failedBeaconIdentifiers.removeAll()
        nearbyBeacons.removeAll()
        constraintIdentifierMap.removeAll()
    }

    // MARK: - Beacon Tracking

    func handleBeacons() {
        let useModifiedBeacons = RadarSettings.useRadarModifiedBeacon

        if beaconUUIDs.isEmpty || useModifiedBeacons,
            nearbyBeaconIdentifiers.count + failedBeaconIdentifiers.count == beacons.count
        {
            RadarLogger.shared.log(level: .debug, message: "Finished ranging")

            stopRanging()
        }
    }
}
