//
//  RadarNotificationHelper.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 3/6/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

let GEOFENCE_NOTIFICATION_PREFIX = "radar_geofence_"

struct RadarNotificationContent: Sendable {
    let notificationTitle: String?
    let notificationSubtitle: String?
    let notificationText: String
    let notificationURL: String?
    let campaignId: String
    let campaignMetadata: [String: Sendable]?
    
    static func fromMetadata(_ metadata: [String: Any]) -> RadarNotificationContent? {
        // required fields
        guard let notificationText = metadata["radar:notificationText"] as? String,
              let campaignId = metadata["radar:campaignId"] as? String else {
            return nil
        }
        // optional fields
        let notificationTitle = metadata["radar:notificationTitle"] as? String
        let notificationSubtitle = metadata["radar:notificationSubtitle"] as? String
        let notificationURL = metadata["radar:notificationURL"] as? String
        let campaignMetadataString = metadata["radar:campaignMetadata"] as? String
        let campaignMetadata: [String: Sendable]?
        if let campaignMetadataString,
           let data = campaignMetadataString.data(using: .utf8) {
            campaignMetadata = try? JSONSerialization.jsonObject(with: data) as? [String: Sendable]
        } else {
            campaignMetadata = nil
        }
        
        let notification = RadarNotificationContent(
            notificationTitle: notificationTitle,
            notificationSubtitle: notificationSubtitle,
            notificationText: notificationText,
            notificationURL: notificationURL,
            campaignId: campaignId,
            campaignMetadata: campaignMetadata,
        )
        return notification
    }
    
    func toNotificationContent(userInfo: [String: Any]) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        
        content.userInfo = userInfo
        content.userInfo["campaignId"] = campaignId
        content.userInfo["url"] = notificationURL
        content.userInfo["campaignMetadata"] = campaignMetadata
    }
}

struct RadarGeofenceNotification: Sendable {
    let campaignType: String
    let geofenceId: String?
    let content: RadarNotificationContent
    let geofence: RadarGeofence
    
    func toNotificationRequest() -> UNNotificationRequest {
        let userInfo = [
            "registerdAt": Date(),
        ]
        let content = content.toNotificationContent(userInfo: userInfo)
        
        
        
        let trigger = UNLocationNotificationTrigger(region: <#T##CLRegion#>, repeats: <#T##Bool#>)
        
        
        return UNNotificationRequest(identifier: "RadarSDKNotification", content: content, trigger: )
    }
    
    static func from(geofence: ) -> RadarGeofenceNotification? {
        guard let content = RadarNotificationContent.fromMetadata([:]) else {
            
        }
    }
    
    
    
    static func fromRequest(_ request: UNNotificationRequest) -> RadarGeofenceNotification? {
        if request.identifier.starts(with: GEOFENCE_NOTIFICATION_PREFIX) {
            
        }
    }
}

//
@available(iOS 13.0, *)
actor RadarNotificationHelper {
    
    private var currentTask: Task<Void, Never>?

    public func registerGeofenceNotifications(geofences: [[String: Any]]) async {
        let radarGeofences = geofences.compactMap { RadarGeofence(object: $0) }
        await registerNotifications(geofences: radarGeofences)
    }

    public func registerNotifications(geofences: [RadarGeofence]) async {

        // cancel previous work
        currentTask?.cancel()
        await currentTask?.value

        let task = Task { [notifications] in
            let notificationCenter = UNUserNotificationCenter.current()
            
            // get existing scheduled notifications
            let requests = await notificationCenter.pendingNotificationRequests()
            
            // remove the ones that should no longer be sent
            var notificationsToRemove: [String] = []
            var notificationsToAdd: [RadarNotification] = []
            for notification in notifications {
                
            }
            
            
            notificationCenter.removePendingNotificationRequests(withIdentifiers: )

            
            
            // add the ones we want
            for notification in notifications {
                let request = notification.toRequest()
                do {
                    try await notificationCenter.add(request)
                } catch {
                    print("Failed to add notification \(error) \(request)")
                }
            }
            
            
            
        }
    }
}
