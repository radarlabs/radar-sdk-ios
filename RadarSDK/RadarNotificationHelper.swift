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
            let unchangedIdentifiers = Self.unchangedIdentifiers(desired: notifications, pending: existingGeofenceRequests)

            // Remove pending geofence notifications that are gone or changed.
            let notificationIdentifiersToRemove =
                existingGeofenceRequests
                .filter { !unchangedIdentifiers.contains($0.identifier) }
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
            for notification in notifications where !unchangedIdentifiers.contains(notification.identifier) {
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

    /// Identifiers of desired notifications that already have an identical pending request, which
    /// should be left in place so their triggers keep their arm point.
    private static func unchangedIdentifiers(desired: [UNNotificationRequest], pending: [UNNotificationRequest]) -> Set<String> {
        let pendingByIdentifier = Dictionary(
            pending.map { ($0.identifier, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return Set(
            desired
                .filter { request in
                    guard let pending = pendingByIdentifier[request.identifier] else {
                        return false
                    }
                    return isNotificationUnchanged(request, comparedTo: pending)
                }
                .map(\.identifier)
        )
    }

    /// Whether a freshly-built request matches an already-pending one closely enough to leave the
    /// pending one in place (preserving its trigger's arm point).
    static func isNotificationUnchanged(_ desired: UNNotificationRequest, comparedTo pending: UNNotificationRequest) -> Bool {
        guard desired.identifier == pending.identifier,
            desired.content.title == pending.content.title,
            desired.content.subtitle == pending.content.subtitle,
            desired.content.body == pending.content.body
        else {
            return false
        }
        return userInfoMatches(desired.content.userInfo, pending.content.userInfo)
            && triggersMatch(desired.trigger, pending.trigger)
    }

    /// Compares userInfo (which carries the campaign metadata) minus two volatile keys:
    /// `registeredAt` is stamped fresh on every build, and `geofenceData` is a JSONEncoder blob
    /// whose key order is not byte-stable across launches. Every campaign field they carry also
    /// appears as a flat userInfo key, in the content, or in the trigger region.
    private static func userInfoMatches(_ lhs: [AnyHashable: Any], _ rhs: [AnyHashable: Any]) -> Bool {
        let volatileKeys: Set<AnyHashable> = ["registeredAt", "geofenceData"]
        let lhsStable = lhs.filter { !volatileKeys.contains($0.key) }
        let rhsStable = rhs.filter { !volatileKeys.contains($0.key) }
        return NSDictionary(dictionary: lhsStable).isEqual(to: rhsStable)
    }

    private static func triggersMatch(_ lhs: UNNotificationTrigger?, _ rhs: UNNotificationTrigger?) -> Bool {
        if lhs == nil && rhs == nil {
            return true
        }
        // Geofence notifications always use a circular-region location trigger; anything else is
        // conservatively treated as changed so the notification gets re-registered.
        guard let lhs = lhs as? UNLocationNotificationTrigger,
            let rhs = rhs as? UNLocationNotificationTrigger,
            let lhsRegion = lhs.region as? CLCircularRegion,
            let rhsRegion = rhs.region as? CLCircularRegion
        else {
            return false
        }
        return lhs.repeats == rhs.repeats
            && lhsRegion.center.latitude == rhsRegion.center.latitude
            && lhsRegion.center.longitude == rhsRegion.center.longitude
            && lhsRegion.radius == rhsRegion.radius
            && lhsRegion.notifyOnEntry == rhsRegion.notifyOnEntry
            && lhsRegion.notifyOnExit == rhsRegion.notifyOnExit
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
