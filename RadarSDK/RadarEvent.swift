//
//  RadarEvent.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// `RadarEventType`, `RadarEventConfidence`, and `RadarEventVerification` stay declared in
// Include/RadarEvent.h, because other Objective-C headers use them.

/// Represents a change in user state.
@objc(RadarEvent)
@objcMembers
public final class RadarEvent: NSObject {
    /// The Radar ID of the event.
    public let _id: String  // swiftlint:disable:this identifier_name

    /// The datetime when the event occurred on the device.
    public let createdAt: Date

    /// The datetime when the event was created on the server. May be `nil` if the server did not return it,
    /// for example for conversion events.
    public let actualCreatedAt: Date?

    /// A boolean indicating whether the event was generated with your live API key.
    public let live: Bool

    /// The type of the event.
    public let type: RadarEventType

    /// The name of the conversion event. This will only be set if the `type` is `RadarEventTypeConversion`.
    public let conversionName: String?

    /// The geofence for which the event was generated. May be `nil` for non-geofence events.
    public let geofence: RadarGeofence?

    /// The place for which the event was generated. May be `nil` for non-place events.
    public let place: RadarPlace?

    /// The region for which the event was generated. May be `null` for non-region events.
    public let region: RadarRegion?

    /// The beacon for which the event was generated. May be `nil` for non-beacon events.
    public let beacon: RadarBeacon?

    /// The trip for which the event was generated. May be `nil` for non-trip events.
    public let trip: RadarTrip?

    /// The fraud checks for which the event was generated. May be `nil` for non-fraud events.
    public let fraud: RadarFraud?

    /// For place entry events, alternate place candidates. May be `nil` for non-place events.
    public let alternatePlaces: [RadarPlace]?

    /// For accepted place entry events, the verified place. May be `nil` for non-place events or unverified events.
    public let verifiedPlace: RadarPlace?

    /// The verification of the event.
    public let verification: RadarEventVerification

    /// The confidence level of the event.
    public let confidence: RadarEventConfidence

    /// The duration between entry and exit events, in minutes, for exit events. 0 for entry events.
    public let duration: Float

    /// The location of the event. May be `nil` if the event has no location, for example for conversion
    /// events logged with `Radar.logConversion`.
    public let location: CLLocation?

    /// A boolean indicating whether the event came from a replayed location.
    public let replayed: Bool

    // Nil when the event had no metadata, so `dictionaryValue()` omits the key as before. Swift
    // callers already saw `[:]` for nil, because Swift bridges a nil dictionary as empty.
    private let metadataValue: [AnyHashable: Any]?

    /// The metadata of the event. Present on conversion events only.
    public var metadata: [AnyHashable: Any] { metadataValue ?? [:] }

    // Public so `RadarEvent()` and `[RadarEvent new]` keep working as they did with the old header.
    // Matches Objective-C `-init`, which left every field zeroed. The nonnull `_id` and `createdAt`
    // get an empty string and the 1970 epoch instead of nil.
    public override init() {
        _id = ""
        createdAt = Date(timeIntervalSince1970: 0)
        actualCreatedAt = nil
        live = false
        type = .unknown
        conversionName = nil
        geofence = nil
        place = nil
        region = nil
        beacon = nil
        trip = nil
        fraud = nil
        alternatePlaces = nil
        verifiedPlace = nil
        verification = .unverify
        confidence = .none
        duration = 0
        location = nil
        replayed = false
        metadataValue = nil
        super.init()
    }

    // Parsing matches the Objective-C implementation: wrongly typed fields are ignored, but a
    // missing `_id` or `createdAt`, a `location` that is present but malformed, or an alternate
    // place that fails to parse returns nil. A missing `location` or `actualCreatedAt` is nil;
    // conversion events have neither. Geofences, places, and beacons are Objective-C models with internal
    // parsers, so they're built through `RadarSwift.modelFactory`, which is installed when the
    // framework loads.
    @objc(initWithObject:)
    init?(object: Any?) {
        guard let dict = object as? NSDictionary,
            let id = dict["_id"] as? String,
            let createdAt = Self.date(from: dict["createdAt"])
        else {
            return nil
        }

        var location: CLLocation?
        if let locationObject = dict["location"], !(locationObject is NSNull) {
            guard let parsed = Self.location(from: locationObject, in: dict, timestamp: createdAt) else {
                return nil
            }
            location = parsed
        }

        let factory = RadarSwift.modelFactory
        let alternatePlacesArray = dict["alternatePlaces"] as? NSArray
        let alternatePlaces = alternatePlacesArray.flatMap { Self.places(from: $0, factory: factory) }
        if alternatePlacesArray != nil && alternatePlaces == nil {
            return nil
        }

        _id = id
        self.createdAt = createdAt
        actualCreatedAt = Self.date(from: dict["actualCreatedAt"])
        live = (dict["live"] as? NSNumber)?.boolValue ?? false
        (type, conversionName) = Self.typeAndConversionName(from: dict["type"])
        geofence = (dict["geofence"] as? [String: Any]).flatMap { factory?.createGeofence(dict: $0) }
        place = (dict["place"] as? [String: Any]).flatMap { factory?.createPlace(dict: $0) }
        region = RadarRegion(object: dict["region"])
        beacon = (dict["beacon"] as? [String: Any]).flatMap { factory?.createBeacon(dict: $0) }
        trip = dict["trip"].flatMap { RadarTrip(object: $0) }
        fraud = dict["fraud"].flatMap { RadarFraud(object: $0) }
        self.alternatePlaces = alternatePlaces
        verifiedPlace = (dict["verifiedPlace"] as? [String: Any]).flatMap { factory?.createPlace(dict: $0) }
        verification = Self.verification(for: dict["verification"] as? NSNumber)
        confidence = Self.confidence(for: dict["confidence"] as? NSNumber)
        duration = (dict["duration"] as? NSNumber)?.floatValue ?? 0
        self.location = location
        replayed = (dict["replayed"] as? NSNumber)?.boolValue ?? false
        metadataValue = Self.metadata(from: dict["metadata"])
        super.init()
    }

    // Returns nil for a non-array. An event that fails to parse, for example because it has no
    // `_id` or a malformed `location`, is dropped and logged, so the other events and the rest of
    // the response still go through. The Android SDK does the same.
    @objc(eventsFromObject:)
    static func events(from object: Any?) -> [RadarEvent]? {
        guard let array = object as? NSArray else {
            return nil
        }

        var events: [RadarEvent] = []
        for element in array {
            guard let event = RadarEvent(object: element) else {
                let id = ((element as? NSDictionary)?["_id"] as? String) ?? "unknown"
                RadarLogger.shared.warning("Dropped an event that failed to parse | _id = \(id)")
                continue
            }
            events.append(event)
        }
        return events
    }

    @objc(stringForType:)
    public static func string(for type: RadarEventType) -> String? {
        if let string = typeStrings.first(where: { $0.type == type })?.string {
            return string
        }
        return type == .conversion ? "custom" : "unknown"
    }

    @objc(arrayForEvents:)
    public static func array(for events: [RadarEvent]?) -> [[AnyHashable: Any]]? {
        events?.map { $0.dictionaryValue() }
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        dict["_id"] = _id
        dict["live"] = live
        dict["type"] = Self.string(for: type)
        dict["geofence"] = geofence?.dictionaryValue()
        dict["place"] = place?.dictionaryValue()
        dict["confidence"] = confidence.rawValue
        if duration != 0 {
            dict["duration"] = duration
        }
        dict["region"] = region?.dictionaryValue()
        dict["beacon"] = beacon?.dictionaryValue()
        dict["trip"] = trip?.dictionaryValue()
        dict["fraud"] = fraud?.dictionaryValue()
        dict["alternatePlaces"] = RadarPlace.array(for: alternatePlaces)
        if let location {
            dict["location"] = [
                "type": "Point",
                "coordinates": [location.coordinate.longitude, location.coordinate.latitude],
            ]
        }
        dict["replayed"] = replayed
        dict["metadata"] = metadataValue
        dict["createdAt"] = RadarUtils.isoDateFormatter.string(from: createdAt)
        dict["actualCreatedAt"] = actualCreatedAt.map { RadarUtils.isoDateFormatter.string(from: $0) }
        return dict
    }
}

// MARK: - Parsing helpers

extension RadarEvent {
    // These strings should match the values of the server's event constants. A type string not
    // listed here is a conversion event named by that string.
    private static let typeStrings: [(type: RadarEventType, string: String)] = [
        (.userEnteredGeofence, "user.entered_geofence"),
        (.userExitedGeofence, "user.exited_geofence"),
        (.userDwelledInGeofence, "user.dwelled_in_geofence"),
        (.userEnteredPlace, "user.entered_place"),
        (.userExitedPlace, "user.exited_place"),
        (.userEnteredRegionCountry, "user.entered_region_country"),
        (.userExitedRegionCountry, "user.exited_region_country"),
        (.userEnteredRegionDMA, "user.entered_region_dma"),
        (.userExitedRegionDMA, "user.exited_region_dma"),
        (.userEnteredRegionState, "user.entered_region_state"),
        (.userExitedRegionState, "user.exited_region_state"),
        (.userEnteredRegionPostalCode, "user.entered_region_postal_code"),
        (.userExitedRegionPostalCode, "user.exited_region_postal_code"),
        (.userNearbyPlaceChain, "user.nearby_place_chain"),
        (.userEnteredBeacon, "user.entered_beacon"),
        (.userExitedBeacon, "user.exited_beacon"),
        (.userStartedTrip, "user.started_trip"),
        (.userUpdatedTrip, "user.updated_trip"),
        (.userStoppedTrip, "user.stopped_trip"),
        (.userApproachingTripDestination, "user.approaching_trip_destination"),
        (.userArrivedAtTripDestination, "user.arrived_at_trip_destination"),
        (.userArrivedAtWrongTripDestination, "user.arrived_at_wrong_trip_destination"),
        (.userFailedFraud, "user.failed_fraud"),
        (.userFiredTripOrders, "user.fired_trip_orders"),
        (.userEnteredHome, "user.entered_home"),
        (.userExitedHome, "user.exited_home"),
        (.userEnteredWork, "user.entered_work"),
        (.userExitedWork, "user.exited_work"),
        (.userStartedTraveling, "user.started_traveling"),
        (.userStoppedTraveling, "user.stopped_traveling"),
        (.userStartedCommuting, "user.started_commuting"),
        (.userStoppedCommuting, "user.stopped_commuting"),
    ]

    // A missing or non-string type is `.unknown`; an unlisted string is a named conversion.
    private static func typeAndConversionName(from object: Any?) -> (RadarEventType, String?) {
        guard let string = object as? String else {
            return (.unknown, nil)
        }
        if let type = typeStrings.first(where: { $0.string == string })?.type {
            return (type, nil)
        }
        return (.conversion, string)
    }

    // Returns nil if any element isn't a dictionary or fails to parse.
    private static func places(from array: NSArray, factory: RadarModelFactoryProtocol?) -> [RadarPlace]? {
        var places: [RadarPlace] = []
        for element in array {
            guard let placeDict = element as? [String: Any], let place = factory?.createPlace(dict: placeDict) else {
                return nil
            }
            places.append(place)
        }
        return places
    }

    // Like the Objective-C parser, reads the value through `-intValue`; other values are unverified.
    private static func verification(for number: NSNumber?) -> RadarEventVerification {
        switch number?.int32Value {
        case 1: return .accept
        case -1: return .reject
        default: return .unverify
        }
    }

    // Like the Objective-C parser, reads the value through `-intValue`; other values are `.none`.
    private static func confidence(for number: NSNumber?) -> RadarEventConfidence {
        switch number?.int32Value {
        case 3: return .high
        case 2: return .medium
        case 1: return .low
        default: return .none
        }
    }

    // Returns nil unless `object` is a dictionary whose `coordinates` hold a numeric longitude and
    // latitude and, optionally, an altitude. A missing or non-numeric altitude or `locationAccuracy`
    // becomes -1.
    private static func location(from object: Any, in dict: NSDictionary, timestamp: Date) -> CLLocation? {
        guard let locationDict = object as? NSDictionary,
            let coordinates = locationDict["coordinates"] as? NSArray,
            coordinates.count == 2 || coordinates.count == 3,
            let longitude = coordinates[0] as? NSNumber,
            let latitude = coordinates[1] as? NSNumber
        else {
            return nil
        }

        var altitude: CLLocationDistance = -1
        if coordinates.count == 3, let altitudeNumber = coordinates[2] as? NSNumber {
            altitude = altitudeNumber.doubleValue
        }

        let horizontalAccuracy = (dict["locationAccuracy"] as? NSNumber)?.doubleValue ?? -1

        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude.doubleValue, longitude: longitude.doubleValue),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: -1,
            timestamp: timestamp
        )
    }

    private static func date(from object: Any?) -> Date? {
        (object as? String).flatMap { RadarUtils.isoDateFormatter.date(from: $0) }
    }

    // Accepts a dictionary, or a string holding a JSON object. Anything else is nil.
    private static func metadata(from object: Any?) -> [AnyHashable: Any]? {
        if let dict = object as? NSDictionary {
            return dict as? [AnyHashable: Any]
        }
        if let string = object as? String {
            let json = try? JSONSerialization.jsonObject(with: Data(string.utf8))
            return json as? [AnyHashable: Any]
        }
        return nil
    }
}
