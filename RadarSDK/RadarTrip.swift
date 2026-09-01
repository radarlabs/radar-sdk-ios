//
//  RadarTrip.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/28/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

@objc(RadarTrip)
@objcMembers
class RadarTrip: NSObject {

    // swiftlint:disable:next identifier_name
    public let _id: String?
    public let externalId: String?
    public let metadata: [AnyHashable: Any]?
    public let destinationGeofenceTag: String?
    public let destinationGeofenceExternalId: String?
    public let destinationLocation: RadarCoordinate?
    public let mode: RadarRouteMode
    public let etaDistance: Float
    public let etaDuration: Float
    public let status: RadarTripStatus
    public let orders: [RadarTripOrder]?
    public let legs: [RadarTripLeg]?
    public let currentLegId: String?

    public init(
        id: String?,
        externalId: String,
        metadata: [AnyHashable: Any]?,
        destinationGeofenceTag: String?,
        destinationGeofenceExternalId: String?,
        destinationLocation: RadarCoordinate?,
        mode: RadarRouteMode,
        etaDistance: Float,
        etaDuration: Float,
        status: RadarTripStatus,
        orders: [RadarTripOrder]?,
        legs: [RadarTripLeg]?,
        currentLegId: String?
    ) {
        self._id = id
        self.externalId = externalId
        self.metadata = metadata
        self.destinationGeofenceTag = destinationGeofenceTag
        self.destinationGeofenceExternalId = destinationGeofenceExternalId
        self.destinationLocation = destinationLocation
        self.mode = mode
        self.etaDistance = etaDistance
        self.etaDuration = etaDuration
        self.status = status
        self.orders = orders
        self.legs = legs
        self.currentLegId = currentLegId

        super.init()
    }

    @objc(initWithObject:)
    public convenience init?(object: Any) {
        guard let dictionary = object as? [AnyHashable: Any],
            let externalId = dictionary["externalId"] as? String
        else {
            return nil
        }

        let id = dictionary["_id"] as? String
        let metadata = dictionary["metadata"] as? [AnyHashable: Any]
        let destinationGeofenceTag =
            dictionary["destinationGeofenceTag"] as? String
        let destinationGeofenceExternalId =
            dictionary["destinationGeofenceExternalId"] as? String

        guard
            let destinationLocation = Self.destinationLocation(
                from: dictionary["destinationLocation"]
            )
        else {
            return nil
        }

        let mode = Self.mode(from: dictionary["mode"] as? String)

        let eta = dictionary["eta"] as? [AnyHashable: Any]
        let etaDistance = (eta?["distance"] as? NSNumber)?.floatValue ?? 0
        let etaDuration = (eta?["duration"] as? NSNumber)?.floatValue ?? 0

        let status = Self.status(from: dictionary["status"] as? String)

        let orders = dictionary["orders"].flatMap {
            RadarTripOrder.orders(from: $0)
        }

        let legs = (dictionary["legs"] as? [Any]).flatMap {
            RadarTripLeg.legs(from: $0)
        }

        let currentLegId = dictionary["currentLeg"] as? String

        self.init(
            id: id,
            externalId: externalId,
            metadata: metadata,
            destinationGeofenceTag: destinationGeofenceTag,
            destinationGeofenceExternalId: destinationGeofenceExternalId,
            destinationLocation: destinationLocation,
            mode: mode,
            etaDistance: etaDistance,
            etaDuration: etaDuration,
            status: status,
            orders: orders,
            legs: legs,
            currentLegId: currentLegId
        )
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [
            "mode": Self.string(for: mode),
            "eta": [
                "distance": etaDistance,
                "duration": etaDuration,
            ],
            "status": Self.string(for: status),
        ]

        if let externalId {
            dictionary["externalId"] = externalId
        }

        if let id = _id {
            dictionary["_id"] = id
        }
        if let metadata {
            dictionary["metadata"] = metadata
        }
        if let destinationGeofenceTag {
            dictionary["destinationGeofenceTag"] = destinationGeofenceTag
        }
        if let destinationGeofenceExternalId {
            dictionary["destinationGeofenceExternalId"] =
                destinationGeofenceExternalId
        }
        if let destinationLocation {
            dictionary["destinationLocation"] = [
                "type": "Point",
                "coordinates": [
                    destinationLocation.coordinate.longitude,
                    destinationLocation.coordinate.latitude,
                ],
            ]
        }
        if let orders, !orders.isEmpty {
            dictionary["orders"] = orders.map { $0.dictionaryValue() }
        }
        if let legs, !legs.isEmpty {
            dictionary["legs"] = legs.map { $0.dictionaryValue() }
        }
        if let currentLegId {
            dictionary["currentLeg"] = currentLegId
        }

        return dictionary
    }

    private static func destinationLocation(
        from object: Any?
    ) -> RadarCoordinate?? {
        guard let location = object as? [AnyHashable: Any] else {
            return .some(nil)
        }

        guard let coordinates = location["coordinates"] as? [Any],
            coordinates.count == 2,
            let longitude = coordinates[0] as? NSNumber,
            let latitude = coordinates[1] as? NSNumber
        else {
            return nil
        }

        let coordinate = CLLocationCoordinate2D(
            latitude: CLLocationDegrees(latitude.doubleValue),
            longitude: CLLocationDegrees(longitude.doubleValue)
        )

        return RadarCoordinate(coordinate: coordinate)
    }

    private static func mode(from string: String?) -> RadarRouteMode {
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

    private static func status(from string: String?) -> RadarTripStatus {
        switch string {
        case "started":
            return .started
        case "approaching":
            return .approaching
        case "arrived":
            return .arrived
        case "expired":
            return .expired
        case "completed":
            return .completed
        case "canceled":
            return .canceled
        default:
            return .unknown
        }
    }

    private static func string(for mode: RadarRouteMode) -> String {
        switch mode {
        case .foot:
            return "foot"
        case .bike:
            return "bike"
        case .truck:
            return "truck"
        case .motorbike:
            return "motorbike"
        default:
            return "car"
        }
    }

    private static func string(for status: RadarTripStatus) -> String {
        switch status {
        case .started:
            return "started"
        case .approaching:
            return "approaching"
        case .arrived:
            return "arrived"
        case .expired:
            return "expired"
        case .completed:
            return "completed"
        case .canceled:
            return "canceled"
        default:
            return "unknown"
        }
    }
}
