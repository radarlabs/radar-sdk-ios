//
//  RadarTrackingOptions.swift
//  RadarSDK
//
//  Created by Alan Charles on 9/1/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

// swiftlint:disable file_length

/// An options class used to configure background tracking.
///
/// - SeeAlso: <https://radar.com/documentation/sdk/ios>
@objc(RadarTrackingOptions)
@objcMembers
public class RadarTrackingOptions: NSObject {  // swiftlint:disable:this type_body_length
    /// Determines the desired location update interval in seconds when stopped.
    /// Use `0` to shut down when stopped.
    ///
    /// - Warning: Location updates may be delayed significantly by Low Power Mode,
    /// connectivity issues, low battery, or Wi-Fi being disabled.
    public var desiredStoppedUpdateInterval: Int32 = 0

    /// Determines the desired location update interval in seconds when moving.
    ///
    /// - Warning: Location updates may be delayed significantly by Low Power Mode,
    /// connectivity issues, low battery, or Wi-Fi being disabled.
    public var desiredMovingUpdateInterval: Int32 = 0

    /// Determines the desired sync interval in seconds.
    public var desiredSyncInterval: Int32 = 0

    /// Determines the desired accuracy of location updates.
    public var desiredAccuracy: RadarTrackingOptionsDesiredAccuracy = .high

    /// With `stopDistance`, determines the duration in seconds after which the
    /// device is considered stopped.
    public var stopDuration: Int32 = 0

    /// With `stopDuration`, determines the distance in meters within which the
    /// device is considered stopped.
    public var stopDistance: Int32 = 0

    /// Determines when to start tracking. Use `nil` to start tracking when
    /// `startTracking` is called.
    public var startTrackingAfter: Date?

    /// Determines when to stop tracking. Use `nil` to track until `stopTracking`
    /// is called.
    public var stopTrackingAfter: Date?

    /// Determines which failed location updates to replay to the server.
    public var replay: RadarTrackingOptionsReplay = .stops

    /// Determines which location updates to sync to the server.
    public var syncLocations: RadarTrackingOptionsSyncLocations = .all

    /// Determines whether the flashing blue status bar is shown when tracking.
    ///
    /// - SeeAlso: <https://developer.apple.com/documentation/corelocation/cllocationmanager/2923541-showsbackgroundlocationindicator>
    public var showBlueBar = false

    /// Determines whether to use the iOS region monitoring service (geofencing)
    /// to create a client geofence around the device's current location when
    /// stopped.
    ///
    /// - SeeAlso: <https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions>
    public var useStoppedGeofence = false

    /// Determines the radius in meters of the client geofence around the
    /// device's current location when stopped.
    public var stoppedGeofenceRadius: Int32 = 0

    /// Determines whether to use the iOS region monitoring service (geofencing)
    /// to create a client geofence around the device's current location when
    /// moving.
    ///
    /// - SeeAlso: <https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions>
    public var useMovingGeofence = false

    /// Determines the radius in meters of the client geofence around the
    /// device's current location when moving.
    public var movingGeofenceRadius: Int32 = 0

    /// Determines whether to sync nearby geofences from the server to the
    /// client to improve responsiveness.
    public var syncGeofences = false

    /// Determines whether to use the iOS visit monitoring service.
    ///
    /// - SeeAlso: <https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/using_the_visits_location_service>
    public var useVisits = false

    /// Determines whether to use the iOS significant location change service.
    ///
    /// - SeeAlso: <https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/using_the_significant-change_location_service>
    public var useSignificantLocationChanges = false

    /// Determines whether to monitor beacons.
    public var beacons = false

    /// Determines whether to use indoor scanning.
    public var useIndoorScan = false

    /// Determines whether to use the iOS motion activity service.
    public var useMotion = false

    /// Determines whether to use the iOS pressure service.
    public var usePressure = false

    /// Determines the time interval between batch events, in seconds. Set to
    /// `0` to disable interval-based batching.
    public var batchInterval: Int32 = 0

    /// Determines the size of each batch. Set to `0` to disable size-based
    /// batching.
    public var batchSize: Int32 = 0

    /// The type of tracking options.
    public var type: RadarTrackingOptionsType = .default

    /// Updates about every 30 seconds while moving or stopped. Moderate battery
    /// usage. Shows the flashing blue status bar during tracking.
    ///
    /// - SeeAlso: <https://developer.apple.com/documentation/corelocation/cllocationmanager/2923541-showsbackgroundlocationindicator>
    public class var presetContinuous: RadarTrackingOptions {
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
    }

    /// Updates about every 2.5 minutes when moving and shuts down when stopped
    /// to save battery. Once stopped, the device must move more than 100 meters
    /// to wake up and start moving again. Low battery usage. Requires the
    /// `location` background mode.
    ///
    /// Location updates may be delayed significantly by Low Power Mode,
    /// connectivity issues, low battery, or Wi-Fi being disabled.
    public class var presetResponsive: RadarTrackingOptions {
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
    }

    /// Uses the iOS visit monitoring service to update only on stops and exits.
    /// Once stopped, the device must move several hundred meters and trigger a
    /// visit departure to wake up and start moving again. Lowest battery usage.
    ///
    /// Location updates may be delayed significantly by Low Power Mode,
    /// connectivity issues, low battery, or Wi-Fi being disabled.
    ///
    /// - SeeAlso: <https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/using_the_visits_location_service>
    public class var presetEfficient: RadarTrackingOptions {
        let options = RadarTrackingOptions()

        options.desiredAccuracy = .medium
        options.syncLocations = .all
        options.replay = .stops
        options.syncGeofences = true
        options.useVisits = true

        return options
    }

    // MARK: - Enum Mappings

    @objc(stringForDesiredAccuracy:)
    public class func string(
        for desiredAccuracy: RadarTrackingOptionsDesiredAccuracy
    ) -> String {
        switch desiredAccuracy {
        case .high:
            return "high"
        case .medium:
            return "medium"
        case .low:
            return "low"
        default:
            return "medium"
        }
    }

    @objc(desiredAccuracyForString:)
    public class func desiredAccuracy(
        for string: String
    ) -> RadarTrackingOptionsDesiredAccuracy {
        switch string {
        case "high":
            return .high
        case "low":
            return .low
        default:
            return .medium
        }
    }

    @objc(stringForReplay:)
    public class func string(
        for replay: RadarTrackingOptionsReplay
    ) -> String {
        switch replay {
        case .stops:
            return "stops"
        case .all:
            return "all"
        case .none:
            return "none"
        default:
            return "none"
        }
    }

    @objc(replayForString:)
    public class func replay(
        for string: String
    ) -> RadarTrackingOptionsReplay {
        switch string {
        case "stops":
            return .stops
        case "all":
            return .all
        default:
            return .none
        }
    }

    @objc(stringForSyncLocations:)
    public class func string(
        for syncLocations: RadarTrackingOptionsSyncLocations
    ) -> String {
        switch syncLocations {
        case .none:
            return "none"
        case .stopsAndExits:
            return "stopsAndExits"
        case .events:
            return "events"
        case .all:
            return "all"
        default:
            return "all"
        }
    }

    @objc(syncLocationsForString:)
    public class func syncLocations(
        for string: String
    ) -> RadarTrackingOptionsSyncLocations {
        switch string {
        case "stopsAndExits":
            return .stopsAndExits
        case "none":
            return .none
        case "events":
            return .events
        default:
            return .all
        }
    }

    @objc(stringForType:)
    public class func string(
        for type: RadarTrackingOptionsType
    ) -> String {
        switch type {
        case .onTrip:
            return "on-trip"
        case .inGeofence:
            return "in-geofence"
        case .isUser:
            return "is-user"
        case .default:
            return "default"
        default:
            return "default"
        }
    }

    @objc(typeForString:)
    public class func type(
        for string: String
    ) -> RadarTrackingOptionsType {
        switch string {
        case "on-trip":
            return .onTrip
        case "in-geofence":
            return .inGeofence
        case "is-user":
            return .isUser
        default:
            return .default
        }
    }

    // MARK: - Dictionary Parsing

    @available(swift, obsoleted: 1.0, message: "Use init(from:) instead.")
    @objc(trackingOptionsFromDictionary:)
    public class func trackingOptions(
        fromDictionary dictionary: [AnyHashable: Any]
    ) -> RadarTrackingOptions? {
        RadarTrackingOptions(from: dictionary)
    }

    @nonobjc
    public convenience init?(  // swiftlint:disable:this function_body_length
        from dictionary: [AnyHashable: Any]
    ) {
        self.init()

        desiredStoppedUpdateInterval = Self.intValue(
            from: dictionary["desiredStoppedUpdateInterval"]
        )
        desiredMovingUpdateInterval = Self.intValue(
            from: dictionary["desiredMovingUpdateInterval"]
        )
        desiredSyncInterval = Self.intValue(
            from: dictionary["desiredSyncInterval"]
        )
        desiredAccuracy = Self.desiredAccuracy(
            for: dictionary["desiredAccuracy"] as? String ?? ""
        )
        stopDuration = Self.intValue(
            from: dictionary["stopDuration"]
        )
        stopDistance = Self.intValue(
            from: dictionary["stopDistance"]
        )
        startTrackingAfter = Self.date(
            from: dictionary["startTrackingAfter"]
        )
        stopTrackingAfter = Self.date(
            from: dictionary["stopTrackingAfter"]
        )
        syncLocations = Self.syncLocations(
            for: dictionary["sync"] as? String ?? ""
        )
        replay = Self.replay(
            for: dictionary["replay"] as? String ?? ""
        )
        showBlueBar = Self.boolValue(
            from: dictionary["showBlueBar"]
        )
        useStoppedGeofence = Self.boolValue(
            from: dictionary["useStoppedGeofence"]
        )
        stoppedGeofenceRadius = Self.intValue(
            from: dictionary["stoppedGeofenceRadius"]
        )
        useMovingGeofence = Self.boolValue(
            from: dictionary["useMovingGeofence"]
        )
        movingGeofenceRadius = Self.intValue(
            from: dictionary["movingGeofenceRadius"]
        )
        syncGeofences = Self.boolValue(
            from: dictionary["syncGeofences"]
        )
        useVisits = Self.boolValue(
            from: dictionary["useVisits"]
        )
        useSignificantLocationChanges = Self.boolValue(
            from: dictionary["useSignificantLocationChanges"]
        )
        beacons = Self.boolValue(
            from: dictionary["beacons"]
        )
        useIndoorScan = Self.boolValue(
            from: dictionary["useIndoorScan"]
        )
        useMotion = Self.boolValue(
            from: dictionary["useMotion"]
        )
        usePressure = Self.boolValue(
            from: dictionary["usePressure"]
        )
        batchInterval = Self.intValue(
            from: dictionary["batchInterval"]
        )
        batchSize = Self.intValue(
            from: dictionary["batchSize"]
        )
        type = Self.type(
            for: dictionary["type"] as? String ?? ""
        )
    }

    private static func date(
        from object: Any?
    ) -> Date? {
        if let date = object as? Date {
            return date
        }

        if let string = object as? String {
            return RadarUtils.isoDateFormatter.date(from: string)
        }

        if let milliseconds = object as? NSNumber {
            return Date(
                timeIntervalSince1970:
                    milliseconds.doubleValue / 1_000
            )
        }

        return nil
    }

    private static func intValue(
        from object: Any?
    ) -> Int32 {
        if let number = object as? NSNumber {
            return number.int32Value
        }

        if let string = object as? String {
            return (string as NSString).intValue
        }

        return 0
    }

    private static func boolValue(
        from object: Any?
    ) -> Bool {
        if let number = object as? NSNumber {
            return number.boolValue
        }

        if let string = object as? String {
            return (string as NSString).boolValue
        }

        return false
    }

    // MARK: - Dictionary Serialization

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [
            "desiredStoppedUpdateInterval": desiredStoppedUpdateInterval,
            "desiredMovingUpdateInterval": desiredMovingUpdateInterval,
            "desiredSyncInterval": desiredSyncInterval,
            "desiredAccuracy": Self.string(for: desiredAccuracy),
            "stopDuration": stopDuration,
            "stopDistance": stopDistance,
            "sync": Self.string(for: syncLocations),
            "replay": Self.string(for: replay),
            "showBlueBar": showBlueBar,
            "useStoppedGeofence": useStoppedGeofence,
            "stoppedGeofenceRadius": stoppedGeofenceRadius,
            "useMovingGeofence": useMovingGeofence,
            "movingGeofenceRadius": movingGeofenceRadius,
            "syncGeofences": syncGeofences,
            "useVisits": useVisits,
            "useSignificantLocationChanges": useSignificantLocationChanges,
            "beacons": beacons,
            "useIndoorScan": useIndoorScan,
            "useMotion": useMotion,
            "usePressure": usePressure,
            "batchInterval": batchInterval,
            "batchSize": batchSize,
            "type": Self.string(for: type),
        ]

        if let startTrackingAfter {
            dictionary["startTrackingAfter"] =
                startTrackingAfter.timeIntervalSince1970 * 1_000
        }

        if let stopTrackingAfter {
            dictionary["stopTrackingAfter"] =
                stopTrackingAfter.timeIntervalSince1970 * 1_000
        }

        return dictionary
    }

    // MARK: - Equality

    private static let dateEqualityTolerance: TimeInterval = 0.001

    public override func isEqual(_ object: Any?) -> Bool {
        guard let options = object as? RadarTrackingOptions else {
            return false
        }

        if self === options {
            return true
        }

        return desiredStoppedUpdateInterval
            == options.desiredStoppedUpdateInterval
            && desiredMovingUpdateInterval
                == options.desiredMovingUpdateInterval
            && desiredSyncInterval == options.desiredSyncInterval
            && desiredAccuracy == options.desiredAccuracy
            && stopDuration == options.stopDuration
            && stopDistance == options.stopDistance
            && Self.datesEqual(startTrackingAfter, options.startTrackingAfter)
            && Self.datesEqual(stopTrackingAfter, options.stopTrackingAfter)
            && syncLocations == options.syncLocations
            && replay == options.replay
            && showBlueBar == options.showBlueBar
            && useStoppedGeofence == options.useStoppedGeofence
            && stoppedGeofenceRadius == options.stoppedGeofenceRadius
            && useMovingGeofence == options.useMovingGeofence
            && movingGeofenceRadius == options.movingGeofenceRadius
            && syncGeofences == options.syncGeofences
            && useVisits == options.useVisits
            && useSignificantLocationChanges
                == options.useSignificantLocationChanges
            && beacons == options.beacons
            && useIndoorScan == options.useIndoorScan
            && useMotion == options.useMotion
            && usePressure == options.usePressure
            && batchInterval == options.batchInterval
            && batchSize == options.batchSize
    }

    private static func datesEqual(
        _ first: Date?,
        _ second: Date?
    ) -> Bool {
        switch (first, second) {
        case (nil, nil):
            return true
        case let (first?, second?):
            return abs(
                first.timeIntervalSince1970
                    - second.timeIntervalSince1970
            ) < dateEqualityTolerance
        default:
            return false
        }
    }
}
