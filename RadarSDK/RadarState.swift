//
//  RadarState.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

let DEGREE_EPSILON = 0.00000001;

extension CLLocation {
    var isValid: Bool {
        get {
            let latitudeValid = (fabs(coordinate.latitude) > DEGREE_EPSILON && coordinate.latitude > -90 && coordinate.latitude < 90)
            let longitudeValid = (fabs(coordinate.longitude) > DEGREE_EPSILON && coordinate.longitude > -180 && coordinate.longitude < 180)
            
            return latitudeValid && longitudeValid && horizontalAccuracy > 0
        }
    }
}

class RadarState {
    nonisolated(unsafe)
    static let shared = RadarState()

    let userDefaults: RadarUserDefaults
    
    
    var lastRelativeAltitudeDataInMemory: [String: Any]? = nil;
    var lastPressureBackupTime: Date? = nil;
    let backupInterval: TimeInterval = 2.0; // 2 seconds
    
    init(userDefaults: RadarUserDefaults? = nil) {
        if let userDefaults {
            self.userDefaults = userDefaults
        } else {
            self.userDefaults = RadarUserDefaults.shared
        }
    }

    var lastLocation: CLLocation? {
        get {
            guard let dict = userDefaults.dictionary(forKey: .LastLocation),
                  let location = CLLocation.from(dict: dict),
                  location.isValid else {
                return nil
            }
            return location
        }
        set {
            guard let newValue, newValue.isValid else { return }
            userDefaults.set(newValue.toDict(), forKey: .LastLocation)
        }
    }

    var lastMovedLocation: CLLocation? {
        get {
            guard let dict = userDefaults.dictionary(forKey: .LastMovedLocation),
                  let location = CLLocation.from(dict: dict),
                  location.isValid else {
                return nil
            }
            return location
        }
        set {
            guard let newValue, newValue.isValid else { return }
            userDefaults.set(newValue.toDict(), forKey: .LastMovedLocation)
        }
    }

    var lastMovedAt: Date? {
        get { userDefaults.object(forKey: .LastMovedAt) as? Date }
        set { userDefaults.set(newValue, forKey: .LastMovedAt) }
    }

    var stopped: Bool {
        get { userDefaults.bool(forKey: .Stopped) }
        set { userDefaults.set(newValue, forKey: .Stopped) }
    }

    var lastSentAt: Date? {
        get { userDefaults.object(forKey: .LastSentAt) as? Date }
        set { userDefaults.set(newValue, forKey: .LastSentAt) }
    }

    func updateLastSentAt() {
        lastSentAt = Date()
    }

    var canExit: Bool {
        get { userDefaults.bool(forKey: .CanExit) }
        set { userDefaults.set(newValue, forKey: .CanExit) }
    }

    var lastFailedStoppedLocation: CLLocation? {
        get {
            guard let dict = userDefaults.dictionary(forKey: .LastFailedStoppedLocation),
                  let location = CLLocation.from(dict: dict),
                  location.isValid else {
                return nil
            }
            return location
        }
        set {
            guard let newValue, newValue.isValid else {
                userDefaults.set(nil, forKey: .LastFailedStoppedLocation)
                return
            }
            userDefaults.set(newValue.toDict(), forKey: .LastFailedStoppedLocation)
        }
    }

    var geofenceIds: [String]? {
        get { userDefaults.object(forKey: .GeofenceIds) as? [String] }
        set { userDefaults.set(newValue, forKey: .GeofenceIds) }
    }

    var placeId: String? {
        get { userDefaults.string(forKey: .PlaceId) }
        set { userDefaults.set(newValue, forKey: .PlaceId) }
    }

    var regionIds: [String]? {
        get { userDefaults.object(forKey: .RegionIds) as? [String] }
        set { userDefaults.set(newValue, forKey: .RegionIds) }
    }

    var beaconIds: [String]? {
        get { userDefaults.object(forKey: .BeaconIds) as? [String] }
        set { userDefaults.set(newValue, forKey: .BeaconIds) }
    }

    var lastHeadingData: [String: Any]? {
        get { userDefaults.dictionary(forKey: .LastHeadingData) }
        set { userDefaults.set(newValue, forKey: .LastHeadingData) }
    }

    var lastMotionActivityData: [String: Any]? {
        get { userDefaults.dictionary(forKey: .LastMotionActivityData) }
        set { userDefaults.set(newValue, forKey: .LastMotionActivityData) }
    }
    
    // for now, this is only used for access from Swift side, and for Mock tracking only
    // TODO:
    var lastRelativeAltitudeData: [String: Any]? {
        get {
            let currentTime = Date().timeIntervalSince1970

            if let inMemory = lastRelativeAltitudeDataInMemory {
                let timestamp = (inMemory["relativeAltitudeTimestamp"] as? NSNumber)?.doubleValue ?? 0
                let age = currentTime - timestamp
                if timestamp > 0 && age <= 60 {
                    return inMemory
                } else if timestamp > 0 {
                    RadarLogger.shared.warning("In-memory altitude data is stale (age: \(String(format: "%.1f", age)) seconds) - will try persisted data")
                }
            }

            if let savedData = userDefaults.dictionary(forKey: .LastPressureData) {
                return savedData
            } else {
                RadarLogger.shared.warning("No persisted altitude data found - altitude will be undefined")
            }

            return nil
        }
        set {
            if let newValue {
                let timestamp = (newValue["relativeAltitudeTimestamp"] as? NSNumber)?.doubleValue ?? 0
                let pressure = newValue["pressure"]
                let relativeAlt = newValue["relativeAltitude"]
                RadarLogger.shared.debug("Storing new altitude data: timestamp=\(String(format: "%.3f", timestamp)), pressure=\(pressure ?? "nil") hPa, relative=\(relativeAlt ?? "nil") m")
            } else {
                RadarLogger.shared.debug("Clearing altitude data (nil passed)")
            }

            lastRelativeAltitudeDataInMemory = newValue

            let now = Date()
            if lastPressureBackupTime == nil || now.timeIntervalSince(lastPressureBackupTime!) >= backupInterval {
                userDefaults.set(newValue, forKey: .LastPressureData)
                lastPressureBackupTime = now
                if newValue != nil {
                    RadarLogger.shared.debug("Backed up altitude data to disk")
                }
            }
        }
    }

    var notificationPermissionGranted: Bool {
        get { userDefaults.bool(forKey: .NotificationPermissionGranted) }
        set { userDefaults.set(newValue, forKey: .NotificationPermissionGranted) }
    }

    var motionAuthorizationString: String? {
        get { userDefaults.string(forKey: .MotionAuthorization) }
        set { userDefaults.set(newValue, forKey: .MotionAuthorization) }
    }

    var registeredNotifications: [[String: Any]]? {
        get { userDefaults.object(forKey: .RegisteredNotifications) as? [[String: Any]] }
        set { userDefaults.set(newValue, forKey: .RegisteredNotifications) }
    }

    func addRegisteredNotification(_ notification: [String: Any]) {
        var notifications = registeredNotifications ?? []
        notifications.append(notification)
        registeredNotifications = notifications
    }

    var altitudeAdjustments: [[String: Any]]? {
        get { userDefaults.object(forKey: .AltitudeAdjustments) as? [[String: Any]] }
        set {
            if let newValue {
                userDefaults.set(newValue, forKey: .AltitudeAdjustments)
            } else {
                userDefaults.removeObject(forKey: .AltitudeAdjustments)
            }
        }
    }
}
