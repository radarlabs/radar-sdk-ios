//
//  RadarOperatingHoursEvaluatorTest.swift
//  RadarSDK
//
//  Created by Alan Charles on 6/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite
struct RadarOperatingHoursEvaluatorTest {
    private let timezone = TimeZone(identifier: "America/New_York")!
    private let utc = TimeZone(identifier: "UTC")!
    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    private func date(_ timezone: TimeZone, hour: Int, minute: Int = 0) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone
        return cal.date(from: DateComponents(year: 2026, month: 6, day: 5, hour: hour, minute: minute))!
    }

    private func dayKey(for date: Date, timezone: TimeZone) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone
        let idx = cal.component(.weekday, from: date) - 1
        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][idx]
    }

    @Test("nil operating hours is treated as open")
    func nilHoursOpen() {
        #expect(RadarOperatingHoursEvaluator.isOpen(operatingHours: nil, now: date(timezone, hour: 3), timeZone: timezone))
    }

    @Test("a day with no entry is treated as open")
    func dayNotPresentOpen() {
        let now = date(timezone, hour: 12)
        let otherDay = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].first { $0 != dayKey(for: now, timezone: timezone) }!
        #expect(RadarOperatingHoursEvaluator.isOpen(operatingHours: [otherDay: [["09:00", "17:00"]]], now: now, timeZone: timezone))
    }

    @Test("within the window is open")
    func withinWindowOpen() {
        let now = date(timezone, hour: 12)
        let hours = [dayKey(for: now, timezone: timezone): [["9:00", "17:00"]]]
        #expect(RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: now, timeZone: timezone))
    }

    @Test("before opening is closed")
    func beforeOpenClosed() {
        let now = date(timezone, hour: 8)
        let hours = [dayKey(for: now, timezone: timezone): [["9:00", "17:00"]]]
        #expect(!RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: now, timeZone: timezone))
    }

    @Test("after closing is closed")
    func afterCloseClosed() {
        let now = date(timezone, hour: 18)
        let hours = [dayKey(for: now, timezone: timezone): [["9:00", "17:00"]]]
        #expect(!RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: now, timeZone: timezone))
    }

    @Test("close buffer pulls the effective close time earlier")
    func closeBufferClosesEarly() {
        let now = date(timezone, hour: 16, minute: 45)
        let hours = [dayKey(for: now, timezone: timezone): [["9:00", "17:00"]]]
        #expect(RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: now, timeZone: timezone))
        #expect(!RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: now, timeZone: timezone, closeBufferMinutes: 30))
    }

    @Test("24:00 is treated as end of day")
    func midnightCloseOpen() {
        let now = date(timezone, hour: 23, minute: 59)
        let hours = [dayKey(for: now, timezone: timezone): [["0:00", "24:00"]]]
        #expect(RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: now, timeZone: timezone))
    }

    @Test("multiple windows: open inside one, closed in the gap")
    func multipleWindows() {
        let key = dayKey(for: date(timezone, hour: 12), timezone: timezone)
        let hours = [key: [["09:00", "12:00"], ["13:00", "17:00"]]]
        #expect(RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: date(timezone, hour: 10), timeZone: timezone))
        #expect(!RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: date(timezone, hour: 12, minute: 30), timeZone: timezone))
        #expect(RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: date(timezone, hour: 14), timeZone: timezone))
    }

    @Test("weekday abbreviation is evaluated in the supplied timezone")
    func weekdayAbbreviationRespectsTimezone() {
        // 02:00 UTC on 2026-06-05 is the previous calendar day (and weekday) in Los Angeles (19:00).
        let instant = date(utc, hour: 2)
        #expect(RadarOperatingHoursEvaluator.weekdayAbbreviation(for: instant, timeZone: utc) == dayKey(for: instant, timezone: utc))
        #expect(RadarOperatingHoursEvaluator.weekdayAbbreviation(for: instant, timeZone: losAngeles) == dayKey(for: instant, timezone: losAngeles))
        #expect(dayKey(for: instant, timezone: utc) != dayKey(for: instant, timezone: losAngeles))
    }

    @Test("the same instant is evaluated in the supplied timezone")
    func respectsTimezone() {
        // 21:00 UTC on 2026-06-05 == 14:00 PDT the same calendar day.
        let instant = date(utc, hour: 21)
        let hours = [dayKey(for: instant, timezone: utc): [["09:00", "17:00"]]]

        #expect(!RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: instant, timeZone: utc))  // 21:00 UTC -> closed
        #expect(RadarOperatingHoursEvaluator.isOpen(operatingHours: hours, now: instant, timeZone: losAngeles))  // 14:00 PDT -> open
    }
}
