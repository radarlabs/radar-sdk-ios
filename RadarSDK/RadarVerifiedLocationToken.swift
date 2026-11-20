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
    /// The response format selected by the server.
    public let format: RadarResponseFormat

    /// The user. Available for JWS responses.
    public let user: RadarUser?

    /// The events. Available for JWS responses.
    public let events: [RadarEvent]?

    /// The response token. Relay it to the customer backend for verification.
    /// JWE tokens must first be decrypted by the customer backend.
    public let token: String?

    /// The datetime when the token expires. Unavailable for ID responses.
    public let expiresAt: Date?

    /// The number of seconds until the token expires. Zero for ID responses.
    public let expiresIn: TimeInterval

    /// Whether the evaluation passed. Unavailable for ID responses, which return false.
    /// Authorization decisions require backend verification.
    public let passed: Bool

    /// Failure reasons. Available for JWS responses.
    public let failureReasons: [String]?

    /// The Radar ID of the location check.
    public let _id: String?  // swiftlint:disable:this identifier_name

    /// The response dictionary.
    public let fullDict: [AnyHashable: Any]?

    override init() {
        format = .jws
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

    // Preserve the existing initializer and Objective-C selector.
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
        format = .jws
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

    @nonobjc
    private init(
        format: RadarResponseFormat,
        id: String,
        token: String?,
        expiresAt: Date?,
        expiresIn: TimeInterval,
        passed: Bool,
        fullDict: [AnyHashable: Any]
    ) {
        self.format = format
        user = nil
        events = nil
        self.token = token
        self.expiresAt = expiresAt
        self.expiresIn = expiresIn
        self.passed = passed
        failureReasons = nil
        _id = id
        self.fullDict = fullDict
        super.init()
    }

    private struct JWEData: Decodable {
        let _id: String  // swiftlint:disable:this identifier_name
        let token: String
        let expiresAt: String
        let expiresIn: TimeInterval
        let passed: Bool
    }

    @objc(initWithObject:)
    convenience init?(object: Any) {  // swiftlint:disable:this function_body_length
        guard let dict = object as? NSDictionary,
            let format = RadarResponseFormat(responseValue: dict["format"])
        else {
            return nil
        }

        switch format {
        case .jws:
            let token = dict["token"] as? String
            let expiresAt = (dict["expiresAt"] as? String).flatMap {
                RadarUtils.isoDateFormatter.date(from: $0)
            }

            // Preserve the legacy parser's float precision and defaults.
            let expiresIn =
                (dict["expiresIn"] as? NSNumber).map {
                    TimeInterval($0.floatValue)
                } ?? 0
            let passed = (dict["passed"] as? NSNumber)?.boolValue ?? false
            let user = (dict["user"] as? NSDictionary).flatMap {
                RadarUser(object: $0)
            }
            // Drop malformed events using the shared RadarEvent parser.
            let events = RadarEvent.events(from: dict["events"])
            let failureReasons =
                (dict["failureReasons"] as? NSArray)?
                .compactMap { $0 as? String } ?? []
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

        case .jwe:
            let responseDictionary = Self.clearDictionary(
                dict,
                keys: [
                    "meta", "format", "_id", "token",
                    "expiresAt", "expiresIn", "passed",
                ]
            )

            guard JSONSerialization.isValidJSONObject(responseDictionary),
                let data = try? JSONSerialization.data(
                    withJSONObject: responseDictionary
                ),
                let response = try? JSONDecoder().decode(JWEData.self, from: data),
                !response._id.isEmpty,
                !response.token.isEmpty,
                let expiresAt = Self.parseExpiration(response.expiresAt)
            else {
                return nil
            }

            self.init(
                format: .jwe,
                id: response._id,
                token: response.token,
                expiresAt: expiresAt,
                expiresIn: response.expiresIn,
                passed: response.passed,
                fullDict: responseDictionary
            )

        case .id:
            guard let id = dict["_id"] as? String, !id.isEmpty else {
                return nil
            }

            self.init(
                format: .id,
                id: id,
                token: nil,
                expiresAt: nil,
                expiresIn: 0,
                passed: false,
                fullDict: Self.clearDictionary(
                    dict,
                    keys: ["meta", "format", "_id"]
                )
            )
        }
    }

    private static func clearDictionary(
        _ dictionary: NSDictionary,
        keys: [String]
    ) -> [AnyHashable: Any] {
        var result: [AnyHashable: Any] = [:]
        for key in keys {
            if let value = dictionary[key] {
                result[key] = value
            }
        }
        return result
    }

    private static func parseExpiration(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        fullDict ?? [:]
    }
}
