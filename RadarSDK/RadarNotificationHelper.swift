//
//  RadarNotificationHelper.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import UserNotifications

protocol NotificationCenterProtocol {
    nonisolated(nonsending) func add(_ request: UNNotificationRequest) async throws
    nonisolated(nonsending) func pendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])

    nonisolated(nonsending) func radarNotificationPermissions() async -> NotificationPermissions
}

extension UNUserNotificationCenter: NotificationCenterProtocol {
    nonisolated(nonsending) func radarNotificationPermissions() async -> NotificationPermissions {
        let settings = await notificationSettings()
        let permissions = NotificationPermissions(from: settings)
        return permissions
    }

}

@objc(RadarNotificationHelper_Swift) @objcMembers
actor RadarNotificationHelper: NSObject {

    private var currentTask: Task<Void, Never>?
    private var isRegistering: Bool = false
    private let geofenceStore: RadarFileStorageObject<[RadarGeofenceSwift]>

    public static let shared = RadarNotificationHelper()

    private let notificationCenter: NotificationCenterProtocol
    private let radarState: RadarState

    init(
        notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current(),
        radarState: RadarState = RadarState(),
        geofenceStore: RadarFileStorageObject<[RadarGeofenceSwift]> = RadarFileStorageObject(fileName: "radar_notification_geofences.json")
    ) {
        self.notificationCenter = notificationCenter
        self.radarState = radarState
        self.geofenceStore = geofenceStore
    }

    public func registerGeofenceNotifications(geofences: [[String: Sendable]]?) async {
        guard let geofences else {
            return
        }

        let decoded: [RadarGeofenceSwift] = geofences.compactMap { geofenceDict in
            guard let json = try? JSONSerialization.data(withJSONObject: geofenceDict),
                let geofence = try? JSONDecoder().decode(RadarGeofenceSwift.self, from: json)
            else {
                return nil
            }
            return geofence
        }

        // Persist the full nearby set (incl. metadata + operatingHours) so a
        // refresh can re-evaluate operating hours later without a track
        geofenceStore.write(decoded)

        await registerGeofences(decoded)
    }

    public func refreshGeofenceNotifications() async {
        guard let geofences = geofenceStore.read() else {
            return
        }
        await registerGeofences(geofences)
    }

    private func registerGeofences(_ geofences: [RadarGeofenceSwift]) async {
        let now = Date()
        let notifications: [UNNotificationRequest] = geofences.compactMap { $0.toNotificationRequest(now: now) }

        RadarLogger.debug("NotificationHelper registering: \(notifications.map(\.identifier))")

        // cancel previous work
        let previousTask = currentTask
        previousTask?.cancel()

        isRegistering = true
        let task = Task { [notifications] in
            await previousTask?.value
            if Task.isCancelled {
                RadarLogger.debug("NotificationHelper cancelled registeration: \(notifications.map(\.identifier))")
                return
            }
            await registerNotifications(notifications: notifications)
            if Task.isCancelled {
                RadarLogger.debug("NotificationHelper cancelled registeration: \(notifications.map(\.identifier))")
                return
            }
            RadarLogger.debug("NotificationHelper completed: \(notifications.map(\.identifier))")
        }
        currentTask = task
        await task.value
    }

    private func registerNotifications(notifications: [UNNotificationRequest]?) async {
        // if notifications is not null, we update the pending notifications, otherwise we only update the registered notifications list
        if let notifications {
            // remove all geofence notifications
            let requests = await notificationCenter.pendingNotificationRequests()
            if Task.isCancelled {
                return
            }
            let notificationIdentifiersToRemove = requests.compactMap {
                let identifier = $0.identifier
                if identifier.starts(with: GEOFENCE_NOTIFICATION_PREFIX) {
                    return identifier
                }
                return nil
            }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: notificationIdentifiersToRemove)

            let permissions = await notificationCenter.radarNotificationPermissions()
            if Task.isCancelled {
                return
            }
            if permissions.authorizationStatus != .authorized {
                RadarLogger.debug("NotificationHelper notifications unauthorized")
                return
            }

            // add notifications
            for notification in notifications {
                do {
                    try await notificationCenter.add(notification)
                    if Task.isCancelled {
                        return
                    }
                } catch {
                    RadarLogger.warning("NotificationHelper failed to add notification \(error) \(notification)")
                }
            }
        }

        if Task.isCancelled {
            return
        }
        let pending = await notificationCenter.pendingNotificationRequests().compactMap {
            NotificationValue(from: $0)
        }
        radarState.registeredNotifications = pending
        RadarLogger.debug("NotificationHelper registered: \(pending.map(\.identifier))")
        isRegistering = false
    }

    public func getDeliveredNotifications() async -> [[String: Sendable]] {
        let permissions = await notificationCenter.radarNotificationPermissions()
        if !permissions.canSendNotification() {
            if let data = try? JSONEncoder().encode(permissions),
                let string = String(data: data, encoding: .utf8)
            {
                RadarLogger.debug("NotificationHelper no permission to send notification \(string)")
            }
            return []
        }

        let task = currentTask
        // if currently registering, notificationCenter state will be unstable
        if isRegistering {
            RadarLogger.debug("NotificationHelper getDeliveredNotifications called while registering")
            return []
        }

        guard let registered = radarState.registeredNotifications else {
            return []
        }
        let pendingRequests = await notificationCenter.pendingNotificationRequests().compactMap {
            NotificationValue(from: $0)
        }

        // if a new task has begin/ended between start of this function, we can't guarantee when
        // pendingNotificationRequests are retrieved. So return empty list.
        if task != currentTask {
            RadarLogger.debug("NotificationHelper getDeliveredNotifications called while registering")
            return []
        }

        let delivered = Set(registered).subtracting(pendingRequests)
        RadarLogger.debug("NotificationHelper delivered: \(delivered.map(\.identifier))")

        if let data = try? JSONEncoder().encode(Array(delivered)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Sendable]]
        {
            return json
        }
        return []
    }

    public func removeRegisteredNotifications(notifications: [[String: Sendable]]?) async {
        guard let notifications else {
            return
        }
        guard var registered = radarState.registeredNotifications else {
            return
        }
        if isRegistering {
            return
        }
        let idsToRemove = Set(notifications.compactMap { $0["identifier"] as? String })
        if idsToRemove.isEmpty {
            return
        }

        registered.removeAll { notification in
            idsToRemove.contains(notification.identifier)
        }
        radarState.registeredNotifications = registered
    }

    public func notificationPermission() async -> String {
        let permissions = await notificationCenter.radarNotificationPermissions()
        guard let data = try? JSONEncoder().encode(permissions) else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
