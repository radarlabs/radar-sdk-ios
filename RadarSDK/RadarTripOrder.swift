//
//  RadarTripOrder.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarTripOrder)
@objcMembers
class RadarTripOrder: NSObject {

    // swiftlint:disable:next identifier_name
    public let _id: String
    public let guid: String?
    public let handoffMode: String?
    public let status: RadarTripOrderStatus
    public let firedAt: Date?
    public let firedAttempts: NSNumber?
    public let firedReason: String?
    public let updatedAt: Date

    public init(
        id: String,
        guid: String?,
        handoffMode: String?,
        status: RadarTripOrderStatus,
        firedAt: Date?,
        firedAttempts: NSNumber?,
        firedReason: String?,
        updatedAt: Date
    ) {
        self._id = id
        self.guid = guid
        self.handoffMode = handoffMode
        self.status = status
        self.firedAt = firedAt
        self.firedAttempts = firedAttempts
        self.firedReason = firedReason
        self.updatedAt = updatedAt

        super.init()
    }

    @objc(initWithObject:)
    public convenience init?(object: Any) {
        guard let dictionary = object as? [AnyHashable: Any],
            let id = dictionary["id"] as? String,
            let updatedAtString = dictionary["updatedAt"] as? String,
            let updatedAt = RadarUtils.isoDateFormatter.date(
                from: updatedAtString
            )
        else {
            return nil
        }

        let guid = dictionary["guid"] as? String
        let handoffMode = dictionary["handoffMode"] as? String
        let status = Self.status(
            from: dictionary["status"] as? String
        )

        let firedAt = (dictionary["firedAt"] as? String).flatMap {
            RadarUtils.isoDateFormatter.date(from: $0)
        }

        let firedAttempts = dictionary["firedAttempts"] as? NSNumber
        let firedReason = dictionary["firedReason"] as? String

        self.init(
            id: id,
            guid: guid,
            handoffMode: handoffMode,
            status: status,
            firedAt: firedAt,
            firedAttempts: firedAttempts,
            firedReason: firedReason,
            updatedAt: updatedAt
        )
    }

    @objc(ordersFromObject:)
    public static func orders(
        from object: Any
    ) -> [RadarTripOrder]? {
        guard let objects = object as? [Any] else {
            return nil
        }

        var orders: [RadarTripOrder] = []
        orders.reserveCapacity(objects.count)

        for object in objects {
            guard let order = RadarTripOrder(object: object) else {
                return nil
            }

            orders.append(order)
        }

        return orders
    }

    @objc(arrayForOrders:)
    public static func array(
        forOrders orders: [RadarTripOrder]?
    ) -> [[AnyHashable: Any]]? {
        orders?.map { $0.dictionaryValue() }
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [
            "id": _id,
            "status": Self.string(for: status),
            "updatedAt": RadarUtils.isoDateFormatter.string(
                from: updatedAt
            ),
        ]

        if let guid {
            dictionary["guid"] = guid
        }

        if let handoffMode {
            dictionary["handoffMode"] = handoffMode
        }

        if let firedAt {
            dictionary["firedAt"] =
                RadarUtils.isoDateFormatter.string(from: firedAt)
        }

        if let firedAttempts {
            dictionary["firedAttempts"] = firedAttempts
        }

        if let firedReason {
            dictionary["firedReason"] = firedReason
        }

        return dictionary
    }

    private static func status(
        from string: String?
    ) -> RadarTripOrderStatus {
        switch string {
        case "pending":
            return .pending
        case "fired":
            return .fired
        case "canceled":
            return .canceled
        case "completed":
            return .completed
        default:
            return .unknown
        }
    }

    private static func string(
        for status: RadarTripOrderStatus
    ) -> String {
        switch status {
        case .pending:
            return "pending"
        case .fired:
            return "fired"
        case .canceled:
            return "canceled"
        case .completed:
            return "completed"
        default:
            return "unknown"
        }
    }
}
