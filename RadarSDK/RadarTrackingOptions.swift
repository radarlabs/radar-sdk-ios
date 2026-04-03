//
//  RadarTrackingOptions.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

/// The location accuracy options.
@objc(RadarTrackingOptionsDesiredAccuracy)
public enum RadarTrackingOptionsDesiredAccuracy: Int {
    /// Uses `kCLLocationAccuracyBest`
    case high = 0
    /// Uses `kCLLocationAccuracyHundredMeters`, the default
    case medium = 1
    /// Uses `kCLLocationAccuracyKilometer`
    case low = 2
}

/// The replay options for failed location updates.
@objc(RadarTrackingOptionsReplay)
public enum RadarTrackingOptionsReplay: Int {
    /// Replays failed stops
    case stops = 0
    /// Replays no failed location updates
    case none = 1
    /// Replays all failed location updates
    case all = 2
}

/// The sync options for location updates.
@objc(RadarTrackingOptionsSyncLocations)
public enum RadarTrackingOptionsSyncLocations: Int {
    /// Syncs all location updates to the server
    case all = 0
    /// Syncs only stops and exits to the server
    case stopsAndExits = 1
    /// Syncs no location updates to the server
    case none = 2
}

/// An options class used to configure background tracking.
/// @see https://radar.com/documentation/sdk/ios
@objc(RadarTrackingOptions) @objcMembers
public class RadarTrackingOptions: NSObject {

    // MARK: - Dictionary Keys

    private static let kDesiredStoppedUpdateInterval = "desiredStoppedUpdateInterval"
    private static let kDesiredMovingUpdateInterval = "desiredMovingUpdateInterval"
    private static let kDesiredSyncInterval = "desiredSyncInterval"
    private static let kDesiredAccuracy = "desiredAccuracy"
    private static let kStopDuration = "stopDuration"
    private static let kStopDistance = "stopDistance"
    private static let kStartTrackingAfter = "startTrackingAfter"
    private static let kStopTrackingAfter = "stopTrackingAfter"
    private static let kSync = "sync"
    private static let kReplay = "replay"
    private static let kShowBlueBar = "showBlueBar"
    private static let kUseStoppedGeofence = "useStoppedGeofence"
    private static let kStoppedGeofenceRadius = "stoppedGeofenceRadius"
    private static let kUseMovingGeofence = "useMovingGeofence"
    private static let kMovingGeofenceRadius = "movingGeofenceRadius"
    private static let kSyncGeofences = "syncGeofences"
    private static let kUseVisits = "useVisits"
    private static let kUseSignificantLocationChanges = "useSignificantLocationChanges"
    private static let kBeacons = "beacons"
    private static let kUseIndoorScan = "useIndoorScan"
    private static let kUseMotion = "useMotion"
    private static let kUsePressure = "usePressure"

    // MARK: - Properties

    /// Determines the desired location update interval in seconds when stopped. Use 0 to shut down when stopped.
    /// - Warning: Location updates may be delayed significantly by Low Power Mode, or if the device has connectivity issues, low battery, or wi-fi disabled.
    public var desiredStoppedUpdateInterval: Int32 = 0

    /// Determines the desired location update interval in seconds when moving.
    /// - Warning: Location updates may be delayed significantly by Low Power Mode, or if the device has connectivity issues, low battery, or wi-fi disabled.
    public var desiredMovingUpdateInterval: Int32 = 0

    /// Determines the desired sync interval in seconds.
    public var desiredSyncInterval: Int32 = 0

    /// Determines the desired accuracy of location updates.
    public var desiredAccuracy: RadarTrackingOptionsDesiredAccuracy = .medium

    /// With `stopDistance`, determines the duration in seconds after which the device is considered stopped.
    public var stopDuration: Int32 = 0

    /// With `stopDuration`, determines the distance in meters within which the device is considered stopped.
    public var stopDistance: Int32 = 0

    /// Determines when to start tracking. Use `nil` to start tracking when `startTracking` is called.
    public var startTrackingAfter: Date?

    /// Determines when to stop tracking. Use `nil` to track until `stopTracking` is called.
    public var stopTrackingAfter: Date?

    /// Determines which failed location updates to replay to the server.
    public var replay: RadarTrackingOptionsReplay = .none

    /// Determines which location updates to sync to the server.
    public var syncLocations: RadarTrackingOptionsSyncLocations = .all

    /// Determines whether the flashing blue status bar is shown when tracking.
    /// @see https://developer.apple.com/documentation/corelocation/cllocationmanager/2923541-showsbackgroundlocationindicator
    public var showBlueBar: Bool = false

    /// Determines whether to use the iOS region monitoring service (geofencing) to create a client geofence around the device's current location when stopped.
    public var useStoppedGeofence: Bool = false

    /// Determines the radius in meters of the client geofence around the device's current location when stopped.
    public var stoppedGeofenceRadius: Int32 = 0

    /// Determines whether to use the iOS region monitoring service (geofencing) to create a client geofence around the device's current location when moving.
    public var useMovingGeofence: Bool = false

    /// Determines the radius in meters of the client geofence around the device's current location when moving.
    public var movingGeofenceRadius: Int32 = 0

    /// Determines whether to sync nearby geofences from the server to the client to improve responsiveness.
    public var syncGeofences: Bool = false

    /// Determines whether to use the iOS visit monitoring service.
    public var useVisits: Bool = false

    /// Determines whether to use the iOS significant location change service.
    public var useSignificantLocationChanges: Bool = false

    /// Determines whether to monitor beacons.
    public var beacons: Bool = false

    /// Determines whether to use indoor scanning.
    public var useIndoorScan: Bool = false

    /// Determines whether to use the iOS motion activity service.
    public var useMotion: Bool = false

    /// Determines whether to use the iOS pressure service.
    public var usePressure: Bool = false

    // MARK: - Presets

    /// Updates about every 30 seconds while moving or stopped. Moderate battery usage. Shows the flashing blue status bar during tracking.
    public static let presetContinuous: RadarTrackingOptions = {
        let options = RadarTrackingOptions()
        options.desiredStoppedUpdateInterval = 30
        options.desiredMovingUpdateInterval = 30
        options.desiredSyncInterval = 20
        options.desiredAccuracy = .high
        options.stopDuration = 140
        options.stopDistance = 70
        options.syncLocations = .all
        options.replay = .none
        options.showBlueBar = true
        options.syncGeofences = true
        return options
    }()

    /// Updates about every 2.5 minutes when moving and shuts down when stopped to save battery. Low battery usage. Requires the `location` background mode.
    public static let presetResponsive: RadarTrackingOptions = {
        let options = RadarTrackingOptions()
        options.desiredMovingUpdateInterval = 150
        options.desiredSyncInterval = 20
        options.desiredAccuracy = .medium
        options.stopDuration = 140
        options.stopDistance = 70
        options.syncLocations = .all
        options.replay = .stops
        options.useStoppedGeofence = true
        options.stoppedGeofenceRadius = 100
        options.useMovingGeofence = true
        options.movingGeofenceRadius = 100
        options.syncGeofences = true
        options.useVisits = true
        options.useSignificantLocationChanges = true
        return options
    }()

    /// Uses the iOS visit monitoring service to update only on stops and exits. Lowest battery usage.
    public static let presetEfficient: RadarTrackingOptions = {
        let options = RadarTrackingOptions()
        options.desiredAccuracy = .medium
        options.syncLocations = .all
        options.replay = .stops
        options.syncGeofences = true
        options.useVisits = true
        return options
    }()

    // MARK: - String Conversions

    public static func string(forDesiredAccuracy desiredAccuracy: RadarTrackingOptionsDesiredAccuracy) -> String {
        switch desiredAccuracy {
        case .high: return "high"
        case .medium: return "medium"
        case .low: return "low"
        }
    }

    public static func desiredAccuracy(forString str: String) -> RadarTrackingOptionsDesiredAccuracy {
        switch str {
        case "high": return .high
        case "low": return .low
        default: return .medium
        }
    }

    public static func string(forReplay replay: RadarTrackingOptionsReplay) -> String {
        switch replay {
        case .stops: return "stops"
        case .all: return "all"
        case .none: return "none"
        }
    }

    public static func replay(forString str: String) -> RadarTrackingOptionsReplay {
        switch str {
        case "stops": return .stops
        case "all": return .all
        default: return .none
        }
    }

    public static func string(forSyncLocations syncLocations: RadarTrackingOptionsSyncLocations) -> String {
        switch syncLocations {
        case .none: return "none"
        case .stopsAndExits: return "stopsAndExits"
        case .all: return "all"
        }
    }

    public static func syncLocations(forString str: String) -> RadarTrackingOptionsSyncLocations {
        switch str {
        case "stopsAndExits": return .stopsAndExits
        case "none": return .none
        default: return .all
        }
    }

    // MARK: - Dictionary Serialization

    @objc(trackingOptionsFromDictionary:)
    public static func from(dictionary dict: [String: Any]) -> RadarTrackingOptions? {
        let options = RadarTrackingOptions()
        options.desiredStoppedUpdateInterval = (dict[kDesiredStoppedUpdateInterval] as? NSNumber)?.int32Value ?? 0
        options.desiredMovingUpdateInterval = (dict[kDesiredMovingUpdateInterval] as? NSNumber)?.int32Value ?? 0
        options.desiredSyncInterval = (dict[kDesiredSyncInterval] as? NSNumber)?.int32Value ?? 0
        options.desiredAccuracy = desiredAccuracy(forString: dict[kDesiredAccuracy] as? String ?? "")
        options.stopDuration = (dict[kStopDuration] as? NSNumber)?.int32Value ?? 0
        options.stopDistance = (dict[kStopDistance] as? NSNumber)?.int32Value ?? 0

        if let startObj = dict[kStartTrackingAfter] {
            if let date = startObj as? Date {
                options.startTrackingAfter = date
            } else if let str = startObj as? String {
                options.startTrackingAfter = RadarUtils.isoDateFormatter.date(from: str)
            } else if let num = startObj as? NSNumber {
                options.startTrackingAfter = Date(timeIntervalSince1970: num.doubleValue / 1000)
            }
        }

        if let stopObj = dict[kStopTrackingAfter] {
            if let date = stopObj as? Date {
                options.stopTrackingAfter = date
            } else if let str = stopObj as? String {
                options.stopTrackingAfter = RadarUtils.isoDateFormatter.date(from: str)
            } else if let num = stopObj as? NSNumber {
                options.stopTrackingAfter = Date(timeIntervalSince1970: num.doubleValue / 1000)
            }
        }

        options.syncLocations = syncLocations(forString: dict[kSync] as? String ?? "")
        options.replay = replay(forString: dict[kReplay] as? String ?? "")
        options.showBlueBar = (dict[kShowBlueBar] as? NSNumber)?.boolValue ?? false
        options.useStoppedGeofence = (dict[kUseStoppedGeofence] as? NSNumber)?.boolValue ?? false
        options.stoppedGeofenceRadius = (dict[kStoppedGeofenceRadius] as? NSNumber)?.int32Value ?? 0
        options.useMovingGeofence = (dict[kUseMovingGeofence] as? NSNumber)?.boolValue ?? false
        options.movingGeofenceRadius = (dict[kMovingGeofenceRadius] as? NSNumber)?.int32Value ?? 0
        options.syncGeofences = (dict[kSyncGeofences] as? NSNumber)?.boolValue ?? false
        options.useVisits = (dict[kUseVisits] as? NSNumber)?.boolValue ?? false
        options.useSignificantLocationChanges = (dict[kUseSignificantLocationChanges] as? NSNumber)?.boolValue ?? false
        options.beacons = (dict[kBeacons] as? NSNumber)?.boolValue ?? false
        options.useIndoorScan = (dict[kUseIndoorScan] as? NSNumber)?.boolValue ?? false
        options.useMotion = (dict[kUseMotion] as? NSNumber)?.boolValue ?? false
        options.usePressure = (dict[kUsePressure] as? NSNumber)?.boolValue ?? false
        return options
    }

    public func dictionaryValue() -> [String: Any] {
        var dict: [String: Any] = [
            Self.kDesiredStoppedUpdateInterval: NSNumber(value: desiredStoppedUpdateInterval),
            Self.kDesiredMovingUpdateInterval: NSNumber(value: desiredMovingUpdateInterval),
            Self.kDesiredSyncInterval: NSNumber(value: desiredSyncInterval),
            Self.kDesiredAccuracy: Self.string(forDesiredAccuracy: desiredAccuracy),
            Self.kStopDuration: NSNumber(value: stopDuration),
            Self.kStopDistance: NSNumber(value: stopDistance),
            Self.kSync: Self.string(forSyncLocations: syncLocations),
            Self.kReplay: Self.string(forReplay: replay),
            Self.kShowBlueBar: NSNumber(value: showBlueBar),
            Self.kUseStoppedGeofence: NSNumber(value: useStoppedGeofence),
            Self.kStoppedGeofenceRadius: NSNumber(value: stoppedGeofenceRadius),
            Self.kUseMovingGeofence: NSNumber(value: useMovingGeofence),
            Self.kMovingGeofenceRadius: NSNumber(value: movingGeofenceRadius),
            Self.kSyncGeofences: NSNumber(value: syncGeofences),
            Self.kUseVisits: NSNumber(value: useVisits),
            Self.kUseSignificantLocationChanges: NSNumber(value: useSignificantLocationChanges),
            Self.kBeacons: NSNumber(value: beacons),
            Self.kUseIndoorScan: NSNumber(value: useIndoorScan),
            Self.kUseMotion: NSNumber(value: useMotion),
            Self.kUsePressure: NSNumber(value: usePressure),
        ]

        if let startTrackingAfter {
            dict[Self.kStartTrackingAfter] = NSNumber(value: startTrackingAfter.timeIntervalSince1970 * 1000)
        }
        if let stopTrackingAfter {
            dict[Self.kStopTrackingAfter] = NSNumber(value: stopTrackingAfter.timeIntervalSince1970 * 1000)
        }

        return dict
    }

    // MARK: - Equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? RadarTrackingOptions else { return false }
        if self === other { return true }

        return desiredStoppedUpdateInterval == other.desiredStoppedUpdateInterval
            && desiredMovingUpdateInterval == other.desiredMovingUpdateInterval
            && desiredSyncInterval == other.desiredSyncInterval
            && desiredAccuracy == other.desiredAccuracy
            && stopDuration == other.stopDuration
            && stopDistance == other.stopDistance
            && areDatesEqual(startTrackingAfter, other.startTrackingAfter)
            && areDatesEqual(stopTrackingAfter, other.stopTrackingAfter)
            && syncLocations == other.syncLocations
            && replay == other.replay
            && showBlueBar == other.showBlueBar
            && useStoppedGeofence == other.useStoppedGeofence
            && stoppedGeofenceRadius == other.stoppedGeofenceRadius
            && useMovingGeofence == other.useMovingGeofence
            && movingGeofenceRadius == other.movingGeofenceRadius
            && syncGeofences == other.syncGeofences
            && useVisits == other.useVisits
            && useSignificantLocationChanges == other.useSignificantLocationChanges
            && beacons == other.beacons
            && useIndoorScan == other.useIndoorScan
            && useMotion == other.useMotion
            && usePressure == other.usePressure
    }

    private func areDatesEqual(_ a: Date?, _ b: Date?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case (nil, _), (_, nil): return false
        case let (a?, b?): return abs(a.timeIntervalSince1970 - b.timeIntervalSince1970) < Double.ulpOfOne
        }
    }
}
