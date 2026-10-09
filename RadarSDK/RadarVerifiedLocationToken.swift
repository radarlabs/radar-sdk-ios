//
//  RadarVerifiedLocationToken.swift
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents a user's verified location.
///
/// - SeeAlso: https://radar.com/documentation/fraud
@objc(RadarVerifiedLocationToken)
@objcMembers
public final class RadarVerifiedLocationToken: NSObject {
    /// The user.
    public let user: RadarUser?

    /// An array of events.
    public let events: [RadarEvent]?

    /// A signed JSON Web Token (JWT) containing the user and array of events. Verify the token server-side using your secret key.
    public let token: String?

    /// The datetime when the token expires.
    public let expiresAt: Date?

    /// The number of seconds until the token expires.
    public let expiresIn: TimeInterval

    /// A boolean indicating whether the user passed all jurisdiction and fraud detection checks.
    public let passed: Bool

    /// An array of failure reasons for jurisdiction and fraud detection checks.
    public let failureReasons: [String]?

    /// The Radar ID of the location check.
    public let _id: String?  // swiftlint:disable:this identifier_name

    /// The full dictionary value of the token.
    public let fullDict: [AnyHashable: Any]?

    override init() {
        user = nil
        events = nil
        token = nil
        expiresAt = nil
        expiresIn = 0
        passed = false
        failureReasons = nil
        _id = nil
        fullDict = nil
        super.init()
    }

    // Declared for Objective-C in RadarVerifiedLocationToken+Internal.h.
    @objc(initWithUser:events:token:expiresAt:expiresIn:passed:failureReasons:_id:fullDict:)
    init(
        user: RadarUser,
        events: [RadarEvent],
        token: String,
        expiresAt: Date,
        expiresIn: TimeInterval,
        passed: Bool,
        failureReasons: [String],
        _id: String?,  // swiftlint:disable:this identifier_name
        fullDict: [AnyHashable: Any]
    ) {
        self.user = user
        self.events = events
        self.token = token
        self.expiresAt = expiresAt
        self.expiresIn = expiresIn
        self.passed = passed
        self.failureReasons = failureReasons
        self._id = _id
        self.fullDict = fullDict
        super.init()
    }

    // Keeps the Objective-C parser declared in RadarVerifiedLocationToken+Internal.h working.
    // `user`, `events`, `token`, and `expiresAt` are required; the rest fall back to defaults.
    // Events are built through `RadarSwift.bridge`, because `RadarEvent`'s parser is internal
    // Objective-C. The bridge is installed by `Radar.initialize`, which runs before any
    // verified track.
    @objc(initWithObject:)
    convenience init?(object: Any) {
        guard let dict = object as? NSDictionary else {
            return nil
        }

        let token = dict["token"] as? String
        let expiresAt = (dict["expiresAt"] as? String).flatMap { RadarUtils.isoDateFormatter.date(from: $0) }
        // Matches the Objective-C parser, which read the value through `-floatValue`.
        let expiresIn = (dict["expiresIn"] as? NSNumber).map { TimeInterval($0.floatValue) } ?? 0
        let passed = (dict["passed"] as? NSNumber)?.boolValue ?? false
        let user = (dict["user"] as? NSDictionary).flatMap { RadarUser(object: $0) }
        let events = (dict["events"] as? NSArray).flatMap(Self.events(from:))
        let failureReasons = (dict["failureReasons"] as? NSArray)?.compactMap { $0 as? String } ?? []
        let id = dict["_id"] as? String

        guard let user, let events, let token, let expiresAt else {
            return nil
        }

        self.init(
            user: user,
            events: events,
            token: token,
            expiresAt: expiresAt,
            expiresIn: expiresIn,
            passed: passed,
            failureReasons: failureReasons,
            _id: id,
            fullDict: dict as? [AnyHashable: Any] ?? [:]
        )
    }

    // Like `+[RadarEvent eventsFromObject:]`, any event that fails to parse fails the whole array.
    private static func events(from array: NSArray) -> [RadarEvent]? {
        var events: [RadarEvent] = []
        for object in array {
            guard let dict = object as? [String: Any], let event = RadarSwift.bridge?.createEvent(dict: dict) else {
                return nil
            }
            events.append(event)
        }
        return events
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        fullDict ?? [:]
    }
}
