//
//  RadarOperatingHours.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

typealias DayRanges = [[String]]
typealias OperatingHours = [String: DayRanges]

struct RadarOperatingHoursSwift: Codable, Sendable, Equatable {
    /// Expected JSON: `{ "mon": [["09:00", "17:00"]] }`.
    let hours: OperatingHours

    init(hours: OperatingHours) {
        self.hours = hours
    }

    init(from decoder: Decoder) throws {
        let days = try decoder.singleValueContainer().decode([String: LossyDay].self)
        hours = days.compactMapValues { $0.ranges }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hours)
    }

    fileprivate static func parse(_ dictionary: NSDictionary) -> OperatingHours {
        var parsedHours: OperatingHours = [:]

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

    /// Expected JSON for one day: `[["09:00", "17:00"], ["18:00", "21:00"]]`.
    ///
    /// Bad days are dropped so one bad value does not lose the whole payload.
    private struct LossyDay: Decodable {
        let ranges: DayRanges?

        init(from decoder: Decoder) throws {
            guard let decoded = try? decoder.singleValueContainer().decode([LossyRange].self) else {
                ranges = nil
                return
            }
            ranges = decoded.compactMap { $0.range }
        }
    }

    /// Expected JSON for one range: `["09:00", "17:00"]`.
    ///
    /// Bad ranges are dropped so good ranges for the day still work.
    private struct LossyRange: Decodable {
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
