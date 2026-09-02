//
//  RadarTrackingOptions.swift
//  RadarSDK
//
//  Created by Alan Charles on 9/1/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

// swiftlint:disable file_length

@objc
@implementation
extension RadarTrackingOptions {
    public var desiredStoppedUpdateInterval: Int32 = 0
    public var desiredMovingUpdateInterval: Int32 = 0
    public var desiredSyncInterval: Int32 = 0
    public var desiredAccuracy: RadarTrackingOptionsDesiredAccuracy = .high
    public var stopDuration: Int32 = 0
    public var stopDistance: Int32 = 0
    private var storedStartTrackingAfter: NSDate?
    private var storedStopTrackingAfter: NSDate?

    public var startTrackingAfter: Date? {
        get { storedStartTrackingAfter as Date? }
        set { storedStartTrackingAfter = newValue as NSDate? }
    }

    public var stopTrackingAfter: Date? {
        get { storedStopTrackingAfter as Date? }
        set { storedStopTrackingAfter = newValue as NSDate? }
    }

    public var replay: RadarTrackingOptionsReplay = .stops
    public var syncLocations: RadarTrackingOptionsSyncLocations = .all
    public var showBlueBar = false
    public var useStoppedGeofence = false
    public var stoppedGeofenceRadius: Int32 = 0
    public var useMovingGeofence = false
    public var movingGeofenceRadius: Int32 = 0
    public var syncGeofences = false
    public var useVisits = false
    public var useSignificantLocationChanges = false
    public var beacons = false
    public var useIndoorScan = false
    public var useMotion = false
    public var usePressure = false
    public var batchInterval: Int32 = 0
    public var batchSize: Int32 = 0
    public var type: RadarTrackingOptionsType = .default

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

    @objc(radar_trackingOptionsFromDictionary:)
    private class func radarTrackingOptions(
        from dictionary: [AnyHashable: Any]?
    ) -> RadarTrackingOptions? {
        RadarTrackingOptions(dictionary: dictionary)
    }

    @nonobjc
    private convenience init?(  // swiftlint:disable:this function_body_length
        dictionary: [AnyHashable: Any]?
    ) {
        guard let dictionary else {
            return nil
        }

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
