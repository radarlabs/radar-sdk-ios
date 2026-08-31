//
//  RadarTimeZone.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents a time zone. Keeps interopt with Obj-C
///
/// See https://radar.com/documentation/api#geocoding
struct RadarTimeZoneSwift: Codable, Sendable, Equatable {
    /// Parses and serializes `currentTime`.
    ///
    /// Mirrors the legacy Objective-C formatter: POSIX locale and no explicit time zone, so
    /// parsing honors the offset carried by the string and serializing uses the device's
    /// current offset.
    fileprivate static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

    let id: String

    let name: String

    let code: String

    let currentTime: Date?

    let utcOffset: Int

    let dstOffset: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case code
        case currentTime
        case utcOffset
        case dstOffset
    }

    init(id: String, name: String, code: String, currentTime: Date?, utcOffset: Int, dstOffset: Int) {
        self.id = id
        self.name = name
        self.code = code
        self.currentTime = currentTime
        self.utcOffset = utcOffset
        self.dstOffset = dstOffset
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(LossyValue<String>.self, forKey: .id)?.value ?? ""
        name = try container.decodeIfPresent(LossyValue<String>.self, forKey: .name)?.value ?? ""
        code = try container.decodeIfPresent(LossyValue<String>.self, forKey: .code)?.value ?? ""

        let currentTimeString = try container.decodeIfPresent(LossyValue<String>.self, forKey: .currentTime)?.value
        currentTime = currentTimeString.flatMap { RadarTimeZoneSwift.dateFormatter.date(from: $0) }

        utcOffset = try container.decodeIfPresent(LossyInt.self, forKey: .utcOffset)?.value ?? 0
        dstOffset = try container.decodeIfPresent(LossyInt.self, forKey: .dstOffset)?.value ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(code, forKey: .code)
        if let currentTime {
            try container.encode(RadarTimeZoneSwift.dateFormatter.string(from: currentTime), forKey: .currentTime)
        }
        try container.encode(utcOffset, forKey: .utcOffset)
        try container.encode(dstOffset, forKey: .dstOffset)
    }
}

@objc(RadarTimeZone)
@objcMembers
final class RadarTimeZone: NSObject {
    @objc(_id) let id: String?
    let name: String?
    let code: String?
    let currentTime: Date?
    let utcOffset: Int32
    let dstOffset: Int32

    override init() {
        id = nil
        name = nil
        code = nil
        currentTime = nil
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

        id = dictionary["id"] as? String
        name = dictionary["name"] as? String
        code = dictionary["code"] as? String
        if let currentTimeString = dictionary["currentTime"] as? String {
            currentTime = RadarTimeZoneSwift.dateFormatter.date(from: currentTimeString)
        } else {
            currentTime = nil
        }
        utcOffset = (dictionary["utcOffset"] as? NSNumber)?.int32Value ?? 0
        dstOffset = (dictionary["dstOffset"] as? NSNumber)?.int32Value ?? 0
        super.init()
    }

    func dictionaryValue() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        if let id {
            dictionary["id"] = id
        }
        if let name {
            dictionary["name"] = name
        }
        if let code {
            dictionary["code"] = code
        }
        if let currentTime {
            dictionary["currentTime"] = RadarTimeZoneSwift.dateFormatter.string(from: currentTime)
        }
        dictionary["utcOffset"] = NSNumber(value: utcOffset)
        dictionary["dstOffset"] = NSNumber(value: dstOffset)
        return dictionary
    }
}

/// Decodes to `nil` instead of throwing when a value is present but of the wrong type.
private struct LossyValue<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? decoder.singleValueContainer().decode(Value.self)
    }
}

/// Decodes an integer the way `NSNumber.intValue` did: a fractional number truncates toward
/// zero, and anything that is not a number decodes to `nil`.
private struct LossyInt: Decodable {
    let value: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = Int(exactly: double.rounded(.towardZero))
        } else {
            value = nil
        }
    }
}
