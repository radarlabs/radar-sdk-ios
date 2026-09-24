//
//  RadarTimeZone.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

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

    // swiftlint:disable:next identifier_name
    public var _id: String { idValue ?? "" }
    @nonobjc var id: String? { idValue }
    public var name: String { nameValue ?? "" }
    public var code: String { codeValue ?? "" }
    public var currentTime: Date { currentTimeValue ?? Date(timeIntervalSince1970: 0) }
    public let utcOffset: Int32
    public let dstOffset: Int32

    public override init() {
        idValue = nil
        nameValue = nil
        codeValue = nil
        currentTimeValue = nil
        utcOffset = 0
        dstOffset = 0
        super.init()
    }

    /// Keeps the hand-written Objective-C header's `initWithObject:` selector working.
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

    public func dictionaryValue() -> [String: Any] {
        var dictionary: [String: Any] = [:]
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
