//
//  RadarNotificationTest.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
import UserNotifications

@testable import RadarSDK

// MARK: - Helpers

private func makeGeofence(metadata: [String: RadarMetadataValue]?) -> RadarGeofenceSwift {
    RadarGeofenceSwift(
        id: "geofence_1",
        description: "Test",
        tag: "test",
        externalId: "ext_1",
        geometry: .circle(
            center: RadarCoordinateSwift(latitude: 40.0, longitude: -74.0),
            radius: 100
        ),
        dwellThreshold: nil,
        geofenceStopDetection: nil,
        metadata: metadata
    )
}

private func baseMetadata(extras: [String: RadarMetadataValue] = [:]) -> [String: RadarMetadataValue] {
    var meta: [String: RadarMetadataValue] = [
        "radar:notificationText": .string("Hello"),
        "radar:campaignId": .string("campaign_1"),
    ]
    for (key, value) in extras { meta[key] = value }
    return meta
}

private let formatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    return fmt
}()

private func isoString(_ date: Date) -> String {
    formatter.string(from: date)
}

private let allDaysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

private func weekdayAbbreviation(for date: Date) -> String {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .current
    return allDaysOfWeek[cal.component(.weekday, from: date) - 1]
}

// MARK: - Tests

@Suite()
struct RadarNotificationTest {
    let now = Date()

    @Test func noWindowKeys_returnsRequest() {
        let geofence = makeGeofence(metadata: baseMetadata())
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func beforeStartsAt_returnsNil() {
        let future = now.addingTimeInterval(3600)
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:startsAt": .string(isoString(future))
            ]))
        #expect(geofence.toNotificationRequest(now: now) == nil)
    }

    @Test func afterStartsAt_returnsRequest() {
        let past = now.addingTimeInterval(-3600)
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:startsAt": .string(isoString(past))
            ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func afterEndsAt_returnsNil() {
        let past = now.addingTimeInterval(-3600)
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:endsAt": .string(isoString(past))
            ]))
        #expect(geofence.toNotificationRequest(now: now) == nil)
    }

    @Test func beforeEndsAt_returnsRequest() {
        let future = now.addingTimeInterval(3600)
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:endsAt": .string(isoString(future))
            ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func withinWindow_returnsRequest() {
        let past = now.addingTimeInterval(-3600)
        let future = now.addingTimeInterval(3600)
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:startsAt": .string(isoString(past)),
                "radar:endsAt": .string(isoString(future)),
            ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func atEndsAt_boundary_returnsRequest() {
        // endsAt is inclusive: at exactly endsAt the notification should still fire
        let secNow = Date(timeIntervalSince1970: floor(now.timeIntervalSince1970))
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:endsAt": .string(isoString(secNow))
            ]))
        #expect(geofence.toNotificationRequest(now: secNow) != nil)
    }

    @Test func afterEndsAt_boundary_returnsNil() {
        // endsAt is inclusive: one second past endsAt the notification should not fire
        let secNow = Date(timeIntervalSince1970: floor(now.timeIntervalSince1970))
        let oneSecondAfter = Date(timeIntervalSince1970: secNow.timeIntervalSince1970 + 1)
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:endsAt": .string(isoString(secNow))
            ]))
        #expect(geofence.toNotificationRequest(now: oneSecondAfter) == nil)
    }

    @Test func unparseableStartsAt_returnsRequest() {
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:startsAt": .string("not-a-date")
            ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func unparseableEndsAt_returnsRequest() {
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:endsAt": .string("not-a-date")
            ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func noNotificationText_returnsNil() {
        let geofence = makeGeofence(metadata: [
            "radar:startsAt": .string(isoString(now.addingTimeInterval(-1)))
        ])
        #expect(geofence.toNotificationRequest(now: now) == nil)
    }

    // MARK: - Day of week

    @Test func dayOfWeekIncludesToday_returnsRequest() {
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:daysOfWeek": .string(weekdayAbbreviation(for: now))
            ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func dayOfWeekExcludesToday_returnsNil() {
        let otherDay = allDaysOfWeek.first { $0 != weekdayAbbreviation(for: now) }!
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:daysOfWeek": .string(otherDay)
            ]))
        #expect(geofence.toNotificationRequest(now: now) == nil)
    }

    @Test func dayOfWeekListIncludesToday_returnsRequest() {
        let today = weekdayAbbreviation(for: now)
        let otherDay = allDaysOfWeek.first { $0 != today }!
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:daysOfWeek": .string("\(otherDay),\(today)")
            ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func dayOfWeekListExcludesToday_returnsNil() {
        let others = allDaysOfWeek.filter { $0 != weekdayAbbreviation(for: now) }
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:daysOfWeek": .string("\(others[0]),\(others[1])")
            ]))
        #expect(geofence.toNotificationRequest(now: now) == nil)
    }

    @Test func emptyDaysOfWeek_returnsRequest() {
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:daysOfWeek": .string("")
            ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func dayOfWeekCaseInsensitive_returnsRequest() {
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:daysOfWeek": .string(weekdayAbbreviation(for: now).lowercased())
            ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func dayOfWeekWhitespaceAndUnknownTokens_returnsRequest() {
        let geofence = makeGeofence(
            metadata: baseMetadata(extras: [
                "radar:daysOfWeek": .string(" \(weekdayAbbreviation(for: now)) , Xyz ")
            ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }
}
