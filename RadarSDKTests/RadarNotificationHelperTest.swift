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

extension NotificationPermissions {
    init(authorized: Bool, canSend: Bool = true) {
        self.init(
            alert: authorized && canSend,
            sound: authorized && canSend,
            badge: authorized && canSend,
            lockScreen: authorized && canSend,
            notificationCenter: authorized && canSend,
            authorizationStatus: authorized ? .authorized : .denied,
        )
    }
}

final class MockNotificationCenter: NotificationCenterProtocol, @unchecked Sendable {
    private let lock = NSLock()
    var pendingRequests: [UNNotificationRequest] = []
    var authorized: Bool
    var canSend: Bool

    init(authorized: Bool = true, canSend: Bool = true) {
        self.authorized = authorized
        self.canSend = canSend
    }

    func radarNotificationPermissions() async -> NotificationPermissions {
        try? await Task.sleep(nanoseconds: 10_000_000)
        return NotificationPermissions(authorized: authorized, canSend: canSend)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await Task.sleep(nanoseconds: 10_000_000)
        pendingRequests.append(request)
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        try? await Task.sleep(nanoseconds: 10_000_000)
        return (authorized && canSend) ? pendingRequests : []
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        let idsToRemove = Set(identifiers)
        pendingRequests.removeAll { idsToRemove.contains($0.identifier) }
    }
}

// MARK: - Test Helpers

private func makeGeofenceDict(id: String, campaignId: String = "campaign_1") -> [String: Sendable] {
    return [
        "_id": id,
        "description": "Test Geofence \(id)",
        "tag": "test",
        "externalId": "ext_\(id)",
        "metadata": [
            "radar:notificationText": "Hello from \(id)",
            "radar:campaignId": campaignId,
        ],
        "geometryCenter": [
            "coordinates": [-74.0, 40.0]
        ],
        "geometryRadius": 100.0,
    ]
}

// MARK: - Tests

@Suite()
struct RadarNotificationHelperTest {
    
    @Test("does not attempt to add notifications if unauthorized")
    func doesNotAddNotificationsIfUnauthorized() async {
        let mockCenter = MockNotificationCenter(authorized: false)
        let mockState = MockRadarState()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState)
        
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
            makeGeofenceDict(id: "3"),
        ])
        
        // direct access to pending requests to make sure add is not called
        let pending = mockCenter.pendingRequests
        #expect(pending.isEmpty)

        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty)
    }
    @Test("Registering geofence notifications works correctly")
    func registerGeofenceNotifications() async throws {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState)
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
        ])

        let pending = await mockCenter.pendingNotificationRequests()
        #expect(Set(pending.map(\.identifier)) == Set(["radar_geofence_1", "radar_geofence_2"]))

        let registered = mockState.registeredNotifications
        #expect(registered?.count == 2)
        #expect(Set(registered?.map(\.identifier) ?? []) == Set(["radar_geofence_1", "radar_geofence_2"]))
        
        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty)
    }
    
    @Test("Registering geofence notifications does not remove existing non-radar notifications")
    func registerGeofenceNotificationsWithExisting() async throws {
        let mockCenter = MockNotificationCenter()
        
        let request = UNNotificationRequest(identifier: "app_custom", content: UNMutableNotificationContent(), trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        try await mockCenter.add(request)
        
        let mockState = MockRadarState()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState)
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
        ])

        let pending = await mockCenter.pendingNotificationRequests()
        #expect(Set(pending.map(\.identifier)) == Set(["radar_geofence_1", "radar_geofence_2", "app_custom"]))

        let registered = mockState.registeredNotifications
        #expect(registered?.count == 2)
        #expect(Set(registered?.map(\.identifier) ?? []) == Set(["radar_geofence_1", "radar_geofence_2"]))
        
        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty)
    }
    
    @Test("notifications missing from the pending list are considered delivered")
    func triggeredNotificationAppearsAsDelivered() async throws {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState)

        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
            makeGeofenceDict(id: "3"),
        ])

        // Simulate notification 2 and 3 being triggered by the OS
        mockCenter.removePendingNotificationRequests(withIdentifiers: ["radar_geofence_2", "radar_geofence_3"])

        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.count == 2)

        let deliveredIds = delivered.compactMap { $0["identifier"] as? String }
        #expect(deliveredIds == ["radar_geofence_2", "radar_geofence_3"])
    }
    
    @Test("getDelivered returns empty when notifications are not sendable")
    func getDeliveredNotAuthorizedReturnsEmpty() async {
        let mockCenter = MockNotificationCenter(authorized: true, canSend: false)
        let mockState = MockRadarState()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState)
        
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
            makeGeofenceDict(id: "3"),
        ])
        
        let pending = await mockCenter.pendingNotificationRequests()
        #expect(pending.isEmpty)

        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty)
    }
    
    @Test("Second registration replaces first set of notifications")
    func sequentialRegistrationsReplacesNotifications() async throws {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState)
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
        ])

        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "3"),
        ])

        let pending = await mockCenter.pendingNotificationRequests()
        #expect(Set(pending.map(\.identifier)) == Set(["radar_geofence_3"]))

        let registered = mockState.registeredNotifications
        #expect(registered?.count == 1)
        #expect(registered?.first?.identifier == "radar_geofence_3")

        // No false deliveries
        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty)
    }
    
    @Test("Concurrent registrations never produce false deliveries")
    func rapidRegistrationsNoFalseDeliveries() async throws {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState)

        var registerTasks: [Task<Void, Never>] = []
        var getPendingTasks: [Task<Int, Never>] = []
        for i in 0..<10 {
            registerTasks.append(Task {
                await helper.registerGeofenceNotifications(geofences: [
                    makeGeofenceDict(id: "\(i)"),
                ])
            })
            getPendingTasks.append(Task {
                let delivered = await helper.getDeliveredNotifications()
                return delivered.count
            })
        }

        for task in registerTasks {
            await task.value
        }
        for task in getPendingTasks {
            let result = await task.value
            #expect(result == 0)
        }

        // Final state must be consistent
        let pending = await mockCenter.pendingNotificationRequests()
        #expect(Set(pending.map(\.identifier)) == Set(mockState.registeredNotifications?.map(\.identifier) ?? []), "State must be consistent after rapid registrations")

        // No false deliveries
        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty, "No false deliveries after rapid registrations")
    }
}
