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
    // trigger
    let latitude: Double
    let longitude: Double
    let radius: Double
    let repeats: Bool
    // content
    let title: String
    let subtitle: String
    let body: String
    let userInfo: [String: Sendable]?
}

extension NotificationRequest {
    static func from(_ request: UNNotificationRequest?) -> NotificationRequest? {
        guard let request else {
            return nil
        }
        guard let trigger = request.trigger as? UNLocationNotificationTrigger,
              let region = trigger.region as? CLCircularRegion else {
            return nil
        }
        let content = request.content
        return NotificationRequest(
            identifier: request.identifier,
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            radius: region.radius,
            repeats: trigger.repeats,
            title: content.title,
            subtitle: content.subtitle,
            body: content.body,
            userInfo: content.userInfo as? [String: Sendable]
        )
    }
    
    func toRequest() -> UNNotificationRequest {
        // content
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        
        // trigger
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        let trigger = UNLocationNotificationTrigger(region: region, repeats: repeats)
        
        // request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        return request
    }
    
    func isEqual(to other: NotificationRequest?) -> Bool {
        guard let other else {
            return false
        }
        // compare metadata
        if ((userInfo == nil) != (other.userInfo == nil)) {
            return false
        }
        if let a = userInfo,
           let b = other.userInfo {
            if (a.count != b.count) {
                return false
            }
            if (!a.allSatisfy { key, value in
                // currently just check that the other key also exist
                return b[key] != nil
            }) {
                return false
            }
        }
        // compare other fields
        return identifier == other.identifier
            && latitude == other.latitude
            && longitude == other.longitude
            && radius == other.radius
            && title == other.title
            && subtitle == other.subtitle
            && body == other.body
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
    
    static let shared = RadarLocationManager()
    
    var locationManager: CLLocationManager?
    
    let geofencePrefix = "radar_geofence_"
    
    func region(for geofence: RadarGeofence, id: String) -> CLCircularRegion? {
        if let geometry = geofence.geometry as? RadarCircleGeometry {
            return CLCircularRegion(center: geometry.center.coordinate, radius: geometry.radius, identifier: id)
        }
        if let geometry = geofence.geometry as? RadarPolygonGeometry {
            return CLCircularRegion(center: geometry.center.coordinate, radius: geometry.radius, identifier: id)
        }
        return nil
    }
    
    func request(for geofence: RadarGeofence, id: String) -> NotificationRequest? {
        guard let metadata = geofence.metadata else {
            return nil
        }
        guard let region = region(for: geofence, id: id) else {
            return nil
        }
        guard let text = metadata["radar:notificationText"] as? String else {
            return nil
        }
        guard let campaignType = metadata["radar:campaignType"] as? String,
              campaignType == "clientSide" || campaignType == "eventBased" else {
            return nil
        }
        // optional params
        let title = (metadata["radar:notificationTitle"] as? String).map { str in
            NSString.localizedUserNotificationString(forKey: str, arguments: nil)
        } ?? ""
        let subtitle = (metadata["radar:notificationSubtitle"] as? String).map { str in
            NSString.localizedUserNotificationString(forKey: str, arguments: nil)
        } ?? ""
        let body = NSString.localizedUserNotificationString(forKey: text, arguments: nil)
        // userInfo
        var userInfo = [String: Sendable]()
        userInfo["registeredAt"] = Date().timeIntervalSince1970
        userInfo["url"] = metadata["radar:notificationURL"] as? String
        userInfo["campaignId"] = metadata["radar:campaignId"] as? String
        userInfo["identifier"] = id
        userInfo["geofenceId"] = geofence._id
        if let campaignMetadataString = metadata["radar:campaignMetadata"] as? String,
           let campaignMetadataData = campaignMetadataString.data(using: .utf8),
           let campaignMetadata = try? JSONSerialization.jsonObject(with: campaignMetadataData) {
            userInfo["campaignMetadata"] = campaignMetadata as? [String: Sendable]
        }
        // trigger
        let repeats = geofence.metadata?["radar:notificationRepeats"] as? Bool ?? false
        
        return NotificationRequest(
            identifier: id,
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            radius: region.radius,
            repeats: repeats,
            title: title,
            subtitle: subtitle,
            body: body,
            userInfo: userInfo)
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
    
    /// remove all monitored regions and notifications that are not in this list, and remove them from the list
    func removeAllExcept(geofences: inout [String: CLCircularRegion], notifications: inout [String: NotificationRequest]) async {
        guard let locationManager = self.locationManager else {
            return
        }
        
        var geofencesRemoved = 0
        var nonRadarMonitoredRegions = [String]()
        // remove regions not in the regions list
        for region in locationManager.monitoredRegions {
            if !region.identifier.hasPrefix(geofencePrefix) {
                nonRadarMonitoredRegions.append(region.identifier)
                continue
            }
            //
            if regionEquals(geofences[region.identifier], region) {
                geofences.removeValue(forKey: region.identifier)
            } else {
                locationManager.stopMonitoring(for: region)
                geofencesRemoved += 1
            }
        }
        // remove notifications not in the notifications list
        let requests = await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                cont.resume(returning: requests.compactMap {
                    return NotificationRequest.from($0)
                })
            }
        }
        var notificationsToRemove = [String]()
        for request in requests {
            if !request.identifier.hasPrefix(self.geofencePrefix) {
                continue
            }
            if request.isEqual(to: notifications[request.identifier]) {
                notifications.removeValue(forKey: request.identifier)
            } else {
                notificationsToRemove.append(request.identifier)
            }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationsToRemove)
        
        RadarLogger.shared.debug("GeofenceSync removed \(geofencesRemoved) geofence regions and \(notificationsToRemove.count) notifications")
        if (nonRadarMonitoredRegions.count > 0) {
            RadarLogger.shared.debug("GeofenceSync found \(nonRadarMonitoredRegions.count) non-Radar monitored regions: \(nonRadarMonitoredRegions.joined(separator: ","))")
        }
    }
    
    /// add all geofences to monitored regions, add all notifications to pending notifications
    /// maybe require notifications to be enabled in here
    func add(geofences: [String: CLCircularRegion], notifications: [String: NotificationRequest]) async {
        guard let locationManager = self.locationManager else {
            return
        }
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
                try await notificationCenter.add(notification.toRequest())
            } catch {
                RadarLogger.shared.log(level: .warning, message: "Failed to add notification: \(error)")
            }
        }
        
        RadarLogger.shared.debug("GeofenceSync added \(geofences.count) geofence regions and \(notifications.count) notifications")
    }
    
    func replaceMonitoredRegions(geofences: [RadarGeofence]) {
        RadarLogger.shared.debug("Syncing with improved sync logic")
        
        guard self.locationManager != nil else {
            return
        }
        
        let limit = Radar.getTrackingOptions().beacons ? 9 : 19
        RadarLogger.shared.info("Syncing \(geofences.count) geofences with \(limit) allowed")
        
        // create the geofence and notification array, which includes already registered regions
        var geofenceRegions = [String: CLCircularRegion]()
        var notifications = [String: NotificationRequest]()
        
        var regionCount = 0
        for geofence in geofences {
            let id = "\(geofencePrefix)\(geofence._id)"
            
            // notification (priority over geofence if there is only 1 slot left
            if let request = request(for: geofence, id: id) {
                notifications[id] = request
                regionCount += 1
            }
            
            if regionCount >= limit {
                break
            }
            
            // geofence
            if let region = region(for: geofence, id: id) {
                geofenceRegions[id] = region
                regionCount += 1
            }
            
            if regionCount >= limit {
                break
            }
        }
        
        RadarLogger.shared.debug("GeofenceSync with \(geofenceRegions.count) geofence regions and \(notifications.count) notifications")
        
        Task {
            await removeAllExcept(geofences: &geofenceRegions, notifications: &notifications)
            await add(geofences: geofenceRegions, notifications: notifications)
        }
    }
}
