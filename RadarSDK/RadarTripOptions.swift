//
//  RadarTripOptions.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarTripOptions)
@objcMembers
class RadarTripOptions: NSObject { // swiftlint:disable:this type_body_length

    public var externalId: String?
    public var metadata: [AnyHashable: Any]?
    public var destinationGeofenceTag: String?
    public var destinationGeofenceExternalId: String?
    public var scheduledArrivalAt: Date?
    public var mode: RadarRouteMode
    public var approachingThreshold: UInt16
    public var startTracking: Bool
    public var legs: [RadarTripLeg]?

    private init(
        externalIdValue: String?,
        destinationGeofenceTag: String?,
        destinationGeofenceExternalId: String?,
        scheduledArrivalAt: Date?,
        mode: RadarRouteMode,
        approachingThreshold: UInt16,
        startTracking: Bool,
        legs: [RadarTripLeg]?
    ) {
        externalId = externalIdValue
        metadata = nil
        self.destinationGeofenceTag = destinationGeofenceTag
        self.destinationGeofenceExternalId =
            destinationGeofenceExternalId
        self.scheduledArrivalAt = scheduledArrivalAt
        self.mode = mode
        self.approachingThreshold = approachingThreshold
        self.startTracking = startTracking
        self.legs = legs

        super.init()
    }

    public override convenience init() {
        self.init(
            externalIdValue: nil,
            destinationGeofenceTag: nil,
            destinationGeofenceExternalId: nil,
            scheduledArrivalAt: nil,
            mode: RadarRouteMode(rawValue: 0),
            approachingThreshold: 0,
            startTracking: false,
            legs: nil
        )
    }

    @objc(
        initWithExternalId:
        destinationGeofenceTag:
        destinationGeofenceExternalId:
    )
    public convenience init(
        externalId: String,
        destinationGeofenceTag: String?,
        destinationGeofenceExternalId: String?
    ) {
        self.init(
            externalIdValue: externalId,
            destinationGeofenceTag: destinationGeofenceTag,
            destinationGeofenceExternalId:
                destinationGeofenceExternalId,
            scheduledArrivalAt: nil,
            mode: .car,
            approachingThreshold: 0,
            startTracking: true,
            legs: nil
        )
    }

    @objc(
        initWithExternalId:
        destinationGeofenceTag:
        destinationGeofenceExternalId:
        scheduledArrivalAt:
    )
    public convenience init(
        externalId: String,
        destinationGeofenceTag: String?,
        destinationGeofenceExternalId: String?,
        scheduledArrivalAt: Date?
    ) {
        self.init(
            externalIdValue: externalId,
            destinationGeofenceTag: destinationGeofenceTag,
            destinationGeofenceExternalId:
                destinationGeofenceExternalId,
            scheduledArrivalAt: scheduledArrivalAt,
            mode: .car,
            approachingThreshold: 0,
            startTracking: true,
            legs: nil
        )
    }

    @objc(
        initWithExternalId:
        destinationGeofenceTag:
        destinationGeofenceExternalId:
        scheduledArrivalAt:
        startTracking:
    )
    public convenience init(
        externalId: String,
        destinationGeofenceTag: String?,
        destinationGeofenceExternalId: String?,
        scheduledArrivalAt: Date?,
        startTracking: Bool
    ) {
        self.init(
            externalIdValue: externalId,
            destinationGeofenceTag: destinationGeofenceTag,
            destinationGeofenceExternalId:
                destinationGeofenceExternalId,
            scheduledArrivalAt: scheduledArrivalAt,
            mode: .car,
            approachingThreshold: 0,
            startTracking: startTracking,
            legs: nil
        )
    }

    @nonobjc
    public convenience init?(
        from dictionary: [AnyHashable: Any]?
    ) {
        guard let dictionary else {
            return nil
        }

        let externalId = dictionary["externalId"] as? String
        let destinationGeofenceTag =
            dictionary["destinationGeofenceTag"] as? String
        let destinationGeofenceExternalId =
            dictionary["destinationGeofenceExternalId"] as? String
        let scheduledArrivalAt = Self.scheduledArrival(
            from: dictionary["scheduledArrivalAt"]
        )
        let mode = Self.mode(
            from: dictionary["mode"] as? String
        )
        let approachingThreshold =
            (dictionary["approachingThreshold"] as? NSNumber)?
                .uint16Value ?? 0
        let startTracking = Self.startTracking(
            from: dictionary["startTracking"]
        )

        let legs: [RadarTripLeg]?
        if let objects = dictionary["legs"] as? [Any] {
            legs = RadarTripLeg.legs(from: objects)
        } else {
            legs = nil
        }

        self.init(
            externalIdValue: externalId,
            destinationGeofenceTag: destinationGeofenceTag,
            destinationGeofenceExternalId:
                destinationGeofenceExternalId,
            scheduledArrivalAt: scheduledArrivalAt,
            mode: mode,
            approachingThreshold: approachingThreshold,
            startTracking: startTracking,
            legs: legs
        )

        metadata = dictionary["metadata"] as? [AnyHashable: Any]
    }

    @objc(tripOptionsFromDictionary:)
    public static func tripOptions(
        fromDictionary dictionary: [AnyHashable: Any]?
    ) -> RadarTripOptions? {
        RadarTripOptions(from: dictionary)
    }

    private static func scheduledArrival(
        from object: Any?
    ) -> Date? {
        if let string = object as? String {
            return RadarUtils.isoDateFormatter.date(from: string)
        }

        if let date = object as? Date {
            return date
        }

        if let milliseconds = object as? NSNumber {
            return Date(
                timeIntervalSince1970:
                    milliseconds.doubleValue / 1_000
            )
        }

        return nil
    }

    private static func mode(
        from string: String?
    ) -> RadarRouteMode {
        switch string {
        case "foot":
            return .foot
        case "bike":
            return .bike
        case "truck":
            return .truck
        case "motorbike":
            return .motorbike
        default:
            return .car
        }
    }

    private static func startTracking(
        from object: Any?
    ) -> Bool {
        if let number = object as? NSNumber {
            return number.boolValue
        }

        if let string = object as? NSString {
            return string.boolValue
        }

        return true
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [:]

        if let externalId {
            dictionary["externalId"] = externalId
        }

        if let metadata {
            dictionary["metadata"] = metadata
        }

        if let destinationGeofenceTag {
            dictionary["destinationGeofenceTag"] =
                destinationGeofenceTag
        }

        if let destinationGeofenceExternalId {
            dictionary["destinationGeofenceExternalId"] =
                destinationGeofenceExternalId
        }

        dictionary["mode"] =
            RadarRouteModeUtils.stringForMode(mode)

        if let scheduledArrivalAt {
            dictionary["scheduledArrivalAt"] =
                RadarUtils.isoDateFormatter.string(
                    from: scheduledArrivalAt
                )
        }

        if approachingThreshold > 0 {
            dictionary["approachingThreshold"] =
                approachingThreshold
        }

        dictionary["startTracking"] = startTracking

        if let legs,
           !legs.isEmpty,
           let serializedLegs = RadarTripLeg.array(for: legs) {
            dictionary["legs"] = serializedLegs
        }

        return dictionary
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? RadarTripOptions else {
            return false
        }

        if self === other {
            return true
        }

        return hasMatchingValues(other) &&
            hasMatchingMetadata(other) &&
            hasMatchingLegs(other)
    }

    private func hasMatchingValues(
        _ other: RadarTripOptions
    ) -> Bool {
        externalId == other.externalId &&
            destinationGeofenceTag ==
                other.destinationGeofenceTag &&
            destinationGeofenceExternalId ==
                other.destinationGeofenceExternalId &&
            scheduledArrivalAt == other.scheduledArrivalAt &&
            mode == other.mode &&
            approachingThreshold == other.approachingThreshold &&
            startTracking == other.startTracking
    }

    private func hasMatchingMetadata(
        _ other: RadarTripOptions
    ) -> Bool {
        switch (metadata, other.metadata) {
        case (nil, nil):
            return true
        case let (metadata?, otherMetadata?):
            return NSDictionary(dictionary: metadata).isEqual(
                to: otherMetadata
            )
        default:
            return false
        }
    }

    private func hasMatchingLegs(
        _ other: RadarTripOptions
    ) -> Bool {
        switch (legs, other.legs) {
        case (nil, nil):
            return true
        case let (legs?, otherLegs?):
            return NSArray(array: legs).isEqual(
                to: otherLegs
            )
        default:
            return false
        }
    }
}
