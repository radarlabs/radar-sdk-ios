//
//  RadarState.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation

/// SDK tracking state persisted through `RadarUserDefaults`. Objective-C uses the class
/// interface declared in `RadarState.h`.
@objc(RadarState) @objcMembers
class RadarState: NSObject {

    private static let relativeAltitudeMaxAge: TimeInterval = 60
    private static let relativeAltitudeBackupInterval: TimeInterval = 2

    // The latest altitude reading is kept in memory and backed up to disk at most every
    // `relativeAltitudeBackupInterval`, because pressure updates arrive frequently.
    private static let relativeAltitudeLock = NSLock()
    nonisolated(unsafe) private static var lastRelativeAltitudeDataInMemory: [String: Any]?
    nonisolated(unsafe) private static var lastRelativeAltitudeBackupTime: Date?

    static var lastLocation: CLLocation? {
        get { location(forKey: .lastLocation) }
        set {
            // An invalid or nil location leaves the stored value unchanged.
            guard let newValue, newValue.isValid else { return }
            RadarUserDefaults.set(RadarUtils.dictionaryForLocation(newValue), forKey: .lastLocation)
        }
    }

    static var lastMovedLocation: CLLocation? {
        get { location(forKey: .lastMovedLocation) }
        set {
            guard let newValue, newValue.isValid else { return }
            RadarUserDefaults.set(RadarUtils.dictionaryForLocation(newValue), forKey: .lastMovedLocation)
        }
    }

    static var lastMovedAt: Date? {
        get { RadarUserDefaults.object(forKey: .lastMovedAt) as? Date }
        set { RadarUserDefaults.set(newValue, forKey: .lastMovedAt) }
    }

    static var stopped: Bool {
        get { RadarUserDefaults.bool(forKey: .stopped) }
        set { RadarUserDefaults.set(newValue, forKey: .stopped) }
    }

    static var lastSentAt: Date? {
        RadarUserDefaults.object(forKey: .lastSentAt) as? Date
    }

    static func updateLastSentAt() {
        RadarUserDefaults.set(Date(), forKey: .lastSentAt)
    }

    static var canExit: Bool {
        get { RadarUserDefaults.bool(forKey: .canExit) }
        set { RadarUserDefaults.set(newValue, forKey: .canExit) }
    }

    static var lastFailedStoppedLocation: CLLocation? {
        get { location(forKey: .lastFailedStoppedLocation) }
        set {
            // Unlike the other locations, an invalid or nil location clears the stored value.
            guard let newValue, newValue.isValid else {
                RadarUserDefaults.set(nil, forKey: .lastFailedStoppedLocation)
                return
            }
            RadarUserDefaults.set(RadarUtils.dictionaryForLocation(newValue), forKey: .lastFailedStoppedLocation)
        }
    }

    static var geofenceIds: [String]? {
        get { RadarUserDefaults.object(forKey: .geofenceIds) as? [String] }
        set { RadarUserDefaults.set(newValue, forKey: .geofenceIds) }
    }

    static var placeId: String? {
        get { RadarUserDefaults.string(forKey: .placeId) }
        set { RadarUserDefaults.set(newValue, forKey: .placeId) }
    }

    static var regionIds: [String]? {
        get { RadarUserDefaults.object(forKey: .regionIds) as? [String] }
        set { RadarUserDefaults.set(newValue, forKey: .regionIds) }
    }

    static var beaconIds: [String]? {
        get { RadarUserDefaults.object(forKey: .beaconIds) as? [String] }
        set { RadarUserDefaults.set(newValue, forKey: .beaconIds) }
    }

    static var lastHeadingData: [String: Double]? {
        get {
            guard let dict = RadarUserDefaults.dictionary(forKey: .lastHeadingData) else {
                return nil
            }
            return dict.compactMapValues { heading in (heading as? NSNumber)?.doubleValue }
        }
        set {
            RadarUserDefaults.set(newValue, forKey: .lastHeadingData)
        }
    }

    static var lastMotionActivityData: [String: Any]? {
        get { RadarUserDefaults.dictionary(forKey: .lastMotionActivityData) }
        set { RadarUserDefaults.set(newValue, forKey: .lastMotionActivityData) }
    }

    /// The latest relative altitude reading, or `nil` when no reading is newer than 60 seconds.
    static var lastRelativeAltitudeData: [String: Any]? {
        get {
            Self.relativeAltitudeLock.lock()
            defer { Self.relativeAltitudeLock.unlock() }

            let now = Date().timeIntervalSince1970

            if let inMemory = Self.lastRelativeAltitudeDataInMemory {
                let timestamp = Self.relativeAltitudeTimestamp(inMemory)
                let age = now - timestamp
                if timestamp > 0 && age <= Self.relativeAltitudeMaxAge {
                    return inMemory
                } else if timestamp > 0 {
                    RadarLogger.shared.warning(
                        String(format: "In-memory altitude data is stale (age: %.1f seconds) - will try persisted data", age))
                }
            }

            guard let saved = RadarUserDefaults.dictionary(forKey: .lastPressureData) else {
                RadarLogger.shared.warning("No persisted altitude data found - altitude will be undefined")
                return nil
            }

            let timestamp = Self.relativeAltitudeTimestamp(saved)
            let age = now - timestamp
            if timestamp > 0 && age <= Self.relativeAltitudeMaxAge {
                Self.lastRelativeAltitudeDataInMemory = saved
                return saved
            } else if timestamp > 0 {
                RadarLogger.shared.warning(
                    String(
                        format: "Persisted altitude data is also stale (age: %.1f seconds) - returning nil, altitude will be undefined",
                        age))
            }
            return nil
        }
        set {
            if let newValue {
                let timestamp = Self.relativeAltitudeTimestamp(newValue)
                let pressure = newValue["pressure"].map { "\($0)" } ?? "(null)"
                let relativeAltitude = newValue["relativeAltitude"].map { "\($0)" } ?? "(null)"
                RadarLogger.shared.debug(
                    String(format: "Storing new altitude data: timestamp=%.3f, pressure=%@ hPa, relative=%@ m", timestamp, pressure, relativeAltitude))
            } else {
                RadarLogger.shared.debug("Clearing altitude data (nil passed)")
            }

            Self.relativeAltitudeLock.lock()
            defer { Self.relativeAltitudeLock.unlock() }

            Self.lastRelativeAltitudeDataInMemory = newValue

            let now = Date()
            if let lastBackup = Self.lastRelativeAltitudeBackupTime,
                now.timeIntervalSince(lastBackup) < Self.relativeAltitudeBackupInterval
            {
                return
            }
            RadarUserDefaults.set(newValue, forKey: .lastPressureData)
            Self.lastRelativeAltitudeBackupTime = now
            if newValue != nil {
                RadarLogger.shared.debug("Backed up altitude data to disk")
            }
        }
    }

    static var notificationPermissionGranted: Bool {
        get { RadarUserDefaults.bool(forKey: .notificationPermissionGranted) }
        set { RadarUserDefaults.set(newValue, forKey: .notificationPermissionGranted) }
    }

    static var motionAuthorizationString: String? {
        get { RadarUserDefaults.string(forKey: .motionAuthorization) }
        set { RadarUserDefaults.set(newValue, forKey: .motionAuthorization) }
    }

    static var locationAuthorizationStatus: CLAuthorizationStatus {
        get {
            CLAuthorizationStatus(rawValue: Int32(RadarUserDefaults.integer(forKey: .locationAuthorizationStatus))) ?? .notDetermined
        }
        set {
            RadarUserDefaults.set(Int(newValue.rawValue), forKey: .locationAuthorizationStatus)
        }
    }

    // Objective-C stores the server's notification dictionaries as-is through
    // `+registeredNotifications`; Swift reads and writes them as `NotificationValue`s.
    @objc(registeredNotifications)
    static var registeredNotificationDictionaries: [[String: Any]]? {
        get { RadarUserDefaults.object(forKey: .registeredNotifications) as? [[String: Any]] }
        set { RadarUserDefaults.set(newValue, forKey: .registeredNotifications) }
    }

    static var registeredNotifications: [NotificationValue]? {
        get {
            if let obj = RadarUserDefaults.object(forKey: .registeredNotifications),
                JSONSerialization.isValidJSONObject(obj),
                let data = try? JSONSerialization.data(withJSONObject: obj),
                let value = try? JSONDecoder().decode([NotificationValue].self, from: data)
            {
                return value
            }
            return nil
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
                let obj = try? JSONSerialization.jsonObject(with: data)
            {
                RadarUserDefaults.set(obj, forKey: .registeredNotifications)
            }
        }
    }

    static var altitudeAdjustments: [[String: Any]]? {
        get { RadarUserDefaults.object(forKey: .altitudeAdjustments) as? [[String: Any]] }
        set { RadarUserDefaults.set(newValue, forKey: .altitudeAdjustments) }
    }

    static var radarUser: RadarUser? {
        get {
            guard let dict = RadarUserDefaults.dictionary(forKey: .radarUser) else {
                return nil
            }
            return RadarSwift.bridge?.createUser(dict: dict)
        }
        set {
            RadarUserDefaults.set(newValue?.dictionaryValue(), forKey: .radarUser)
        }
    }

    private static func location(forKey key: RadarUserDefaults.Key) -> CLLocation? {
        let location = RadarUtils.locationForDictionary(RadarUserDefaults.dictionary(forKey: key))
        return location.isValid ? location : nil
    }

    private static func relativeAltitudeTimestamp(_ data: [String: Any]) -> TimeInterval {
        (data["relativeAltitudeTimestamp"] as? NSNumber)?.doubleValue ?? 0
    }
}
