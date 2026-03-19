//
//  RadarNotificationHelper.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

let RADAR_NOTIFICATION_PREFIX = "radar_"
let GEOFENCE_NOTIFICATION_PREFIX = "radar_geofence_"

struct RadarNotificationContent: Sendable, Hashable {
    let notificationTitle: String?
    let notificationSubtitle: String?
    let notificationText: String
    let notificationURL: String?
    let campaignId: String
    let campaignMetadata: String?
    
    init?(from metadata: [String: RadarMetadataValue]) {
        // required fields
        guard case let .string(notificationText)? = metadata["radar:notificationText"],
              case let .string(campaignId)? = metadata["radar:campaignId"] else {
            return nil
        }
        self.notificationText = notificationText
        self.campaignId = campaignId
        
        // optional fields
        if case let .string(value)? = metadata["radar:notificationTitle"] {
            self.notificationTitle = value
        }
        if case let .string(value)? = metadata["radar:notificationSubtitle"] {
            self.notificationSubtitle = value
        }
        if case let .string(value)? = metadata["radar:notificationURL"] {
            self.notificationURL = value
        }
        if case let .string(value)? = metadata["radar:campaignMetadata"] {
            self.campaignMetadata = value
        }
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
    func toNotificationRequest() -> UNNotificationRequest? {
        // Content
        guard let metadata = metadata,
              let metadataContent = RadarNotificationContent(from: metadata) else {
            return nil
        }
        let identifier = GEOFENCE_NOTIFICATION_PREFIX + _id
        
        var userInfo: [String: Any] = [
            "registerdAt": Date().timeIntervalSince1970,
            "identifier": identifier,
        ]
        if let geofenceData = try? JSONEncoder().encode(self) {
            userInfo["geofenceData"] = geofenceData
        }
        let content = metadataContent.toNotificationContent(userInfo: userInfo)
        
        // Trigger
        guard let latitude = geometry.center?.coordinate.latitude,
              let longitude = geometry.center?.coordinate.longitude,
              let radius = geometry.radius else {
            return nil
        }
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        let repeats = if case let .bool(value)? = metadata["radar:notificationRepeats"] { value } else { false }
        let trigger = UNLocationNotificationTrigger(region: region, repeats: repeats)
        
        return UNNotificationRequest(identifier: "RadarSDKNotification", content: content, trigger: trigger)
    }
}

struct NotificationValue: Codable, Hashable {
    let identifier: String
    let registerdAt: Double
    let geofenceId: String?
    let campaignId: String?
    
    init?(from request: UNNotificationRequest) {
        if !request.identifier.starts(with: RADAR_NOTIFICATION_PREFIX) {
            return nil
        }
        let userInfo = request.content.userInfo
        guard let registerdAt = userInfo["registerdAt"] as? Double else {
            return nil
        }
        
        self.identifier = request.identifier
        self.registerdAt = registerdAt
        
        self.geofenceId = userInfo["geofenceId"] as? String
        self.campaignId = userInfo["campaignId"] as? String
    }
}

/**
 Wrapper for UNNotificationRequest for comparison
 */
struct RadarNotification: Hashable {
    let request: UNNotificationRequest
    let identifier: String
    
    init?(from request: UNNotificationRequest) {
        if !request.identifier.starts(with: RADAR_NOTIFICATION_PREFIX) {
            return nil
        }
        self.request = request
        self.identifier = request.identifier
    }
    
    static func == (lhs: RadarNotification, rhs: RadarNotification) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

//
@available(iOS 13.0, *)
@objc(RadarNotificationHelper_Swift) @objcMembers
actor RadarNotificationHelper: NSObject {
    
    private var currentTask: Task<Void, Never>?

    static let shared = RadarNotificationHelper()
    
    public func registerGeofenceNotifications(geofences: [[String: Sendable]]) async {
        let notifications: [RadarNotification] = geofences.compactMap { (geofenceDict) -> RadarNotification? in
            if let json = try? JSONSerialization.data(withJSONObject: geofenceDict),
               let geofence = try? JSONDecoder().decode(RadarGeofence_Swift.self, from: json),
               let request = geofence.toNotificationRequest(),
               let notification = RadarNotification(from: request) {
                return notification
            }
            return nil
        }
        
        // cancel previous work
        currentTask?.cancel()
        await currentTask?.value
        
        currentTask = Task { [notifications] in
            await registerNotifications(notifications: notifications)
        }
    }
    
    private func registerNotifications(notifications: [RadarNotification]) async {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // get existing scheduled notifications
        let requests = await notificationCenter.pendingNotificationRequests().compactMap(RadarNotification.init(from:))
        
        // remove the ones that should no longer be sent
        // TODO: maybe specify comparison function (without using set operations)
        var notificationsToRemove = Set(requests).subtracting(notifications)
        var notificationsToAdd = Set(notifications).subtracting(requests)
        
        
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: notificationsToRemove.map(\.identifier))
        
        // add the ones we want
        for notification in notificationsToAdd {
            do {
                try await notificationCenter.add(notification)
            } catch {
                print("Failed to add notification \(error) \(notification)")
            }
        }
        
        let pending = await notificationCenter.pendingNotificationRequests().compactMap {
            NotificationValue.from(request: $0)
        }
        
        RadarState.registeredNotifications = pending
    }
    
    public func getDeliveredNotifications() async -> [[String: Sendable]] {
        let notificationCenter = UNUserNotificationCenter.current()
        
        guard let registered = RadarState.registeredNotifications else {
            return []
        }
        let pendingRequests = await notificationCenter.pendingNotificationRequests().compactMap {
            NotificationValue.from(request: $0)
        }
        
        let delivered = Set(registered).subtracting(pendingRequests)
        
        if let data = try? JSONEncoder().encode(Array(delivered)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Sendable]] {
            return json
        }
        return []
    }
}
