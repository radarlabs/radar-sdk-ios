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

@objc(RadarTripLeg)
@objcMembers
class RadarTripLeg: NSObject {  // swiftlint:disable:this type_body_length

    // swiftlint:disable:next identifier_name
    public private(set) var _id: String?
    public private(set) var status: RadarTripLegStatus = .unknown
    public private(set) var destinationType: RadarTripLegDestinationType = .unknown
    public private(set) var createdAt: Date?
    public private(set) var updatedAt: Date?
    public private(set) var etaDuration: Float = 0
    public private(set) var etaDistance: Float = 0

    public var destinationGeofenceTag: String?
    public var destinationGeofenceExternalId: String?
    public var destinationGeofenceId: String?
    public var address: String?

    public var coordinates: CLLocationCoordinate2D {
        didSet {
            hasCoordinates = CLLocationCoordinate2DIsValid(coordinates)
        }
    }

    public private(set) var hasCoordinates: Bool = false
    public var arrivalRadius: Int = 0
    public var stopDuration: Int = 0
    public var metadata: [AnyHashable: Any]?

    public override init() {
        coordinates = kCLLocationCoordinate2DInvalid
        super.init()
    }

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

    @objc(initWithDestinationGeofenceId:)
    public convenience init(destinationGeofenceId: String) {
        self.init()
        self.destinationGeofenceId = destinationGeofenceId
        destinationType = .geofence
    }

    @objc(initWithAddress:)
    public convenience init(address: String) {
        self.init()
        self.address = address
        destinationType = .address
    }

    @objc(initWithCoordinates:)
    public convenience init(coordinates: CLLocationCoordinate2D) {
        self.init()
        self.coordinates = coordinates
        hasCoordinates = CLLocationCoordinate2DIsValid(coordinates)
        destinationType = .coordinates
    }

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
