//
//  RadarNotificationHelper.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import UserNotifications
import CoreLocation

let RADAR_NOTIFICATION_PREFIX = "radar_"
let GEOFENCE_NOTIFICATION_PREFIX = "radar_geofence_"

struct RadarNotificationContent: Sendable, Hashable {
    let campaignId: String
    let notificationText: String
    let notificationTitle: String?
    let notificationSubtitle: String?
    let notificationURL: String?
    let campaignMetadata: String?
    
    init?(from metadata: [String: RadarMetadataValue]) {
        // required fields
        guard let notificationText = metadata["radar:notificationText"]?.string(),
              let campaignId = metadata["radar:campaignId"]?.string() else {
            return nil
        }
        self.notificationText = notificationText
        self.campaignId = campaignId
        
        // optional fields
        self.notificationTitle = metadata["radar:notificationTitle"]?.string()
        self.notificationSubtitle = metadata["radar:notificationSubtitle"]?.string()
        self.notificationURL = metadata["radar:notificationURL"]?.string()
        self.campaignMetadata = metadata["radar:campaignMetadata"]?.string()
    }
    
    func toNotificationContent(userInfo: [String: Any]) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        
        if let notificationTitle {
            content.title = NSString.localizedUserNotificationString(forKey: notificationTitle, arguments: nil)
        }
        if let notificationSubtitle {
            content.subtitle = NSString.localizedUserNotificationString(forKey: notificationSubtitle, arguments: nil)
        }
        content.body = NSString.localizedUserNotificationString(forKey: notificationText, arguments: nil)
        
        content.userInfo = userInfo
        content.userInfo["campaignId"] = campaignId
        content.userInfo["url"] = notificationURL
        if let data = campaignMetadata?.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) {
            content.userInfo["campaignMetadata"] = json
        }
        
        return content
    }
}

extension RadarGeofence_Swift {
    func toNotificationRequest(now: Date = Date()) -> UNNotificationRequest? {
        let identifier = GEOFENCE_NOTIFICATION_PREFIX + _id
        // Content
        guard let metadata = metadata,
              let metadataContent = RadarNotificationContent(from: metadata) else {
            return nil
        }
        guard let geofenceData = try? JSONEncoder().encode(self) else {
            return nil
        }
        let userInfo: [String: Any] = [
            "registeredAt": now.timeIntervalSince1970,
            "identifier": identifier,
            "geofenceId": _id,
            "geofenceData": geofenceData,
        ]
        let content = metadataContent.toNotificationContent(userInfo: userInfo)
        
        // Trigger
        let latitude = geometryCenter.coordinate.latitude
        let longitude = geometryCenter.coordinate.longitude
        let radius = geometryRadius
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        let repeats = if case let .bool(value)? = metadata["radar:notificationRepeats"] { value } else { false }
        let trigger = UNLocationNotificationTrigger(region: region, repeats: repeats)
        
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}

struct NotificationValue: Codable, Hashable {
    let identifier: String
    let registeredAt: Double
    let geofenceId: String?
    let campaignId: String?
    
    init?(from request: UNNotificationRequest) {
        if !request.identifier.starts(with: RADAR_NOTIFICATION_PREFIX) {
            return nil
        }
        let userInfo = request.content.userInfo
        guard let registeredAt = userInfo["registeredAt"] as? Double else {
            return nil
        }
        
        self.identifier = request.identifier
        self.registeredAt = registeredAt
        
        self.geofenceId = userInfo["geofenceId"] as? String
        self.campaignId = userInfo["campaignId"] as? String
    }
}

//
@available(iOS 13.0, *)
@objc(RadarNotificationHelper_Swift) @objcMembers
actor RadarNotificationHelper: NSObject {
    
    private var currentTask: Task<Void, Never>?

    public static let shared = RadarNotificationHelper()
    
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
        print("task \(task.hashValue)")
        await task.value
    }
    
    private func registerNotifications(notifications: [UNNotificationRequest]) async {
        let notificationCenter = UNUserNotificationCenter.current()
        
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
        
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if Task.isCancelled {
            return
        }
        if settings.authorizationStatus != .authorized {
            RadarLogger.debug("NotificationHelper notifications unauthorized")
            return
        }
        
        // add notifications
        for notification in notifications {
            do {
                try await notificationCenter.add(notification)
                print("added \(notification.identifier)")
                if Task.isCancelled {
                    return
                }
            } catch {
                RadarLogger.warning("NotificationHelper failed to add notification \(error) \(notification)")
            }
        }
        
        let pending = await notificationCenter.pendingNotificationRequests().compactMap {
            NotificationValue(from: $0)
        }
        RadarState.registeredNotifications = pending
        RadarLogger.debug("NotificationHelper registered: \(pending.map(\.identifier))")
    }
    
    public func getDeliveredNotifications() async -> [[String: Sendable]] {
        
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let permissions = NotificationPermissions(from: settings)
        if (!permissions.canSendNotification()) {
            return []
        }
        
        let registerTask = currentTask
        if let registerTask {
            // if theres a register currently in progress, we need to wait for that to complete
            await registerTask.value
            // if that task was cancelled, there's an active
            // instance of `registerNotifications` that's modifying the notification list, so the diff
            // might not be correct.
            if registerTask.isCancelled {
                RadarLogger.debug("NotificationHelper getDeliveredNotifications while registering")
                return []
            }
        }
        
        guard let registered = RadarState.registeredNotifications else {
            return []
        }
        let notificationCenter = UNUserNotificationCenter.current()
        let pendingRequests = await notificationCenter.pendingNotificationRequests().compactMap {
            NotificationValue(from: $0)
        }
        // if during await pendingNotificationRequests, the task has changed, there's an active
        // instance of `registerNotifications` that's modifying the notification list, so the diff
        // might not be correct.
        if registerTask != currentTask {
            RadarLogger.debug("NotificationHelper getDeliveredNotifications while registering")
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
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let permissions = NotificationPermissions(from: settings)
        guard let data = try? JSONEncoder().encode(permissions) else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
