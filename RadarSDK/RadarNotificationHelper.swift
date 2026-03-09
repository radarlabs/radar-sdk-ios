//
//  RadarNotificationHelper.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 3/6/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

let GEOFENCE_NOTIFICATION_PREFIX = "radar_geofence_"



if (notificationText && [RadarNotificationHelper isNotificationCampaign:metadata]) {
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    if (notificationTitle) {
        content.title = [NSString localizedUserNotificationStringForKey:notificationTitle arguments:nil];
    }
    if (notificationSubtitle) {
        content.subtitle = [NSString localizedUserNotificationStringForKey:notificationSubtitle arguments:nil];
    }
    content.body = [NSString localizedUserNotificationStringForKey:notificationText arguments:nil];
    
    NSMutableDictionary *mutableUserInfo = [metadata mutableCopy];

    NSDate *now = [NSDate new];
    NSTimeInterval lastSyncInterval = [now timeIntervalSince1970];
    mutableUserInfo[@"registeredAt"] = [NSString stringWithFormat:@"%f", lastSyncInterval];

    if (notificationURL) {
        mutableUserInfo[@"url"] = notificationURL;
    }
    if (campaignId) {
        mutableUserInfo[@"campaignId"] = campaignId;
    }
    if (identifier) {
        mutableUserInfo[@"identifier"] = identifier;

        if ([identifier hasPrefix:@"radar_geofence_"]) {
            mutableUserInfo[@"geofenceId"] = [identifier stringByReplacingOccurrencesOfString:@"radar_geofence_" withString:@""];
        }
    }
    if (campaignMetadata && [campaignMetadata isKindOfClass:[NSString class]]) {
        NSError *jsonError;
        NSData *jsonData = [((NSString *)campaignMetadata) dataUsingEncoding:NSUTF8StringEncoding];
        id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
        if (!jsonError && [jsonObj isKindOfClass:[NSDictionary class]]) {
            mutableUserInfo[@"campaignMetadata"] = (NSDictionary *)jsonObj;
        }
    }
    
    content.userInfo = [mutableUserInfo copy];
    return content;
} else {
    return nil;
}


struct RadarNotificationContent: Codable, Sendable {
    let notificationTitle: String?
    let notificationSubtitle: String?
    let notificationText: String
    let notificationURL: String?
    let campaignId: String
    let campaignMetadata: String?
    
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
        let campaignMetadata = metadata["radar:campaignMetadata"] as? String
        
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
    
    func toNotificationContent() -> UNNotificationContent {
        
    }
}

struct RadarGeofenceNotification: Codable, Sendable {
    let campaignType: String
    let geofenceId: String?
    let content: RadarNotificationContent
    
    func toNotificationRequest() -> UNNotificationRequest {
        let content = content.toNotificationContent()
        let
        
        
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

    public func registerGeofenceNotifications(notifications: [RadarNotification]) async {

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
