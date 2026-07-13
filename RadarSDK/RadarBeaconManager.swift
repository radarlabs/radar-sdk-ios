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
    
    private let locationManager: CLLocationManager
    private var started = false
    private var completionHandlers: [RadarBeaconCompletionHandler] = []
    private var nearbyBeaconIdentifiers: Set<String> = []
    private var failedBeaconIdentifiers: Set<String> = []
    private var nearbyBeacons: Set<RadarBeacon> = []
    private var beacons: [RadarBeacon] = []
    private var beaconUUIDs: [String] = []
    
    private static let beaconNotificationIdentifierPrefix = "radar_beacon_notification_"
    
    private override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Region Helpers
    
    private func region(for beacon: RadarBeacon) -> CLBeaconRegion? {
        guard let uuid = UUID(uuidString: beacon.uuid) else { return nil }
        guard let major = CLBeaconMajorValue(beacon.major),
              let minor = CLBeaconMinorValue(beacon.minor) else { return nil }
        
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
            RadarLogger.shared.log( level: .debug, message: "No beacons to range")
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
            RadarLogger.shared.log( level: .debug, message: "No UUIDs to range")
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
    }
    
    // MARK: - Beacon Tracking
    
    private func handleBeacons() {
        let useModifiedBeacons = RadarSettings.useRadarModifiedBeacon
        
        if (beaconUUIDs.isEmpty || useModifiedBeacons),
        nearbyBeaconIdentifiers.count + failedBeaconIdentifiers.count == beacons.count {
            RadarLogger.shared.log(level: .debug, message: "Finished ranging")
            
            stopRanging()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
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
                    message: "Ranged beacon with RSSI \(entry.rssi) | nearbyBeacons.count = \(nearbyBeacons.count); identifier = \(identifier); beacon.uuid = \(entry.uuid); beacon.major = \(entry.major); beacon.minor = \(entry.minor); beacon.rssi = \(entry.rssi); beacon.proximity = \(entry.proximity)"
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
    
    // MARK: - Entry/Exit Handlers
    
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
    
    // MARK: - Beacon Region Notifications
    
    @objc(registerBeaconRegionNotificationsFromArray:)
    func registerBeaconRegionNotifications(
        from beaconArray: [[String: Any]]
    ) {
        guard let bridge = RadarSwift.bridge else { return }
        
        var requests: [UNNotificationRequest] = []
        
        for beaconDict in beaconArray {
            guard let uuidString = beaconDict["uuid"] as? String else {
                RadarLogger.shared.log(level:.error, message: "Missing required uuid for beacon notification")
                continue
            }
            
            guard let uuid = UUID(uuidString: uuidString) else {
                RadarLogger.shared.log(level:.error, message: "Invalid UUID string for beacon notification | uuid = \(uuidString)")
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
               let minorString = minor, let minorValue = CLBeaconMinorValue(minorString) {
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
