//
//  RadarTripLeg.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

// swiftlint:disable file_length

import CoreLocation
import Foundation

/// Represents a leg of a multi-destination trip.
///
/// - SeeAlso: https://radar.com/documentation/trip-tracking
@objc(RadarTripLeg)
@objcMembers
public class RadarTripLeg: NSObject {  // swiftlint:disable:this type_body_length

    /// The Radar ID of the leg. Set from server response.
    /// Use this when calling updateTripLeg.
    public private(set) var _id: String?  // swiftlint:disable:this identifier_name

    /// The status of the leg. Set from server response.
    public private(set) var status: RadarTripLegStatus = .unknown

    /// The destination type for this leg.
    /// When parsed from a server response, reflects the server's `destination.type`.
    /// Otherwise, inferred from which properties are set (geofence > address > coordinates).
    public private(set) var destinationType: RadarTripLegDestinationType = .unknown

    /// The date when the leg was created. Set from server response.
    public private(set) var createdAt: Date?

    /// The date when the leg was last updated. Set from server response.
    public private(set) var updatedAt: Date?

    /// The ETA duration in minutes to this leg's destination. Set from server response.
    public private(set) var etaDuration: Float = 0

    /// The ETA distance in meters to this leg's destination. Set from server response.
    public private(set) var etaDistance: Float = 0

    /// The tag of the destination geofence for this leg.
    /// Use with destinationGeofenceExternalId for geofence-based destinations.
    public var destinationGeofenceTag: String?

    /// The external ID of the destination geofence for this leg.
    /// Use with destinationGeofenceTag for geofence-based destinations.
    public var destinationGeofenceExternalId: String?

    /// The Radar ID of the destination geofence for this leg.
    /// Alternative to using destinationGeofenceTag + destinationGeofenceExternalId.
    public var destinationGeofenceId: String?

    /// The address string for the destination of this leg.
    /// Use for address-based destinations.
    public var address: String?

    /// The coordinates for the destination of this leg.
    /// Use for coordinate-based destinations. Set latitude and longitude.
    public var coordinates: CLLocationCoordinate2D {
        didSet {
            hasCoordinates = CLLocationCoordinate2DIsValid(coordinates)
        }
    }

    /// Whether coordinates have been explicitly set.
    public private(set) var hasCoordinates: Bool = false

    /// The arrival radius in meters for coordinate-based destinations.
    /// Only used when coordinates are set.
    public var arrivalRadius: Int = 0

    /// The stop duration in minutes for this leg.
    public var stopDuration: Int = 0

    /// An optional set of custom key-value pairs for this leg.
    public var metadata: [AnyHashable: Any]?

    public override init() {
        coordinates = kCLLocationCoordinate2DInvalid
        super.init()
    }

    /// Initializes a RadarTripLeg with the specified destination geofence tag and external ID.
    ///
    /// - Parameters:
    ///   - destinationGeofenceTag: The tag of the destination geofence.
    ///   - destinationGeofenceExternalId: The external ID of the destination geofence.
    ///
    /// - Returns: A new RadarTripLeg instance.
    @objc(initWithDestinationGeofenceTag:destinationGeofenceExternalId:)
    public convenience init(
        destinationGeofenceTag: String?,
        destinationGeofenceExternalId: String?
    ) {
        self.init()
        self.destinationGeofenceTag = destinationGeofenceTag
        self.destinationGeofenceExternalId =
            destinationGeofenceExternalId
        destinationType = .geofence
    }

    /// Initializes a RadarTripLeg with the specified destination geofence ID.
    ///
    /// - Parameter destinationGeofenceId: The Radar ID of the destination geofence.
    ///
    /// - Returns: A new RadarTripLeg instance.
    @objc(initWithDestinationGeofenceId:)
    public convenience init(destinationGeofenceId: String) {
        self.init()
        self.destinationGeofenceId = destinationGeofenceId
        destinationType = .geofence
    }

    /// Initializes a RadarTripLeg with the specified address.
    ///
    /// - Parameter address: The address string for the destination.
    ///
    /// - Returns: A new RadarTripLeg instance.
    @objc(initWithAddress:)
    public convenience init(address: String) {
        self.init()
        self.address = address
        destinationType = .address
    }

    /// Initializes a RadarTripLeg with the specified coordinates.
    ///
    /// - Parameter coordinates: The coordinates for the destination.
    ///
    /// - Returns: A new RadarTripLeg instance.
    @objc(initWithCoordinates:)
    public convenience init(coordinates: CLLocationCoordinate2D) {
        self.init()
        self.coordinates = coordinates
        hasCoordinates = CLLocationCoordinate2DIsValid(coordinates)
        destinationType = .coordinates
    }

    /// Returns the string representation of a trip leg status.
    ///
    /// - Parameter status: The trip leg status.
    ///
    /// - Returns: The string representation.
    @objc(stringForStatus:)
    public static func string(
        for status: RadarTripLegStatus
    ) -> String {
        switch status {
        case .pending:
            return "pending"
        case .started:
            return "started"
        case .approaching:
            return "approaching"
        case .arrived:
            return "arrived"
        case .completed:
            return "completed"
        case .canceled:
            return "canceled"
        case .expired:
            return "expired"
        default:
            return "unknown"
        }
    }

    /// Returns the trip leg status for a string representation.
    ///
    /// - Parameter string: The string representation.
    ///
    /// - Returns: The trip leg status.
    @objc(statusForString:)
    public static func status(
        for string: String
    ) -> RadarTripLegStatus {
        switch string {
        case "pending":
            return .pending
        case "started":
            return .started
        case "approaching":
            return .approaching
        case "arrived":
            return .arrived
        case "completed":
            return .completed
        case "canceled":
            return .canceled
        case "expired":
            return .expired
        default:
            return .unknown
        }
    }

    /// Returns the string representation of a trip leg destination type.
    ///
    /// - Parameter destinationType: The trip leg destination type.
    ///
    /// - Returns: The string representation.
    @objc(stringForDestinationType:)
    public static func string(
        for destinationType: RadarTripLegDestinationType
    ) -> String {
        switch destinationType {
        case .geofence:
            return "geofence"
        case .address:
            return "address"
        case .coordinates:
            return "coordinates"
        default:
            return "unknown"
        }
    }

    /// Returns the trip leg destination type for a string representation.
    ///
    /// - Parameter string: The string representation.
    ///
    /// - Returns: The trip leg destination type.
    @objc(destinationTypeForString:)
    public static func destinationType(
        for string: String
    ) -> RadarTripLegDestinationType {
        switch string {
        case "geofence":
            return .geofence
        case "address":
            return .address
        case "coordinates":
            return .coordinates
        default:
            return .unknown
        }
    }

    /// Creates a RadarTripLeg from a dictionary representation.
    ///
    /// - Parameter dictionary: The dictionary containing leg data.
    ///
    /// - Returns: A new RadarTripLeg instance, or nil if the dictionary is invalid.
    @nonobjc
    public convenience init?(
        from dictionary: [AnyHashable: Any]?
    ) {
        guard let dictionary else {
            return nil
        }

        self.init()

        _id = dictionary["_id"] as? String

        if let status = dictionary["status"] as? String {
            self.status = Self.status(for: status)
        }

        if let createdAt = dictionary["createdAt"] as? String {
            self.createdAt = RadarUtils.isoDateFormatter.date(
                from: createdAt
            )
        }

        if let updatedAt = dictionary["updatedAt"] as? String {
            self.updatedAt = RadarUtils.isoDateFormatter.date(
                from: updatedAt
            )
        }

        if let eta = dictionary["eta"] as? [AnyHashable: Any] {
            etaDuration =
                (eta["duration"] as? NSNumber)?.floatValue ?? 0
            etaDistance =
                (eta["distance"] as? NSNumber)?.floatValue ?? 0
        }

        if let destination =
            dictionary["destination"] as? [AnyHashable: Any]
        {
            parseDestination(destination)
        }

        if let stopDuration = dictionary["stopDuration"] as? NSNumber {
            self.stopDuration = stopDuration.intValue
        }

        metadata = dictionary["metadata"] as? [AnyHashable: Any]
    }

    /// Creates a RadarTripLeg from a dictionary representation.
    ///
    /// - Parameter object: The dictionary containing leg data.
    ///
    /// - Returns: A new RadarTripLeg instance, or nil if the dictionary is invalid.
    @objc(legFromDictionary:)
    public static func leg(
        fromDictionary object: Any?
    ) -> RadarTripLeg? {
        guard let dictionary = object as? [AnyHashable: Any] else {
            return nil
        }

        return RadarTripLeg(from: dictionary)
    }

    private func parseDestination(
        _ destination: [AnyHashable: Any]
    ) {
        if let type = destination["type"] as? String {
            destinationType = Self.destinationType(for: type)
        }

        if let source =
            destination["source"] as? [AnyHashable: Any]
        {
            parseDestinationSource(source)
        } else {
            parseRequestDestination(destination)
        }

        if let location =
            destination["location"] as? [AnyHashable: Any],
            let coordinates = Self.coordinates(
                from: location["coordinates"]
            )
        {
            self.coordinates = coordinates
        }

        if let arrivalRadius =
            destination["arrivalRadius"] as? NSNumber
        {
            self.arrivalRadius = arrivalRadius.intValue
        }

        inferDestinationTypeIfNeeded()
    }

    private func parseDestinationSource(
        _ source: [AnyHashable: Any]
    ) {
        switch destinationType {
        case .geofence:
            destinationGeofenceId = source["geofence"] as? String

            if let data = source["data"] as? [AnyHashable: Any] {
                destinationGeofenceTag = data["tag"] as? String
                destinationGeofenceExternalId =
                    data["externalId"] as? String
            }

        case .address:
            address = source["data"] as? String

        case .coordinates, .unknown:
            break

        default:
            break
        }
    }

    private func parseRequestDestination(
        _ destination: [AnyHashable: Any]
    ) {
        destinationGeofenceTag =
            destination["destinationGeofenceTag"] as? String
        destinationGeofenceExternalId =
            destination["destinationGeofenceExternalId"] as? String
        destinationGeofenceId =
            destination["destinationGeofenceId"] as? String
        address = destination["address"] as? String

        if let coordinates = Self.coordinates(
            from: destination["coordinates"]
        ) {
            self.coordinates = coordinates
        }
    }

    private func inferDestinationTypeIfNeeded() {
        guard destinationType == .unknown else {
            return
        }

        if destinationGeofenceId != nil || (destinationGeofenceTag != nil && destinationGeofenceExternalId != nil) {
            destinationType = .geofence
        } else if address != nil {
            destinationType = .address
        } else if hasCoordinates {
            destinationType = .coordinates
        }
    }

    private static func coordinates(
        from object: Any?
    ) -> CLLocationCoordinate2D? {
        guard let values = object as? [Any],
            values.count >= 2,
            let longitude = doubleValue(from: values[0]),
            let latitude = doubleValue(from: values[1])
        else {
            return nil
        }

        return CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }

    private static func doubleValue(
        from object: Any
    ) -> Double? {
        if let number = object as? NSNumber {
            return number.doubleValue
        }

        if let string = object as? NSString {
            return string.doubleValue
        }

        return nil
    }

    /// Creates an array of RadarTripLeg objects from an array of dictionaries.
    ///
    /// - Parameter array: The array of dictionaries containing leg data.
    ///
    /// - Returns: An array of RadarTripLeg instances, or nil if the array is invalid.
    @objc(legsFromArray:)
    public static func legs(
        from array: [Any]?
    ) -> [RadarTripLeg]? {
        guard let array else {
            return nil
        }

        let legs = array.compactMap {
            leg(fromDictionary: $0)
        }

        return legs.isEmpty ? nil : legs
    }

    /// Converts the leg to a dictionary representation for API serialization.
    ///
    /// - Returns: A dictionary representation of the leg.
    public func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [:]

        if let id = _id {
            dictionary["_id"] = id
        }

        if status != .unknown {
            dictionary["status"] = Self.string(for: status)
        }

        if let createdAt {
            dictionary["createdAt"] =
                RadarUtils.isoDateFormatter.string(from: createdAt)
        }

        if let updatedAt {
            dictionary["updatedAt"] =
                RadarUtils.isoDateFormatter.string(from: updatedAt)
        }

        if let destination = destinationDictionary() {
            dictionary["destination"] = destination
        }

        if stopDuration > 0 {
            dictionary["stopDuration"] = stopDuration
        }

        if let metadata {
            dictionary["metadata"] = metadata
        }

        if let eta = etaDictionary() {
            dictionary["eta"] = eta
        }

        return dictionary
    }

    private func destinationDictionary() -> [AnyHashable: Any]? {
        var destination: [AnyHashable: Any] = [:]

        if let destinationGeofenceTag {
            destination["destinationGeofenceTag"] =
                destinationGeofenceTag
        }

        if let destinationGeofenceExternalId {
            destination["destinationGeofenceExternalId"] =
                destinationGeofenceExternalId
        }

        if let destinationGeofenceId {
            destination["destinationGeofenceId"] =
                destinationGeofenceId
        }

        if let address {
            destination["address"] = address
        }

        if hasCoordinates {
            destination["coordinates"] = [
                coordinates.longitude,
                coordinates.latitude,
            ]

            if arrivalRadius > 0 {
                destination["arrivalRadius"] = arrivalRadius
            }
        }

        return destination.isEmpty ? nil : destination
    }

    private func etaDictionary() -> [AnyHashable: Any]? {
        guard etaDuration > 0 || etaDistance > 0 else {
            return nil
        }

        var eta: [AnyHashable: Any] = [:]

        if etaDuration > 0 {
            eta["duration"] = etaDuration
        }

        if etaDistance > 0 {
            eta["distance"] = etaDistance
        }

        return eta
    }

    /// Converts an array of legs to an array of dictionaries.
    ///
    /// - Parameter legs: The array of RadarTripLeg instances.
    ///
    /// - Returns: An array of dictionary representations.
    @objc(arrayForLegs:)
    public static func array(
        for legs: [RadarTripLeg]?
    ) -> [[AnyHashable: Any]]? {
        guard let legs, !legs.isEmpty else {
            return nil
        }

        return legs.map { $0.dictionaryValue() }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? RadarTripLeg else {
            return false
        }

        if self === other {
            return true
        }

        return hasMatchingCoreValues(other) && hasMatchingDestination(other) && hasMatchingMetadata(other)
    }

    private func hasMatchingCoreValues(
        _ other: RadarTripLeg
    ) -> Bool {
        guard destinationType == other.destinationType,
            status == other.status,
            stopDuration == other.stopDuration,
            arrivalRadius == other.arrivalRadius,
            hasCoordinates == other.hasCoordinates
        else {
            return false
        }

        guard hasCoordinates else {
            return true
        }

        return coordinates.latitude == other.coordinates.latitude && coordinates.longitude == other.coordinates.longitude
    }

    private func hasMatchingDestination(
        _ other: RadarTripLeg
    ) -> Bool {
        _id == other._id && destinationGeofenceTag == other.destinationGeofenceTag && destinationGeofenceExternalId == other.destinationGeofenceExternalId
            && destinationGeofenceId == other.destinationGeofenceId && address == other.address
    }

    private func hasMatchingMetadata(
        _ other: RadarTripLeg
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
}
