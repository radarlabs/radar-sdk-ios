//
//  RadarUser.swift
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// Represents learned home, work, and travel state returned with a track response.
@objc(RadarUserLocationInsights)
@objcMembers
public final class RadarUserLocationInsights: NSObject {
    /// A boolean indicating whether the user is currently at their learned home location.
    public let atHome: Bool

    /// A boolean indicating whether the user is currently at their learned work location.
    public let atWork: Bool

    /// A boolean indicating whether the user is currently traveling away from home.
    public let traveling: Bool

    /// A nullable boolean indicating whether the user is currently commuting.
    public let commuting: NSNumber?

    // Public so `RadarUserLocationInsights()` and `[RadarUserLocationInsights new]` keep working
    // as they did with the old header. Matches Objective-C `-init`, which left every field zeroed.
    public override convenience init() {
        self.init(atHome: false, atWork: false, traveling: false, commuting: nil)
    }

    init(atHome: Bool, atWork: Bool, traveling: Bool, commuting: NSNumber?) {
        self.atHome = atHome
        self.atWork = atWork
        self.traveling = traveling
        self.commuting = commuting
        super.init()
    }

    // Wrongly typed fields are ignored: booleans default to false and `commuting` to nil.
    public convenience init?(object: Any) {
        guard let dict = object as? NSDictionary else {
            return nil
        }

        self.init(
            atHome: RadarUser.bool(dict["atHome"]),
            atWork: RadarUser.bool(dict["atWork"]),
            traveling: RadarUser.bool(dict["traveling"]),
            commuting: dict["commuting"] as? NSNumber
        )
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [
            "atHome": atHome,
            "atWork": atWork,
            "traveling": traveling,
        ]
        dict["commuting"] = commuting
        return dict
    }
}

/// Represents the current user state.
@objc(RadarUser)
@objcMembers
public final class RadarUser: NSObject {
    /// The Radar ID of the user.
    public let _id: String  // swiftlint:disable:this identifier_name

    /// The unique ID of the user, provided when you identified the user. May be `nil` if the user has not been identified.
    public let userId: String?

    /// The device ID of the user.
    public let deviceId: String?

    /// The optional description of the user. Not to be confused with the `NSObject` `description` property.
    public let __description: String?  // swiftlint:disable:this identifier_name

    /// The optional set of custom key-value pairs for the user.
    public let metadata: [AnyHashable: Any]?

    /// The user's current location.
    public let location: CLLocation

    /// The user's current activity type.
    public let activityType: RadarActivityType

    /// An array of the user's current geofences. May be `nil` or empty if the user is not in any geofences.
    ///
    /// - SeeAlso: https://radar.com/documentation/geofences
    public let geofences: [RadarGeofence]?

    /// The user's current place. May be `nil` if the user is not at a place or if Places is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/places
    public let place: RadarPlace?

    /// An array of the user's nearby beacons. May be `nil` or empty if the user is not near any beacons or if Beacons is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/beacons
    public let beacons: [RadarBeacon]?

    /// A boolean indicating whether the user is stopped.
    public let stopped: Bool

    /// A boolean indicating whether the user was last updated in the foreground.
    public let foreground: Bool

    /// The user's current country. May be `nil` if country is not available or if Regions is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/regions
    public let country: RadarRegion?

    /// The user's current state. May be `nil` if state is not available or if Regions is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/regions
    public let state: RadarRegion?

    /// The user's current designated market area (DMA). May be `nil` if DMA is not available or if Regions is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/regions
    public let dma: RadarRegion?

    /// The user's current postal code. May be `nil` if postal code is not available or if Regions is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/regions
    public let postalCode: RadarRegion?

    /// The user's nearby chains. May be `nil` if no chains are nearby or if nearby chains are not enabled.
    public let nearbyPlaceChains: [RadarChain]?

    /// The user's segments. May be `nil` if segments are not enabled.
    public let segments: [RadarSegment]?

    /// The user's nearby chains. May be `nil` if segments are not enabled.
    public let topChains: [RadarChain]?

    /// The source of the user's current location.
    public let source: RadarLocationSource

    /// The user's current trip. May be `nil` if the user is not currently on a trip.
    ///
    /// - SeeAlso: https://radar.com/documentation/trip-tracking
    public let trip: RadarTrip?

    /// A boolean indicating whether the user is marked as debug
    public let debug: Bool

    /// The user's current fraud state. May be `nil` if Fraud is not enabled.
    ///
    /// - SeeAlso: https://radar.com/documentation/fraud
    public let fraud: RadarFraud?

    /// The user's learned home, work, and travel state. May be `nil` if location insights are not enabled.
    public let locationInsights: RadarUserLocationInsights?

    /// The user's expected address state. May be `nil` if an expected address has not been set with `setExpectedAddress:`.
    public let expectedAddress: RadarExpectedAddress?

    public let altitude: Double

    // Public so `RadarUser()` and `[RadarUser new]` keep working as they did with the old header.
    // Matches Objective-C `-init`, which left every field zeroed. The nonnull `_id` and
    // `location` get an empty string and a zero location instead of nil.
    public override init() {
        _id = ""
        userId = nil
        deviceId = nil
        __description = nil
        metadata = nil
        location = CLLocation()
        activityType = RadarActivityType(rawValue: 0) ?? .unknown
        geofences = nil
        place = nil
        beacons = nil
        stopped = false
        foreground = false
        country = nil
        state = nil
        dma = nil
        postalCode = nil
        nearbyPlaceChains = nil
        segments = nil
        topChains = nil
        source = RadarLocationSource(rawValue: 0) ?? .unknown
        trip = nil
        debug = false
        fraud = nil
        locationInsights = nil
        expectedAddress = nil
        altitude = 0
        super.init()
    }

    // Parsing matches the Objective-C implementation: wrongly typed fields are ignored, but a
    // `location` without two or three numeric coordinates, or a missing `_id` or `location`,
    // returns nil. Geofences, beacons, places, and segments are Objective-C models with internal
    // parsers, so they're built through `RadarSwift.modelFactory`, which is installed when the
    // framework loads.
    public init?(object: Any) {
        guard let dict = object as? NSDictionary else {
            return nil
        }

        guard let id = dict["_id"] as? String else {
            return nil
        }

        guard let locationDict = dict["location"] as? NSDictionary,
            let location = Self.location(from: locationDict, accuracy: dict["locationAccuracy"])
        else {
            return nil
        }

        let factory = RadarSwift.modelFactory

        _id = id
        userId = dict["userId"] as? String
        deviceId = dict["deviceId"] as? String
        __description = dict["description"] as? String
        metadata = dict["metadata"] as? [AnyHashable: Any]
        self.location = location
        activityType = Self.activityType(for: dict["activityType"] as? String)
        geofences = (dict["geofences"] as? NSArray).flatMap { array in
            Self.all(array) { factory?.createGeofence(dict: $0) }
        }
        place = (dict["place"] as? [String: Any]).flatMap { factory?.createPlace(dict: $0) }
        beacons = (dict["beacons"] as? NSArray).flatMap { array in
            Self.all(array) { factory?.createBeacon(dict: $0) }
        }
        stopped = Self.bool(dict["stopped"])
        foreground = Self.bool(dict["foreground"])
        country = RadarRegion(object: dict["country"])
        state = RadarRegion(object: dict["state"])
        dma = RadarRegion(object: dict["dma"])
        postalCode = RadarRegion(object: dict["postalCode"])
        nearbyPlaceChains = (dict["nearbyPlaceChains"] as? NSArray)?.compactMap { RadarChain(object: $0) }
        segments = (dict["segments"] as? NSArray)?.compactMap { element in
            (element as? [String: Any]).flatMap { factory?.createSegment(dict: $0) }
        }
        topChains = (dict["topChains"] as? NSArray)?.compactMap { RadarChain(object: $0) }
        source = Self.locationSource(for: dict["source"] as? String)
        trip = dict["trip"].flatMap { RadarTrip(object: $0) }
        debug = Self.bool(dict["debug"])
        fraud = dict["fraud"].flatMap { RadarFraud(object: $0) }
        locationInsights = dict["locationInsights"].flatMap { RadarUserLocationInsights(object: $0) }
        // `altitude` wins over `barometricAltitude` when both are present.
        altitude =
            (dict["altitude"] as? NSNumber)?.doubleValue
            ?? (dict["barometricAltitude"] as? NSNumber)?.doubleValue
            ?? .nan
        expectedAddress = dict["expectedAddress"].flatMap { RadarExpectedAddress(object: $0) }
        super.init()
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        dict["_id"] = _id
        dict["userId"] = userId
        dict["deviceId"] = deviceId
        dict["description"] = __description
        dict["metadata"] = metadata
        dict["location"] = [
            "type": "Point",
            "coordinates": [location.coordinate.longitude, location.coordinate.latitude],
        ]
        dict["activityType"] = Radar.stringForActivityType(activityType)
        dict["geofences"] = RadarGeofence.array(for: geofences)
        dict["place"] = place?.dictionaryValue()
        dict["beacons"] = RadarBeacon.array(for: beacons)
        dict["stopped"] = stopped
        dict["foreground"] = foreground
        dict["country"] = country?.dictionaryValue()
        dict["state"] = state?.dictionaryValue()
        dict["dma"] = dma?.dictionaryValue()
        dict["postalCode"] = postalCode?.dictionaryValue()
        dict["nearbyPlaceChains"] = RadarChain.array(for: nearbyPlaceChains)
        dict["segments"] = RadarSegment.array(for: segments)
        dict["topChains"] = RadarChain.array(for: topChains)
        dict["source"] = Radar.stringForLocationSource(source)
        dict["trip"] = trip?.dictionaryValue()
        dict["debug"] = debug
        dict["fraud"] = fraud?.dictionaryValue()
        dict["locationInsights"] = locationInsights?.dictionaryValue()
        if !altitude.isNaN {
            dict["altitude"] = altitude
        }
        dict["expectedAddress"] = expectedAddress?.dictionaryValue()
        return dict
    }

    // MARK: - Parsing helpers

    static func bool(_ object: Any?) -> Bool {
        return (object as? NSNumber)?.boolValue ?? false
    }

    /// Returns nil if any element isn't a dictionary or fails to parse, like the Objective-C
    /// `+geofencesFromObject:` and `+beaconsFromObject:` helpers.
    private static func all<T>(_ array: NSArray, _ parse: ([String: Any]) -> T?) -> [T]? {
        var result: [T] = []
        for element in array {
            guard let elementDict = element as? [String: Any], let parsed = parse(elementDict) else {
                return nil
            }
            result.append(parsed)
        }
        return result
    }

    private static func location(from locationDict: NSDictionary, accuracy: Any?) -> CLLocation? {
        guard let coordinates = locationDict["coordinates"] as? NSArray,
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

        let horizontalAccuracy = (accuracy as? NSNumber)?.doubleValue ?? -1

        return CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: latitude.doubleValue,
                longitude: longitude.doubleValue
            ),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: -1,
            timestamp: Date()
        )
    }

    private static func activityType(for string: String?) -> RadarActivityType {
        switch string {
        case "car": return .car
        case "bike": return .bike
        case "foot": return .foot
        case "run": return .run
        case "stationary": return .stationary
        default: return .unknown
        }
    }

    // Only the sources the Objective-C parser recognized; anything else is `.unknown`.
    private static func locationSource(for string: String?) -> RadarLocationSource {
        switch string {
        case "FOREGROUND_LOCATION": return .foregroundLocation
        case "BACKGROUND_LOCATION": return .backgroundLocation
        case "MANUAL_LOCATION": return .manualLocation
        case "GEOFENCE_ENTER": return .geofenceEnter
        case "GEOFENCE_EXIT": return .geofenceExit
        case "VISIT_ARRIVAL": return .visitArrival
        case "VISIT_DEPARTURE": return .visitDeparture
        case "MOCK_LOCATION": return .mockLocation
        default: return .unknown
        }
    }
}
