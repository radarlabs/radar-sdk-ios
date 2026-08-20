//
//  RadarOperatingHours.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Weekly operating hours, keyed by a lowercased weekday abbreviation (`"mon"`, `"tue"`, …)
/// mapping to the `["HH:mm", "HH:mm"]` start/end ranges the location is open that day.
///
/// Decoding mirrors the leniency of the legacy Objective-C `RadarOperatingHours`: a day whose
/// value is not an array is dropped entirely, and a range that is not a two-element array of
/// strings is dropped from its day, leaving the day with its remaining — possibly zero — ranges.
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
