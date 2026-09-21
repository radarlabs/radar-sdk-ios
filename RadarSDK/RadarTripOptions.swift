//
//  RadarTripOptions.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc @implementation extension RadarTripOptions {

    var externalId: String! = nil
    var metadata: [AnyHashable: Any]?
    var destinationGeofenceTag: String?
    var destinationGeofenceExternalId: String?
    var scheduledArrivalAt: Date?
    var mode: RadarRouteMode = RadarRouteMode(rawValue: 0)
    var approachingThreshold: UInt16 = 0
    var startTracking = false
    var legs: [RadarTripLeg]?

    override init() {
        super.init()
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
        self.init()
        self.externalId = externalId
        self.destinationGeofenceTag = destinationGeofenceTag
        self.destinationGeofenceExternalId = destinationGeofenceExternalId
        self.mode = .car
        self.startTracking = true
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
        self.init()
        self.externalId = externalId
        self.destinationGeofenceTag = destinationGeofenceTag
        self.destinationGeofenceExternalId = destinationGeofenceExternalId
        self.scheduledArrivalAt = scheduledArrivalAt
        self.mode = .car
        self.startTracking = true
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
        self.init()
        self.externalId = externalId
        self.destinationGeofenceTag = destinationGeofenceTag
        self.destinationGeofenceExternalId = destinationGeofenceExternalId
        self.scheduledArrivalAt = scheduledArrivalAt
        self.mode = .car
        self.startTracking = startTracking
    }

    @objc(tripOptionsFromDictionary:)
    public convenience init?(
        from dictionary: [AnyHashable: Any]
    ) {
        guard let parsed = Self.parsed(from: dictionary) else {
            return nil
        }

        self.init()
        externalId = parsed.externalId
        metadata = parsed.metadata
        destinationGeofenceTag = parsed.destinationGeofenceTag
        destinationGeofenceExternalId = parsed.destinationGeofenceExternalId
        scheduledArrivalAt = parsed.scheduledArrivalAt
        mode = parsed.mode
        approachingThreshold = parsed.approachingThreshold
        startTracking = parsed.startTracking
        legs = parsed.legs
    }

    static func scheduledArrival(
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

    static func mode(
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

    static func startTracking(
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

    func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [:]

        if let externalId = optionalExternalId {
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
            let serializedLegs = RadarTripLeg.array(for: legs)
        {
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

        return hasMatchingValues(other) && hasMatchingMetadata(other) && hasMatchingLegs(other)
    }

    private func hasMatchingValues(
        _ other: RadarTripOptions
    ) -> Bool {
        guard let externalId = optionalExternalId,
            let otherExternalId = other.optionalExternalId,
            externalId == otherExternalId
        else {
            return false
        }

        return destinationGeofenceTag == other.destinationGeofenceTag && destinationGeofenceExternalId == other.destinationGeofenceExternalId
            && scheduledArrivalAt == other.scheduledArrivalAt && mode == other.mode && approachingThreshold == other.approachingThreshold && startTracking == other.startTracking
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

private extension RadarTripOptions {
    // The header requires a nonnull NSString, but the legacy Swift initializer uses nil until
    // callers provide an external ID. Keep that compatibility while avoiding IUO comparisons.
    var optionalExternalId: String? {
        externalId as String?
    }
}
