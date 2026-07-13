//
//  RadarBeaconManager+Delegate.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import UserNotifications

// MARK: - CLLocationManagerDelegate

extension RadarBeaconManagerSwift {

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        monitoringDidFailFor region: CLRegion?,
        withError error: Error
    ) {
        let identifier = region?.identifier
        MainActor.assumeIsolated {
            guard !RadarSettings.useRadarModifiedBeacon else { return }
            guard let identifier = identifier else { return }

            RadarLogger.shared.log(level: .debug, message: "Failed to monitor beacon | region.identifier = \(identifier)")

            failedBeaconIdentifiers.insert(identifier)
            handleBeacons()
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didRange beacons: [CLBeacon],
        satisfying beaconConstraint: CLBeaconIdentityConstraint
    ) {
        let identifier = beaconConstraint.uuid.uuidString
        let rangedData = beacons.map { clBeacon in
            (
                uuid: clBeacon.uuid.uuidString,
                major: "\(clBeacon.major)",
                minor: "\(clBeacon.minor)",
                rssi: clBeacon.rssi,
                proximity: clBeacon.proximity.rawValue
            )
        }

        MainActor.assumeIsolated {
            nearbyBeaconIdentifiers.insert(identifier)

            for entry in rangedData {
                guard let bridge = RadarSwift.bridge else { return }
                let newBeacon = bridge.createBeacon(
                    uuid: entry.uuid, major: entry.major,
                    minor: entry.minor, rssi: entry.rssi
                )

                if let existing = nearbyBeacons.first(where: { $0.isEqual(newBeacon) }) {
                    if entry.rssi != 0 && entry.rssi != existing.rssi {
                        RadarLogger.shared.log(level: .debug, message: "Overwriting stale RSSI: \(existing.rssi)")

                        bridge.setRssi(entry.rssi, on: existing)
                    }
                } else {
                    nearbyBeacons.insert(newBeacon)
                }

                RadarLogger.shared.log(
                    level: .debug,
                    message:
                        "Ranged beacon with RSSI \(entry.rssi) | nearbyBeacons.count = \(nearbyBeacons.count); identifier = \(identifier); beacon.uuid = \(entry.uuid); beacon.major = \(entry.major); beacon.minor = \(entry.minor); beacon.rssi = \(entry.rssi); beacon.proximity = \(entry.proximity)"
                )
            }

            handleBeacons()
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint,
        error: Error
    ) {
        let identifier = beaconConstraint.uuid.uuidString
        MainActor.assumeIsolated {
            RadarLogger.shared.log(level: .debug, message: "Failed to range beacon | identifier = \(identifier)")

            failedBeaconIdentifiers.insert(identifier)
            handleBeacons()
        }
    }
}

// MARK: - Entry/Exit Handlers

extension RadarBeaconManagerSwift {

    @objc(handleBeaconEntryForRegion:completionHandler:)
    func handleBeaconEntry(
        for region: CLBeaconRegion,
        completionHandler: @escaping RadarBeaconCompletionHandler
    ) {
        guard !RadarSettings.useRadarModifiedBeacon else { return }

        let identifier = region.identifier
        if nearbyBeaconIdentifiers.contains(identifier) {
            RadarLogger.shared.log(level: .debug, message: "Already inside beacon region | identifier = \(identifier)")
        } else {
            RadarLogger.shared.log(level: .debug, message: "Entered beacon region | identifier = \(identifier)")

            nearbyBeaconIdentifiers.insert(identifier)
            if let bridge = RadarSwift.bridge {
                nearbyBeacons.insert(bridge.createBeacon(fromRegion: region))
            }

            completionHandler(.success, Array(nearbyBeacons))
        }
    }

    @objc(handleBeaconExitForRegion:completionHandler:)
    func handleBeaconExit(
        for region: CLBeaconRegion,
        completionHandler: @escaping RadarBeaconCompletionHandler
    ) {
        guard !RadarSettings.useRadarModifiedBeacon else { return }

        let identifier = region.identifier
        if !nearbyBeaconIdentifiers.contains(identifier) {
            RadarLogger.shared.log(level: .debug, message: "Already outside beacon region | identifier = \(identifier)")
        } else {
            RadarLogger.shared.log(level: .debug, message: "Exited beacon region | identifier = \(identifier)")

            nearbyBeaconIdentifiers.remove(identifier)
            if let bridge = RadarSwift.bridge {
                let regionBeacon = bridge.createBeacon(fromRegion: region)
                nearbyBeacons.remove(regionBeacon)
            }

            completionHandler(.success, Array(nearbyBeacons))
        }
    }

    @objc(handleBeaconUUIDEntryForRegion:completionHandler:)
    func handleBeaconUUIDEntry(
        for region: CLBeaconRegion,
        completionHandler: @escaping RadarBeaconCompletionHandler
    ) {
        guard !RadarSettings.useRadarModifiedBeacon else { return }

        let uuids = RadarSettings.beaconUUIDs ?? []
        rangeBeaconUUIDs(uuids, completionHandler: completionHandler)
    }

    @objc(handleBeaconUUIDExitForRegion:completionHandler:)
    func handleBeaconUUIDExit(
        for region: CLBeaconRegion,
        completionHandler: @escaping RadarBeaconCompletionHandler
    ) {
        guard !RadarSettings.useRadarModifiedBeacon else { return }

        let uuids = RadarSettings.beaconUUIDs ?? []
        rangeBeaconUUIDs(uuids, completionHandler: completionHandler)
    }
}

// MARK: - Beacon Region Notifications

extension RadarBeaconManagerSwift {

    @objc(registerBeaconRegionNotificationsFromArray:)
    func registerBeaconRegionNotifications(
        from beaconArray: [[String: Any]]
    ) {
        guard let bridge = RadarSwift.bridge else { return }

        var requests: [UNNotificationRequest] = []

        for beaconDict in beaconArray {
            guard let uuidString = beaconDict["uuid"] as? String else {
                RadarLogger.shared.log(level: .error, message: "Missing required uuid for beacon notification")
                continue
            }

            guard let uuid = UUID(uuidString: uuidString) else {
                RadarLogger.shared.log(level: .error, message: "Invalid UUID string for beacon notification | uuid = \(uuidString)")
                continue
            }

            guard let metadata = beaconDict["metadata"] as? [AnyHashable: Any] else {
                RadarLogger.shared.log(level: .error, message: "Missing or invalid metadata for beacon notification | uuid = \(uuidString)")
                continue
            }

            let major = beaconDict["major"] as? String
            let minor = beaconDict["minor"] as? String

            let constraint: CLBeaconIdentityConstraint
            if let majorString = major, let majorValue = CLBeaconMajorValue(majorString),
                let minorString = minor, let minorValue = CLBeaconMinorValue(minorString)
            {
                constraint = CLBeaconIdentityConstraint(uuid: uuid, major: majorValue, minor: minorValue)
            } else if let majorString = major, let majorValue = CLBeaconMajorValue(majorString) {
                constraint = CLBeaconIdentityConstraint(uuid: uuid, major: majorValue)
            } else {
                constraint = CLBeaconIdentityConstraint(uuid: uuid)
            }

            let region = CLBeaconRegion(
                beaconIdentityConstraint: constraint,
                identifier: uuidString
            )

            let notificationId = "\(Self.beaconNotificationIdentifierPrefix)\(uuidString)"

            if let content = bridge.extractContent(
                fromMetadata: metadata, identifier: notificationId
            ) {
                let trigger = UNLocationNotificationTrigger(region: region, repeats: false)

                let request = UNNotificationRequest(
                    identifier: notificationId,
                    content: content,
                    trigger: trigger
                )

                requests.append(request)
            }
        }

        bridge.updateClientSideCampaigns(
            withPrefix: Self.beaconNotificationIdentifierPrefix,
            notificationRequests: requests
        )
    }
}
