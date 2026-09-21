//
//  RadarTripOrder.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Keep one initialized value so failed Objective-C initializers can deallocate safely.
private final class RadarTripOrderStorage {
    let id: String
    let guid: String?
    let handoffMode: String?
    let status: RadarTripOrderStatus
    let firedAt: Date?
    let firedAttempts: NSNumber?
    let firedReason: String?
    let updatedAt: Date

    init(
        id: String,
        guid: String?,
        handoffMode: String?,
        status: RadarTripOrderStatus,
        firedAt: Date?,
        firedAttempts: NSNumber?,
        firedReason: String?,
        updatedAt: Date
    ) {
        self.id = id
        self.guid = guid
        self.handoffMode = handoffMode
        self.status = status
        self.firedAt = firedAt
        self.firedAttempts = firedAttempts
        self.firedReason = firedReason
        self.updatedAt = updatedAt
    }
}

@objc @implementation extension RadarTripOrder {

    @nonobjc private var storage: RadarTripOrderStorage?

    // swiftlint:disable:next identifier_name
    public var _id: String! {
        storage?.id
    }
    public var guid: String? {
        storage?.guid
    }
    public var handoffMode: String? {
        storage?.handoffMode
    }
    public var status: RadarTripOrderStatus {
        storage?.status ?? .unknown
    }
    public var firedAt: Date? {
        storage?.firedAt
    }
    public var firedAttempts: NSNumber? {
        storage?.firedAttempts
    }
    public var firedReason: String? {
        storage?.firedReason
    }
    public var updatedAt: Date {
        storage?.updatedAt ?? Date(timeIntervalSince1970: 0)
    }

    public init?(
        id: String,
        guid: String?,
        handoffMode: String?,
        status: RadarTripOrderStatus,
        firedAt: Date?,
        firedAttempts: NSNumber?,
        firedReason: String?,
        updatedAt: Date
    ) {
        self.storage = RadarTripOrderStorage(
            id: id,
            guid: guid,
            handoffMode: handoffMode,
            status: status,
            firedAt: firedAt,
            firedAttempts: firedAttempts,
            firedReason: firedReason,
            updatedAt: updatedAt
        )

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
    public class func orders(
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
    public class func array(
        for orders: [RadarTripOrder]?
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
