//
//  RadarOperatingHours.swift
//  RadarSDK
//
//  Created by Alan Charles on 6/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

enum RadarOperatingHoursEvaluator {
    // Fixed English abbreviations matching the server-supplied `operatingHours` keys and
    // `radar:daysOfWeek` values; intentionally NOT localized — a locale-formatted weekday
    // (e.g. "dim.") would stop matching the backend's English keys.
    private static let daysOfWeekAbbr = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    static func isOpen(
        operatingHours: [String: [[String]]]?,
        now: Date = Date(),
        timeZone: TimeZone = .current,
        closeBufferMinutes: Int = 0
    ) -> Bool {
        guard let operatingHours else {
            return true
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let weekdayIndex = calendar.component(.weekday, from: now) - 1
        guard weekdayIndex >= 0, weekdayIndex < daysOfWeekAbbr.count,
            let dailyHours = operatingHours[daysOfWeekAbbr[weekdayIndex]]
        else {
            return true
        }

        let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        return dailyHours.contains { window in
            guard window.count == 2,
                let open = minutesSinceMidnight(window[0]),
                let close = minutesSinceMidnight(window[1])
            else {
                return false
            }

            let effectiveClose = close - closeBufferMinutes
            return nowMinutes > open && nowMinutes < effectiveClose
        }
    }

    /// Returns the day-of-week abbreviation ("Sun"…"Sat") for `date` evaluated in `timeZone`,
    /// matching the keys used by `isOpen` and the `radar:daysOfWeek` campaign metadata.
    static func weekdayAbbreviation(for date: Date, timeZone: TimeZone = .current) -> String? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        guard weekdayIndex >= 0, weekdayIndex < daysOfWeekAbbr.count else {
            return nil
        }
        return daysOfWeekAbbr[weekdayIndex]
    }

    private static func minutesSinceMidnight(_ timeString: String) -> Int? {
        if timeString == "24:00" {
            return 24 * 60
        }

        let parts = timeString.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
            return nil
        }

        return hour * 60 + minute
    }
}
