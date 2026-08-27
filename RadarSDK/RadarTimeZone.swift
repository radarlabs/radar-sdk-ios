//
//  RadarTimeZone.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Represents a time zone.
///
/// See https://radar.com/documentation/api#geocoding
struct RadarTimeZoneSwift: Codable, Sendable, Equatable {
    /// Parses and serializes `currentTime`.
    ///
    /// Mirrors the legacy Objective-C formatter: POSIX locale and no explicit time zone, so
    /// parsing honors the offset carried by the string and serializing uses the device's
    /// current offset.
    nonisolated(unsafe) private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

    /// The ID of the time zone.
    let id: String

    /// The name of the time zone.
    let name: String

    /// The time zone abbreviation.
    let code: String

    /// The current time for the time zone.
    let currentTime: Date?

    /// The UTC offset for the time zone.
    let utcOffset: Int

    /// The DST offset for the time zone.
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

    /// Decoding is lenient to match the Objective-C parser's `isKindOfClass:` checks: a
    /// missing field, a `null`, an unparseable date, or a value of the wrong type falls back
    /// to the default instead of failing the whole payload.
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
