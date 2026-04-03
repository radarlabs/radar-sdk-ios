//
//  RadarNotificationHelper.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import UserNotifications
import CoreLocation

@available(iOS 13.0, *)
protocol NotificationCenterProtocol {
    nonisolated(nonsending) func add(_ request: UNNotificationRequest) async throws
    nonisolated(nonsending) func pendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    
    nonisolated(nonsending) func radarNotificationPermissions() async -> NotificationPermissions
}

extension UNUserNotificationCenter: NotificationCenterProtocol {
    @available(iOS 13.0, *)
    nonisolated(nonsending) func radarNotificationPermissions() async -> NotificationPermissions {
        let settings = await notificationSettings()
        let permissions = NotificationPermissions(from: settings)
        return permissions
    }
    
}

@available(iOS 13.0, *)
@objc(RadarNotificationHelper_Swift) @objcMembers
actor RadarNotificationHelper: NSObject {

    private var currentTask: Task<Void, Never>? = nil
    private var isRegistering: Bool = false

    public static let shared = RadarNotificationHelper()
    
    private let notificationCenter: NotificationCenterProtocol
    private let radarState: RadarState
    
    init(notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current(), radarState: RadarState = RadarState()) {
        self.notificationCenter = notificationCenter
        self.radarState = radarState
    }

    public func registerGeofenceNotifications(geofences: [[String: Sendable]]) async {
        let now = Date()
        let notifications: [UNNotificationRequest] = geofences.compactMap { (geofenceDict) -> UNNotificationRequest? in
            if let json = try? JSONSerialization.data(withJSONObject: geofenceDict),
               let geofence = try? JSONDecoder().decode(RadarGeofence_Swift.self, from: json),
               let notification = geofence.toNotificationRequest(now: now) {
                return notification
            }
            return nil
        }
        
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
        if (!permissions.canSendNotification()) {
            if let data = try? JSONEncoder().encode(permissions),
               let string = String(data: data, encoding: .utf8) {
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
           let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Sendable]] {
            return json
        }
        return []
    }
    
    public func notificationPermission() async -> String {
        let permissions = await notificationCenter.radarNotificationPermissions()
        guard let data = try? JSONEncoder().encode(permissions) else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

