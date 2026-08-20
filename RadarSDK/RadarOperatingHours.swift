//
//  RadarOperatingHours.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

struct RadarOperatingHoursSwift: Codable, Sendable, Equatable {
    let hours: [String: [[String]]]

    init(hours: [String: [[String]]]) {
        self.hours = hours
    }

    init(from decoder: Decoder) throws {
        let days = try decoder.singleValueContainer().decode([String: LenientDay].self)
        hours = days.compactMapValues { $0.ranges }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hours)
    }

    fileprivate static func parse(_ dictionary: NSDictionary) -> [String: [[String]]] {
        var parsedHours: [String: [[String]]] = [:]

        for case let (key as String, dayPairs as [Any]) in dictionary {
            let parsedDayPairs = dayPairs.compactMap { pair -> [String]? in
                guard let pair = pair as? [Any], pair.count == 2,
                    let start = pair[0] as? String,
                    let end = pair[1] as? String
                else {
                    return nil
                }
                return [start, end]
            }
            parsedHours[key] = parsedDayPairs
        }

        return parsedHours
    }

    /// One day's ranges. Decoding never throws, so a single malformed day cannot fail the whole
    /// payload; `ranges` is `nil` when the value was not an array, which drops the day.
    private struct LenientDay: Decodable {
        let ranges: [[String]]?

        init(from decoder: Decoder) throws {
            guard let decoded = try? decoder.singleValueContainer().decode([LenientRange].self) else {
                ranges = nil
                return
            }
            ranges = decoded.compactMap { $0.range }
        }
    }

    /// One `[start, end]` range. `range` is `nil` unless the value was an array of exactly two
    /// strings, which drops the range from its day.
    private struct LenientRange: Decodable {
        let range: [String]?

        init(from decoder: Decoder) throws {
            let decoded = try? decoder.singleValueContainer().decode([String].self)
            range = decoded.flatMap { $0.count == 2 ? $0 : nil }
        }
    }
}

@objc(RadarOperatingHours)
final class RadarOperatingHours: NSObject {
    @objc let hours: NSDictionary

    /// This keeps old Objective-C calls working.
    @objc(initWithDictionary:)
    init(dictionary: NSDictionary) {
        hours = RadarOperatingHoursSwift.parse(dictionary) as NSDictionary
        super.init()
    }
}
