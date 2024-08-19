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
#import "RadarState.h"

@implementation RadarNotificationHelper

static NSString *const kEventNotificationIdentifierPrefix = @"radar_event_notification_";

+ (void)showNotificationsForEvents:(NSArray<RadarEvent *> *)events {
    if (!events || !events.count) {
        return;
    }
    
    for (RadarEvent *event in events) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                           message:@"got event to maybe create notifications with"];
        NSString *notificationText;
        NSDictionary *metadata;
        
        if (event.type == RadarEventTypeUserEnteredGeofence && event.geofence && event.geofence.metadata) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                               message:@"unpacking metadata"];
            metadata = event.geofence.metadata;
            // print out the metadata
            for (NSString *key in metadata) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                                   message:[NSString stringWithFormat:@"key: %@, value: %@", key, [metadata objectForKey:key]]];
            }
            notificationText = [metadata objectForKey:@"radar:entryNotificationText"];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                               message:notificationText];
        } else if (event.type == RadarEventTypeUserExitedGeofence && event.geofence && event.geofence.metadata) {
            metadata = event.geofence.metadata;
            notificationText = [metadata objectForKey:@"radar:exitNotificationText"];
            for (NSString *key in metadata) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                                   message:[NSString stringWithFormat:@"key: %@, value: %@", key, [metadata objectForKey:key]]];
            }
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
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                               message:@"adding notifications"];
            [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
                if (error) {
                    [[RadarLogger sharedInstance]
                     logWithLevel:RadarLogLevelDebug
                     message:[NSString stringWithFormat:@"Error adding local notification | identifier = %@; error = %@", request.identifier, error]];
                } else {
                    [RadarState addPendingNotificationIdentifier:request.identifier];
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                       message:[NSString stringWithFormat:@"Added local notification | identifier = %@", request.identifier]];
                }
            }];
        }
    }
}

@end
