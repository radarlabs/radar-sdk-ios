//
//  RadarTimeZone.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents a time zone.
/// - SeeAlso: https://radar.com/documentation/api#geocoding
@objc(RadarTimeZone)
@objcMembers
public final class RadarTimeZone: NSObject {
    /// Keep one formatter to preserve the legacy wire format and POSIX locale.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

    private let idValue: String?
    private let nameValue: String?
    private let codeValue: String?
    private let currentTimeValue: Date?

    /// The ID of the time zone.
    public var _id: String { idValue ?? "" }  // swiftlint:disable:this identifier_name
    /// The name of of the time zone.
    public var name: String { nameValue ?? "" }
    /// The time zone abbreviation.
    public var code: String { codeValue ?? "" }
    /// The current time for the time zone.
    public var currentTime: Date { currentTimeValue ?? Date(timeIntervalSince1970: 0) }
    /// The UTC offset for the time zone.
    public let utcOffset: Int32
    /// The DST offset for the time zone.
    public let dstOffset: Int32

    override init() {
        idValue = nil
        nameValue = nil
        codeValue = nil
        currentTimeValue = nil
        utcOffset = 0
        dstOffset = 0
        super.init()
    }

    // Keeps the hand-written Objective-C header's `initWithObject:` selector working.
    @objc(initWithObject:)
    init?(object: Any) {
        guard let dictionary = object as? NSDictionary else {
            return nil
        }

        idValue = dictionary["id"] as? String
        nameValue = dictionary["name"] as? String
        codeValue = dictionary["code"] as? String
        if let currentTimeString = dictionary["currentTime"] as? String {
            currentTimeValue = Self.dateFormatter.date(from: currentTimeString)
        } else {
            currentTimeValue = nil
        }
        utcOffset = (dictionary["utcOffset"] as? NSNumber)?.int32Value ?? 0
        dstOffset = (dictionary["dstOffset"] as? NSNumber)?.int32Value ?? 0
        super.init()
    }

    public func dictionaryValue() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [:]
        if let id = idValue {
            dictionary["id"] = id
        }
        if let name = nameValue {
            dictionary["name"] = name
        }
        if let code = codeValue {
            dictionary["code"] = code
        }
        if let currentTime = currentTimeValue {
            dictionary["currentTime"] = Self.dateFormatter.string(from: currentTime)
        }
        dictionary["utcOffset"] = NSNumber(value: utcOffset)
        dictionary["dstOffset"] = NSNumber(value: dstOffset)
        return dictionary
    }
}
