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
    var m: [String: RadarMetadataValue] = [
        "radar:notificationText": .string("Hello"),
        "radar:campaignId": .string("campaign_1"),
    ]
    for (k, v) in extras { m[k] = v }
    return m
}

private let formatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    return f
}()

private func isoString(_ date: Date) -> String {
    formatter.string(from: date)
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
        let geofence = makeGeofence(metadata: baseMetadata(extras: [
            "radar:startsAt": .string(isoString(future))
        ]))
        #expect(geofence.toNotificationRequest(now: now) == nil)
    }

    @Test func afterStartsAt_returnsRequest() {
        let past = now.addingTimeInterval(-3600)
        let geofence = makeGeofence(metadata: baseMetadata(extras: [
            "radar:startsAt": .string(isoString(past))
        ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func afterEndsAt_returnsNil() {
        let past = now.addingTimeInterval(-3600)
        let geofence = makeGeofence(metadata: baseMetadata(extras: [
            "radar:endsAt": .string(isoString(past))
        ]))
        #expect(geofence.toNotificationRequest(now: now) == nil)
    }

    @Test func beforeEndsAt_returnsRequest() {
        let future = now.addingTimeInterval(3600)
        let geofence = makeGeofence(metadata: baseMetadata(extras: [
            "radar:endsAt": .string(isoString(future))
        ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func withinWindow_returnsRequest() {
        let past = now.addingTimeInterval(-3600)
        let future = now.addingTimeInterval(3600)
        let geofence = makeGeofence(metadata: baseMetadata(extras: [
            "radar:startsAt": .string(isoString(past)),
            "radar:endsAt": .string(isoString(future)),
        ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func atEndsAt_boundary_returnsNil() {
        // Use a date with zero sub-second component to avoid ms rounding in the formatter
        let secNow = Date(timeIntervalSince1970: floor(now.timeIntervalSince1970))
        let geofence = makeGeofence(metadata: baseMetadata(extras: [
            "radar:endsAt": .string(isoString(secNow))
        ]))
        #expect(geofence.toNotificationRequest(now: secNow) == nil)
    }

    @Test func unparseableStartsAt_returnsRequest() {
        let geofence = makeGeofence(metadata: baseMetadata(extras: [
            "radar:startsAt": .string("not-a-date")
        ]))
        #expect(geofence.toNotificationRequest(now: now) != nil)
    }

    @Test func unparseableEndsAt_returnsRequest() {
        let geofence = makeGeofence(metadata: baseMetadata(extras: [
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
}
