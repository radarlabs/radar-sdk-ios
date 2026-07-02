//
//  RadarNotificationHelperRefreshTest.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

private let schedulingWindowFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    return fmt
}()

private func isoString(_ date: Date) -> String {
    schedulingWindowFormatter.string(from: date)
}

extension RadarNotificationHelperTest {

    @Test("refresh re-registers from the persisted store")
    func refreshReRegistersFromStore() async {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let fileName = "refresh_\(UUID().uuidString).json"
        let store = RadarFileStorageObject<[RadarGeofenceSwift]>(fileName: fileName)
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState, geofenceStore: store)

        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1"),
            makeGeofenceDict(id: "2"),
        ])

        // Simulate the pending list being lost (e.g. relaunch) so we can prove refresh rebuilds it.
        mockCenter.pendingRequests.removeAll()

        let helperAfterRelaunch = RadarNotificationHelper(
            notificationCenter: mockCenter,
            radarState: mockState,
            geofenceStore: RadarFileStorageObject<[RadarGeofenceSwift]>(fileName: fileName)
        )
        await helperAfterRelaunch.refreshGeofenceNotifications()

        let pending = await mockCenter.pendingNotificationRequests()
        #expect(Set(pending.map(\.identifier)) == Set(["radar_geofence_1", "radar_geofence_2"]))

        store.clear()
    }

    @Test("refresh with an empty store is a no-op")
    func refreshEmptyStoreNoOp() async {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let store = RadarFileStorageObject<[RadarGeofenceSwift]>(fileName: "refresh_empty_\(UUID().uuidString).json")
        store.clear()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState, geofenceStore: store)

        await helper.refreshGeofenceNotifications()

        let pending = await mockCenter.pendingNotificationRequests()
        #expect(pending.isEmpty)
    }

    @Test("refresh deregisters a campaign whose scheduling window has ended")
    func refreshDeregistersEndedWindow() async {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let fileName = "refresh_window_\(UUID().uuidString).json"
        let store = RadarFileStorageObject<[RadarGeofenceSwift]>(fileName: fileName)
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState, geofenceStore: store)

        // Registered while within the window (endsAt in the future): both are pending.
        await helper.registerGeofenceNotifications(geofences: [
            makeGeofenceDict(id: "1", endsAt: isoString(Date().addingTimeInterval(3600))),
            makeGeofenceDict(id: "2"),
        ])
        var pending = await mockCenter.pendingNotificationRequests()
        #expect(Set(pending.map(\.identifier)) == Set(["radar_geofence_1", "radar_geofence_2"]))

        // The window for geofence "1" has since ended (endsAt now in the past). A refresh push
        // re-evaluates the cache and must prune it, leaving the windowless geofence registered.
        store.write([
            decodeGeofence(makeGeofenceDict(id: "1", endsAt: isoString(Date().addingTimeInterval(-3600))))!,
            decodeGeofence(makeGeofenceDict(id: "2"))!,
        ])
        await helper.refreshGeofenceNotifications()

        pending = await mockCenter.pendingNotificationRequests()
        #expect(Set(pending.map(\.identifier)) == Set(["radar_geofence_2"]))

        store.clear()
    }

    @Test("refresh keeps a campaign still within its scheduling window")
    func refreshKeepsActiveWindow() async {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let store = RadarFileStorageObject<[RadarGeofenceSwift]>(fileName: "refresh_active_\(UUID().uuidString).json")
        store.write([
            decodeGeofence(
                makeGeofenceDict(
                    id: "1",
                    startsAt: isoString(Date().addingTimeInterval(-3600)),
                    endsAt: isoString(Date().addingTimeInterval(3600))
                )
            )!
        ])
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState, geofenceStore: store)

        await helper.refreshGeofenceNotifications()

        let pending = await mockCenter.pendingNotificationRequests()
        #expect(Set(pending.map(\.identifier)) == Set(["radar_geofence_1"]))

        store.clear()
    }

    @Test("Re-registering identical geofences leaves unchanged notifications armed")
    func reRegisteringSameGeofencesPreservesPendingRequests() async throws {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState)

        let geofences = [makeGeofenceDict(id: "1"), makeGeofenceDict(id: "2")]
        await helper.registerGeofenceNotifications(geofences: geofences)

        let afterFirst = mockCenter.pendingRequests
        #expect(afterFirst.count == 2)
        let addCountAfterFirst = mockCenter.addCallCount

        await helper.registerGeofenceNotifications(geofences: geofences)

        let afterSecond = mockCenter.pendingRequests
        #expect(afterSecond.count == 2)
        #expect(mockCenter.addCallCount == addCountAfterFirst, "Unchanged notifications should not be re-added")
        for request in afterFirst {
            #expect(
                afterSecond.contains { $0 === request },
                "Unchanged notification \(request.identifier) should remain the same pending request instance"
            )
        }

        let delivered = await helper.getDeliveredNotifications()
        #expect(delivered.isEmpty, "Re-registering identical geofences must not look like a delivery")
    }

    @Test("Re-registering a changed geofence rebuilds that notification")
    func reRegisteringChangedGeofenceReplaces() async throws {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState)

        await helper.registerGeofenceNotifications(geofences: [makeGeofenceDict(id: "1", radius: 100.0)])
        let first = try #require(mockCenter.pendingRequests.first)

        // Same id but a different region — the trigger changed, so it must be rebuilt.
        await helper.registerGeofenceNotifications(geofences: [makeGeofenceDict(id: "1", radius: 250.0)])

        let pending = await mockCenter.pendingNotificationRequests()
        #expect(pending.count == 1)
        #expect(pending.first?.identifier == "radar_geofence_1")
        #expect(pending.first !== first, "A changed geofence notification should be rebuilt, not left in place")
    }

    @Test("Re-registering with changed campaign metadata rebuilds that notification")
    func reRegisteringChangedMetadataReplaces() async throws {
        let mockCenter = MockNotificationCenter()
        let mockState = MockRadarState()
        let helper = RadarNotificationHelper(notificationCenter: mockCenter, radarState: mockState)

        await helper.registerGeofenceNotifications(geofences: [makeGeofenceDict(id: "1", campaignId: "campaign_1")])
        let first = try #require(mockCenter.pendingRequests.first)

        // Same id, content, and region — only the campaign metadata carried in userInfo changed,
        // so the notification must be re-registered with the new metadata.
        await helper.registerGeofenceNotifications(geofences: [makeGeofenceDict(id: "1", campaignId: "campaign_2")])

        let pending = await mockCenter.pendingNotificationRequests()
        #expect(pending.count == 1)
        #expect(pending.first?.identifier == "radar_geofence_1")
        #expect(pending.first !== first, "Changed campaign metadata should rebuild the notification")
        #expect(pending.first?.content.userInfo["campaignId"] as? String == "campaign_2")
    }
}
