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

        // Persist the full nearby set (incl. metadata + operatingHours) so a refresh can
        // re-evaluate operating hours and the campaign scheduling window (radar:startsAt/endsAt)
        // later without a track
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
            let requests = await notificationCenter.pendingNotificationRequests()
            if Task.isCancelled {
                return
            }

            // Diff against the currently-pending geofence notifications instead of tearing them all
            // down and re-adding. This runs on every track (replaceSyncedGeofences), which re-builds
            // the same requests; re-adding an unchanged UNLocationNotificationTrigger re-arms it, and
            // iOS will not fire an entry for a trigger scheduled while the device is already inside
            // the region. Leaving unchanged triggers in place preserves their arm point so an
            // in-progress geofence entry still fires.
            let existingGeofenceRequests = requests.filter { $0.identifier.starts(with: GEOFENCE_NOTIFICATION_PREFIX) }
            let existingUniqueIdentifiers = Set(existingGeofenceRequests.map { Self.notificationUniqueIdentifier(for: $0) })
            let desiredUniqueIdentifiers = Set(notifications.map { Self.notificationUniqueIdentifier(for: $0) })

            // Remove pending geofence notifications that are gone or changed (unique identifier no longer desired).
            let notificationIdentifiersToRemove =
                existingGeofenceRequests
                .filter { !desiredUniqueIdentifiers.contains(Self.notificationUniqueIdentifier(for: $0)) }
                .map { $0.identifier }
            if !notificationIdentifiersToRemove.isEmpty {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: notificationIdentifiersToRemove)
            }

            let permissions = await notificationCenter.radarNotificationPermissions()
            if Task.isCancelled {
                return
            }
            if permissions.authorizationStatus != .authorized {
                RadarLogger.debug("NotificationHelper notifications unauthorized")
                return
            }

            // Add only notifications that aren't already pending unchanged, so triggers we left in
            // place keep their arm point.
            for notification in notifications where !existingUniqueIdentifiers.contains(Self.notificationUniqueIdentifier(for: notification)) {
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

    /// A stable identity for a geofence notification used to diff desired vs. already-pending
    /// requests. Covers everything that determines whether re-adding would change behavior —
    /// identifier, content, and the location trigger's region — but deliberately excludes
    /// `userInfo` (its `registeredAt` is stamped fresh on every build, so including it would make
    /// every request look changed and defeat the diff).
    private static func notificationUniqueIdentifier(for request: UNNotificationRequest) -> String {
        let content = request.content
        var parts: [String] = [request.identifier, content.title, content.subtitle, content.body]
        if let trigger = request.trigger as? UNLocationNotificationTrigger,
            let region = trigger.region as? CLCircularRegion
        {
            parts.append(String(format: "%.6f,%.6f,%.2f", region.center.latitude, region.center.longitude, region.radius))
            parts.append(region.notifyOnEntry ? "1" : "0")
            parts.append(region.notifyOnExit ? "1" : "0")
            parts.append(trigger.repeats ? "1" : "0")
        }
        return parts.joined(separator: "|")
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
