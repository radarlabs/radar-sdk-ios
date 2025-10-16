//
//  RadarLocationManager.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 10/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation


struct NotificationRequest {
    let identifier: String
    let latitude: Double
    let longitude: Double
    let radius: Double
}

extension NotificationRequest {
    static func fromNotification(_ request: UNNotificationRequest?) -> NotificationRequest? {
        guard let request else {
            return nil
        }
        guard let trigger = request.trigger as? UNLocationNotificationTrigger,
              let region = trigger.region as? CLCircularRegion else {
            return nil
        }
        return NotificationRequest(
            identifier: request.identifier,
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            radius: region.radius
        )
    }
    
    static func toNotification() {
        
    }
}

@globalActor
@available(iOS 13.0, *)
actor IOActor {
    static let shared = IOActor()
}

@IOActor
@available(iOS 13.0, *)
@objc(RadarLocationManagerSwift) @objcMembers
class RadarLocationManager: NSObject {
    
    let locationManager: CLLocationManager
    
    let geofencePrefix = "radar_geofence_"
    let notificationPrefix = "radar_notification_"
    
    public init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }
    
    func region(for geofence: RadarGeofence, id: String) -> CLCircularRegion? {
        if let geometry = geofence.geometry as? RadarCircleGeometry {
            return CLCircularRegion(center: geometry.center.coordinate, radius: geometry.radius, identifier: id)
        }
        if let geometry = geofence.geometry as? RadarPolygonGeometry {
            return CLCircularRegion(center: geometry.center.coordinate, radius: geometry.radius, identifier: id)
        }
        return nil
    }
    
    func notificationContent(from metadata: [AnyHashable: Any]?, identifier: String) -> UNMutableNotificationContent? {
        guard var metadata = metadata else {
            return nil
        }
        guard let text = metadata["radar:notificationText"] as? String else {
            return nil
        }
        guard let campaignType = metadata["radar:campaignType"] as? String,
              campaignType == "clientSide" || campaignType == "eventBased" else {
            return nil
        }
        
        let content = UNMutableNotificationContent()
        if let title = metadata["radar:notificationTitle"] as? String {
            content.title = NSString.localizedUserNotificationString(forKey: title, arguments: nil)
        }
        if let subtitle = metadata["radar:notificationSubtitle"] as? String {
            content.subtitle = NSString.localizedUserNotificationString(forKey: subtitle, arguments: nil)
        }
        content.body = NSString.localizedUserNotificationString(forKey: text, arguments: nil)
        
        let now = Date()
        metadata["registeredAt"] = now.timeIntervalSince1970
        
        if let notificationUrl = metadata["radar:notificationURL"] as? String {
            metadata["url"] = notificationUrl
        }
        if let campaignId = metadata["radar:campaignId"] as? String {
            metadata["campaignId"] = campaignId
        }
        metadata["identifier"] = identifier
        if identifier.hasPrefix(geofencePrefix) {
            metadata["geofenceId"] = identifier.replacingOccurrences(of: geofencePrefix, with: "")
        }
        if let campaignMetadataString = ["radar:campaignMetadata"] as? String,
           let campaignMetadataData = campaignMetadataString.data(using: .utf8),
           let campaignMetadata = try? JSONSerialization.jsonObject(with: campaignMetadataData) {
            metadata["campaignMetadata"] = campaignMetadata
        }
        content.userInfo = metadata
        return content
    }
    
    func regionEquals(_ regionA: CLRegion?, _ regionB: CLRegion?) -> Bool {
        guard let a = regionA as? CLCircularRegion,
              let b = regionB as? CLCircularRegion else {
            if (regionA == nil && regionB == nil) {
                return true;
            }
            return false
        }
        
        if (a.identifier != b.identifier) {
            return false;
        }
        
        return (a.center.latitude == b.center.latitude &&
                a.center.longitude == b.center.longitude &&
                a.radius == b.radius)
    }
    
    func notificationEquals(_ a: NotificationRequest?, _ b: NotificationRequest?) -> Bool {
        guard let a, let b else {
            return (a == nil) && (b == nil)
        }
        
        return a.identifier == b.identifier &&
               a.latitude == b.latitude &&
               a.longitude == b.longitude &&
               a.radius == b.radius
    }
    
    /// remove all monitored regions and notifications that are not in this list, and remove them from the list
    func removeAllExcept(geofences: inout [String: CLCircularRegion], notifications: inout [String: UNNotificationRequest]) async {
        // remove regions not in the regions list
        for region in locationManager.monitoredRegions {
            if !region.identifier.hasPrefix(geofencePrefix) {
                continue
            }
            //
            if regionEquals(geofences[region.identifier], region) {
                geofences.removeValue(forKey: region.identifier)
            } else {
                locationManager.stopMonitoring(for: region)
            }
        }
        // remove notifications not in the notifications list
        let requests = await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                cont.resume(returning: requests.compactMap {
                    return NotificationRequest.fromNotification($0)
                })
            }
        }
        var notificationsToRemove = [String]()
        for request in requests {
            if !request.identifier.hasPrefix(self.notificationPrefix) {
                continue
            }
            if notificationEquals(NotificationRequest.fromNotification(notifications[request.identifier]), request) {
                notifications.removeValue(forKey: request.identifier)
            } else {
                notificationsToRemove.append(request.identifier)
            }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationsToRemove)
    }
    
    /// add all geofences to monitored regions, add all notifications to pending notifications
    /// maybe require notifications to be enabled in here
    func add(geofences: [String: CLCircularRegion], notifications: [String: UNNotificationRequest]) async {
        // add to geofences
        for geofence in geofences.values {
            locationManager.startMonitoring(for: geofence)
        }
        // add to notifications
        let notificationCenter = UNUserNotificationCenter.current()
        let authorized = await withCheckedContinuation { cont in
            notificationCenter.getNotificationSettings { settings in
                cont.resume(returning: settings.authorizationStatus == .authorized)
            }
        }
        if (!authorized) {
            return
        }
        for notification in notifications.values {
            do {
                try await notificationCenter.add(notification)
            } catch {
                RadarLogger.shared.log(level: .warning, message: "Failed to add notification: \(error)")
            }
        }
    }
    
    public func replaceMonitoredRegions(geofences: [RadarGeofence]) {
        let limit = Radar.getTrackingOptions().beacons ? 9 : 19
        RadarLogger.shared.info("Syncing \(geofences.count) geofences with \(limit) allowed")
        
        // create the geofence and notification array, which includes already registered regions
        var geofenceRegions = [String: CLCircularRegion]()
        var notifications = [String: UNNotificationRequest]()
        
        var regionCount = 0
        for geofence in geofences {
            let geofenceIdentifier = "\(geofencePrefix)\(geofence._id)"
            let notificationIdentifier = "\(notificationPrefix)\(geofence._id)"
            
            // notification (priority over geofence if there is only 1 slot left
            let notification = notificationContent(from: geofence.metadata, identifier: notificationIdentifier)
            let notificationRegion = region(for: geofence, id: notificationIdentifier)
            if let notification, let region = notificationRegion {
                
                let repeats = geofence.metadata?["radar:notificationRepeats"] as? Bool ?? false
                
                let trigger = UNLocationNotificationTrigger(region: region, repeats: repeats)
                let request = UNNotificationRequest(identifier: notificationIdentifier, content: notification, trigger: trigger)
                    
                notifications[notificationIdentifier] = request
                regionCount += 1
            }
            
            if regionCount >= limit {
                break
            }
            
            // geofence
            if let region = region(for: geofence, id: geofenceIdentifier) {
                geofenceRegions[geofenceIdentifier] = region
                regionCount += 1
            }
            
            if regionCount >= limit {
                break
            }
        }
        
        
        RadarLogger.shared.info("Syncing \(geofenceRegions.count) geofence regions and \(notifications.count) notifications")
        
        Task {
            await removeAllExcept(geofences: &geofenceRegions, notifications: &notifications)
            await add(geofences: geofenceRegions, notifications: notifications)
        }
    }
}
