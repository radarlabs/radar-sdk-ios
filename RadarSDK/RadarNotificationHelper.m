//
//  RadarNotificationHelper.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>

#import "RadarEvent.h"
#import "RadarLogger.h"
#import "RadarNotificationHelper.h"

@implementation RadarNotificationHelper

static NSString *const kEventNotificationIdentifierPrefix = @"radar_event_notification_";

+ (void)showNotificationsForEvents:(NSArray<RadarEvent *> *)events {
    if (!events || !events.count) {
        return;
    }
    
    for (RadarEvent *event in events) {
        NSString *notificationText;
        NSDictionary *metadata;
        
        if (event.type == RadarEventTypeUserEnteredGeofence && event.geofence && event.geofence.metadata) {
            metadata = event.geofence.metadata;
            notificationText = [metadata objectForKey:@"radar:entryNotificationText"];
        } else if (event.type == RadarEventTypeUserExitedGeofence && event.geofence && event.geofence.metadata) {
            metadata = event.geofence.metadata;
            notificationText = [metadata objectForKey:@"radar:exitNotificationText"];
        } else if (event.type == RadarEventTypeUserEnteredBeacon && event.beacon && event.beacon.metadata) {
            metadata = event.beacon.metadata;
            notificationText = [metadata objectForKey:@"radar:entryNotificationText"];
        } else if (event.type == RadarEventTypeUserExitedBeacon && event.beacon && event.geofence.metadata) {
            metadata = event.beacon.metadata;
            notificationText = [metadata objectForKey:@"radar:exitNotificationText"];
        } else if (event.type == RadarEventTypeUserApproachingTripDestination && event.trip && event.trip.metadata) {
            metadata = event.trip.metadata;
            notificationText = [event.trip.metadata objectForKey:@"radar:approachingNotificationText"];
        } else if (event.type == RadarEventTypeUserArrivedAtTripDestination && event.trip && event.trip.metadata) {
            metadata = event.trip.metadata;
            notificationText = [event.trip.metadata objectForKey:@"radar:arrivalNotificationText"];
        }
        
        if (notificationText) {
            NSString *identifier = [NSString stringWithFormat:@"%@%@", kEventNotificationIdentifierPrefix, event._id];
            NSString *categoryIdentifier = [RadarEvent stringForType:event.type];
            
            UNMutableNotificationContent *content = [UNMutableNotificationContent new];
            content.body = [NSString localizedUserNotificationStringForKey:notificationText arguments:nil];
            content.userInfo = metadata;
            content.categoryIdentifier = categoryIdentifier;

            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:nil];
            [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
                if (error) {
                    [[RadarLogger sharedInstance]
                     logWithLevel:RadarLogLevelDebug
                     message:[NSString stringWithFormat:@"Error adding local notification | identifier = %@; error = %@", request.identifier, error]];
                } else {
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                       message:[NSString stringWithFormat:@"Added local notification | identifier = %@", request.identifier]];
                }
            }];
        }
    }
}

+ (void)showDidReceiveSilentPushNotification {
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.body = @"Received silent push; calling startTracking() continuous";
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString] content:content trigger:nil];
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
    }];
}

@end
