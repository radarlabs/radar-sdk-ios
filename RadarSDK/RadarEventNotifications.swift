//
//  RadarEventNotifications.swift
//  RadarSDK
//
//  Created by Alan Charles on 7/17/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import UserNotifications

private let kEventNotificationIdentifierPrefix = "radar_event_notification_"

@objc public final class RadarEventNotifications: NSObject {
    
    /// Show local notifications for incoming events (geofence, beacon, trip).
    /// Called by RadarDelegateHolder when events arrive.
    @objc public static func showNotifications(for events: [RadarEvent]) {
        guard !events.isEmpty else { return }
        
        for event in events {
            let identifier = "\(kEventNotificationIdentifierPrefix)\(event._id)"
            let categoryIdentifier = RadarEvent.string(for: event.type) ?? ""
            
            // Campaign path: rich content from event metadata (title, subtitle, url, campaignId, etc.)
            if let content = extractCampaignContent(from: event.metadata, identifier: identifier) {
                content.categoryIdentifier = categoryIdentifier
                postNotification(identifier: identifier, content: content)
                continue
            }
            
            // Legacy path: simple notification text from geofence/beacon/trip metadata
            guard let (metadata, text) = legacyNotificationText(for: event) else { continue }
            
            let content = UNMutableNotificationContent()
            content.body = NSString.localizedUserNotificationString(forKey: text, arguments: nil)
            content.userInfo = metadata
            content.categoryIdentifier = categoryIdentifier
            postNotification(identifier: identifier, content: content)
        }
    }
    
    // MARK: - Campaign content extraction
    
    /// Builds notification content from campaign metadata. Returns nil if not a campaign
    /// or missing required fields.
    @objc public static func extractCampaignContent(
        from metadata: [AnyHashable: Any]?,
        identifier: String?
    ) -> UNMutableNotificationContent? {
        guard let metadata = metadata as? [String: Any] else {
            if let identifier {
                RadarLogger.shared.log( level: .error, message:"No metadata found for identifier = \(identifier)")
            }
            return nil
        }
        
        guard let notificationText = metadata["radar:notificationText"] as? String,
              isCampaign(metadata)
        else { return nil }
        
        let content = UNMutableNotificationContent()
        
        if let title = metadata["radar:notificationTitle"] as? String {
            content.title = NSString.localizedUserNotificationString(forKey: title, arguments: nil)
        }
        if let subtitle = metadata["radar:notificationSubtitle"] as? String {
            content.subtitle = NSString.localizedUserNotificationString(forKey: subtitle, arguments: nil)
        }
        content.body = NSString.localizedUserNotificationString(forKey: notificationText, arguments: nil)
        
        var userInfo = metadata
        userInfo["registeredAt"] = "\(Date().timeIntervalSince1970)"
        
        if let url = metadata["radar:notificationURL"] as? String {
            userInfo["url"] = url
        }
        if let campaignId = metadata["radar:campaignId"] as? String {
            userInfo["campaignId"] = campaignId
        }
        if let identifier {
            userInfo["identifier"] = identifier
            if identifier.hasPrefix("radar_geofence_") {
                userInfo["geofenceId"] = identifier.replacingOccurrences(of: "radar_geofence_", with: "")
            }
        }
        if let campaignMetadataStr = metadata["radar:campaignMetadata"] as? String,
           let data = campaignMetadataStr.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            userInfo["campaignMetadata"] = json
        }

        content.userInfo = userInfo
        return content
    }
    
    // MARK: - Helpers
    
    static func isCampaign(_ metadata: [String: Any]) -> Bool {
        guard let campaignType = metadata["radar:campaignType"] as? String else { return false }
        return campaignType == "clientSide" || campaignType == "eventBased"
    }
    
    /// Extracts the legacy notification text and source metadata for an event,
    /// based on event type and the associated geofence/beacon/trip metadata.
    static func legacyNotificationText(for event: RadarEvent) -> ([AnyHashable: Any], String)? {
        switch event.type {
        case .userEnteredGeofence:
            guard let metadata = event.geofence?.metadata,
                  let text = metadata["radar:entryNotificationText"] as? String
            else { return nil }
            return (metadata, text)

        case .userExitedGeofence:
            guard let metadata = event.geofence?.metadata,
                  let text = metadata["radar:exitNotificationText"] as? String
            else { return nil }
            return (metadata, text)

        case .userEnteredBeacon:
            guard let metadata = event.beacon?.metadata,
                  let text = metadata["radar:entryNotificationText"] as? String
            else { return nil }
            return (metadata, text)

        case .userExitedBeacon:
            guard let metadata = event.beacon?.metadata,
                  let text = metadata["radar:exitNotificationText"] as? String
            else { return nil }
            return (metadata, text)

        case .userApproachingTripDestination:
            guard let metadata = event.trip?.metadata,
                  let text = metadata["radar:approachingNotificationText"] as? String
            else { return nil }
            return (metadata, text)

        case .userArrivedAtTripDestination:
            guard let metadata = event.trip?.metadata,
                  let text = metadata["radar:arrivalNotificationText"] as? String
            else { return nil }
            return (metadata, text)

        default:
            return nil
        }
    }
    
    private static func postNotification(identifier: String, content: UNNotificationContent) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                RadarLogger.shared.log(level: .debug, message:"Error adding local notification | identifier = \(identifier); error = \(error)")
            } else {
                RadarLogger.shared.log(level: .debug, message:"Added local notification | identifier = \(identifier)")
            }
        }
    }
}
