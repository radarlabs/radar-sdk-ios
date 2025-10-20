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
    let userInfo: [String: Sendable]
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
            userInfo: content.userInfo as? [String: Sendable] ?? [:]
        )
    }
    
    func toRequest() -> UNNotificationRequest {
        // content
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.userInfo = userInfo
        
        // trigger
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        let trigger = UNLocationNotificationTrigger(region: region, repeats: repeats)
        
        // request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        return request
    }
    
    static func metadataEqual(_ a: [String: Sendable], _ b: [String: Sendable]) -> Bool {
        if a.count != b.count {
            return false
        }
        return a.allSatisfy { key, aValue in
            guard let bValue = b[key] else {
                return false
            }
            if let aValue = aValue as? String {
                if aValue != (bValue as? String) {
                    return false
                }
            }
            if let aValue = aValue as? Double {
                if aValue != (bValue as? Double) {
                    return false
                }
            }
            if let aValue = aValue as? Int {
                if aValue != (bValue as? Int) {
                    return false
                }
            }
            if let aValue = aValue as? Bool {
                if aValue != (bValue as? Bool) {
                    return false
                }
            }
            if let aValue = aValue as? [String: Sendable] {
                let bValue = bValue as? [String: Sendable]
                if bValue == nil || !metadataEqual(aValue, bValue!) {
                    return false
                }
            }
            return true
        }
    }
    
    func isEqual(to other: NotificationRequest?) -> Bool {
        guard let other else {
            return false
        }
        // compare userInfo, (don't compare registeredAt)
        var a = userInfo
        a.removeValue(forKey: "registeredAt")
        var b = other.userInfo
        b.removeValue(forKey: "registeredAt")
        if !NotificationRequest.metadataEqual(a, b) {
            return false
        }
        // compare other fields
        return identifier == other.identifier
            && latitude == other.latitude
            && longitude == other.longitude
            && radius == other.radius
            && repeats == other.repeats
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
    
    /// create a circular region from the geofence
    func region(for geofence: RadarGeofence, id: String) -> CLCircularRegion? {
        if let geometry = geofence.geometry as? RadarCircleGeometry {
            return CLCircularRegion(center: geometry.center.coordinate, radius: geometry.radius, identifier: id)
        }
        if let geometry = geofence.geometry as? RadarPolygonGeometry {
            return CLCircularRegion(center: geometry.center.coordinate, radius: geometry.radius, identifier: id)
        }
        return nil
    }
    
    /// create a NotificationRequest object from the radar geofence if the geofence contains notification data NotificationRequest can be converted directly to UNNotificationRequest
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
        
        var campaignMetadata: [String: Sendable]? = nil
        if let campaignMetadataString = metadata["radar:campaignMetadata"] as? String,
           let campaignMetadataData = campaignMetadataString.data(using: .utf8) {
            campaignMetadata = try? JSONSerialization.jsonObject(with: campaignMetadataData) as? [String: Sendable]
            if (campaignMetadata != nil) {
                userInfo["campaignMetadata"] = campaignMetadata
            }
        }
        // trigger
        let geofenceMetadataRepeats = geofence.metadata?["radar:notificationRepeats"] as? Bool
        let campaignMetadataRepeats = campaignMetadata?["radar:notificationRepeats"] as? Bool
        // can be enabled in both geofence and campaign, geofence takes priority if set
        let repeats = (geofenceMetadataRepeats != nil ? geofenceMetadataRepeats : campaignMetadataRepeats) ?? false
        
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
        
        var geofencesRemoved = [String]()
        var nonRadarMonitoredRegions = [String]()
        // remove regions not in the regions list
        for region in locationManager.monitoredRegions {
            if !region.identifier.hasPrefix("radar_") {
                nonRadarMonitoredRegions.append(region.identifier)
                continue
            }
            
            if !region.identifier.hasPrefix(geofencePrefix) {
                continue
            }
            //
            if regionEquals(geofences[region.identifier], region) {
                geofences.removeValue(forKey: region.identifier)
            } else {
                locationManager.stopMonitoring(for: region)
                geofencesRemoved.append(region.identifier)
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
        // remove from registered notifications
        var registered = RadarState.registeredNotifications
        registered.removeAll(where: { notificationsToRemove.contains($0["identifier"] as! String) })
        RadarState.registeredNotifications = registered
        
        RadarLogger.shared.debug("GeofenceSync removed \(geofencesRemoved.count) geofence regions and \(notificationsToRemove.count) notifications | geofences: \(geofencesRemoved); notifications: \(notificationsToRemove)")
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
        var successfulNotificatons = [NotificationRequest]()
        for notification in notifications.values {
            do {
                let request = notification.toRequest()
                try await notificationCenter.add(request)
                successfulNotificatons.append(notification)
                RadarLogger.shared.debug("GeofenceSync notification added \(notification.identifier) with \((request.trigger?.repeats ?? false) ? "repeating" : "non-repeating"); userInfo: \(request.content.userInfo)")
            } catch {
                RadarLogger.shared.debug("GeofenceSync failed to add notification \(notification.identifier): \(error)")
            }
        }
        
        var registered = RadarState.registeredNotifications
        registered.append(contentsOf: successfulNotificatons.map(\.userInfo))
        RadarState.registeredNotifications = registered
        
        let addedGeofencesIds = geofences.values.map(\.identifier)
        let addedNotificationsIds = successfulNotificatons.map(\.identifier)
        RadarLogger.shared.debug("GeofenceSync added \(geofences.count) geofence regions and \(notifications.count) notifications | geofences: \(addedGeofencesIds), notifications: \(addedNotificationsIds)")
    }
    
    func replaceMonitoredRegions(geofences: [RadarGeofence]) {
        RadarLogger.shared.debug("GeofenceSync with improved sync logic")
        
        guard self.locationManager != nil else {
            return
        }
        
        let limit = Radar.getTrackingOptions().beacons ? 9 : 19
        RadarLogger.shared.debug("GeofenceSync called with \(geofences.count) geofences with \(limit) allowed")
        
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
        
        let geofenceIds = geofenceRegions.keys.map { $0.dropFirst(geofencePrefix.count) }
        RadarLogger.shared.debug("GeofenceSync with \(geofenceRegions.count) geofence regions and \(notifications.count) notifications | \(geofenceIds)")
        
        Task {
            await removeAllExcept(geofences: &geofenceRegions, notifications: &notifications)
            await add(geofences: geofenceRegions, notifications: notifications)
        }
    }
}
