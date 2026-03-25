//
//  RadarNotificationHelperTest.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
import UserNotifications
@testable import RadarSDK

// MARK: - Test Helpers

private func makeGeofenceDict(id: String, campaignId: String = "campaign_1") -> [String: Sendable] {
    return [
        "_id": id,
        "description": "Test Geofence \(id)" as String,
        "tag": "test" as String,
        "externalId": "ext_\(id)" as String,
        "metadata": [
            "radar:notificationText": "Hello from \(id)",
            "radar:campaignId": campaignId,
        ] as [String: String],
        "geometryCenter": [
            "coordinates": [-74.0, 40.0]
        ] as [String: Sendable],
        "geometryRadius": 100.0 as Double,
    ] as [String: Sendable]
}

/// Remove all radar-prefixed pending notifications and clear registered state.
private func cleanup() async {
    let notificationCenter = UNUserNotificationCenter.current()
    let pending = await notificationCenter.pendingNotificationRequests()
    let radarIds = pending.filter { $0.identifier.hasPrefix("radar_") }.map(\.identifier)
    if !radarIds.isEmpty {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: radarIds)
    }
    RadarState.registeredNotifications = nil
}

/// Returns the identifiers of all radar-prefixed pending notification requests.
private func pendingRadarIds() async -> Set<String> {
    let notificationCenter = UNUserNotificationCenter.current()
    let pending = await notificationCenter.pendingNotificationRequests()
    return Set(pending.filter { $0.identifier.hasPrefix("radar_") }.map(\.identifier))
}

private func isAuthorized() async -> Bool {
    let notificationCenter = UNUserNotificationCenter.current()
    let settings = await notificationCenter.notificationSettings()
    return settings.authorizationStatus == .authorized
}

// MARK: - Tests

@Suite(.serialized)
struct RadarNotificationHelperTest {

    // MARK: - Basic Registration

    @Test("Register geofences sets pending requests and RadarState")
    func registerSetsState() async throws {
        await cleanup()
        try #require(await isAuthorized(), "Notification authorization required")

        let helper = RadarNotificationHelper()
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
        ])

        let ids = await pendingRadarIds()
        #expect(ids == Set(["radar_geofence_1", "radar_geofence_2"]))

        let registered = RadarState.registeredNotifications
        #expect(registered?.count == 2)
        #expect(Set(registered?.map(\.identifier) ?? []) == Set(["radar_geofence_1", "radar_geofence_2"]))
    }

    @Test("After register with no triggers, getDelivered returns empty")
    func noTriggersReturnsEmpty() async throws {
        await cleanup()
        try #require(await isAuthorized(), "Notification authorization required")

        let helper = RadarNotificationHelper()
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
        ])

        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty)
    }

    // MARK: - Triggered Notifications

    @Test("Removing a pending notification makes it appear as delivered")
    func triggeredNotificationAppearsAsDelivered() async throws {
        let notificationCenter = UNUserNotificationCenter.current()
        await cleanup()
        try #require(await isAuthorized(), "Notification authorization required")

        let helper = RadarNotificationHelper()
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
            makeGeofenceDict(id: "3"),
        ])

        // Simulate notification "2" being triggered by the OS
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["radar_geofence_2"])

        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.count == 1)

        let deliveredIds = delivered.compactMap { $0["identifier"] as? String }
        #expect(deliveredIds == ["radar_geofence_2"])
    }

    @Test("Removing all pending notifications returns all as delivered")
    func allTriggeredReturnsAll() async throws {
        let notificationCenter = UNUserNotificationCenter.current()
        await cleanup()
        try #require(await isAuthorized(), "Notification authorization required")

        let helper = RadarNotificationHelper()
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
        ])

        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["radar_geofence_1", "radar_geofence_2"])

        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.count == 2)

        let deliveredIds = Set(delivered.compactMap { $0["identifier"] as? String })
        #expect(deliveredIds == Set(["radar_geofence_1", "radar_geofence_2"]))
    }

    // MARK: - Authorization

    @Test("getDelivered returns empty when notifications are not authorized")
    func getDeliveredNotAuthorizedReturnsEmpty() async {
        await cleanup()
        // This test is only meaningful when NOT authorized.
        // When authorized, skip it since we can't revoke authorization in tests.
        guard !(await isAuthorized()) else { return }

        let helper = RadarNotificationHelper()
        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty)
    }

    // MARK: - Multiple Registrations

    @Test("Second registration replaces first set of notifications")
    func sequentialRegistrationsReplacesNotifications() async throws {
        await cleanup()
        try #require(await isAuthorized(), "Notification authorization required")

        let helper = RadarNotificationHelper()
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
        ])

        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "3"),
        ])

        let ids = await pendingRadarIds()
        #expect(ids == Set(["radar_geofence_3"]))

        let registered = RadarState.registeredNotifications
        #expect(registered?.count == 1)
        #expect(registered?.first?.identifier == "radar_geofence_3")

        // No false deliveries
        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty)
    }

    @Test("Concurrent registrations produce consistent state with no false deliveries")
    func concurrentRegistrationsConsistentState() async throws {
        await cleanup()
        try #require(await isAuthorized(), "Notification authorization required")

        let helper = RadarNotificationHelper()

        let t1 = Task {
            await helper.registerGeofenceNotifications(geofences: [
                makeGeofenceDict(id: "1"),
                makeGeofenceDict(id: "2"),
            ])
        }
        let t2 = Task {
            await helper.registerGeofenceNotifications(geofences: [
                makeGeofenceDict(id: "3"),
            ])
        }

        await t1.value
        await t2.value

        // After both complete, registered state must match pending state
        let pendingIds = await pendingRadarIds()
        let registeredIds = Set(RadarState.registeredNotifications?.map(\.identifier) ?? [])
        #expect(pendingIds == registeredIds,
                "Pending and registered state must be consistent after concurrent registrations")

        // No false deliveries
        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty, "No false deliveries after concurrent registrations")
    }

    // MARK: - Rapid concurrent access

    @Test("Many rapid registrations never produce false deliveries")
    func rapidRegistrationsNoFalseDeliveries() async throws {
        await cleanup()
        try #require(await isAuthorized(), "Notification authorization required")

        let helper = RadarNotificationHelper()

        var tasks: [Task<Void, Never>] = []
        for i in 0..<10 {
            tasks.append(Task {
                await helper.registerGeofenceNotifications(geofences: [
                    makeGeofenceDict(id: "\(i)"),
                ])
            })
        }

        for task in tasks {
            await task.value
        }

        // Final state must be consistent
        let pendingIds = await pendingRadarIds()
        let registeredIds = Set(RadarState.registeredNotifications?.map(\.identifier) ?? [])
        #expect(pendingIds == registeredIds, "State must be consistent after rapid registrations")

        // No false deliveries
        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty, "No false deliveries after rapid registrations")
    }

    @Test("Concurrent getDelivered and register never returns false deliveries")
    func concurrentGetDeliveredAndRegisterNoFalseDeliveries() async throws {
        await cleanup()
        try #require(await isAuthorized(), "Notification authorization required")

        let helper = RadarNotificationHelper()

        // Register initial set
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
        ])

        // Fire a new registration and getDelivered concurrently
        let registerTask = Task {
            await helper.registerGeofenceNotifications(geofences: [
                makeGeofenceDict(id: "2"),
            ])
        }
        let deliveredTask = Task {
            await helper.getDeliveredNotifications()
        }

        let delivered = await deliveredTask.value
        await registerTask.value

        // Must NEVER report any notification as falsely delivered — that would mean
        // the registration's remove-then-add sequence leaked into the diff.
        let deliveredIds = Set(delivered.compactMap { $0["identifier"] as? String })
        #expect(!deliveredIds.contains("radar_geofence_1"),
                "Old notification must not appear as falsely delivered during re-registration")
        #expect(!deliveredIds.contains("radar_geofence_2"),
                "New notification must not appear as falsely delivered")
    }

    @Test("Interleaved register and getDelivered calls maintain consistency")
    func interleavedRegisterAndGetDelivered() async throws {
        let notificationCenter = UNUserNotificationCenter.current()
        await cleanup()
        try #require(await isAuthorized(), "Notification authorization required")

        let helper = RadarNotificationHelper()

        // Round 1: register, trigger, verify
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "a"),
            makeGeofenceDict(id: "b"),
        ])
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["radar_geofence_a"])

        let delivered1 = await helper.getDeliveredNotifications()
        let delivered1Ids = Set(delivered1.compactMap { $0["identifier"] as? String })
        #expect(delivered1Ids == Set(["radar_geofence_a"]))

        // Round 2: re-register (replaces everything), no triggers
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "c"),
            makeGeofenceDict(id: "d"),
        ])

        let delivered2 = await helper.getDeliveredNotifications()
        #expect(delivered2.isEmpty, "No triggers in round 2, should be empty")

        // Round 3: trigger one of the new ones
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["radar_geofence_d"])

        let delivered3 = await helper.getDeliveredNotifications()
        let delivered3Ids = Set(delivered3.compactMap { $0["identifier"] as? String })
        #expect(delivered3Ids == Set(["radar_geofence_d"]))

        // Old notifications from round 1 must not leak through
        #expect(!delivered3Ids.contains("radar_geofence_a"))
        #expect(!delivered3Ids.contains("radar_geofence_b"))
    }
}
