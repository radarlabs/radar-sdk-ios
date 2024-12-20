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
#import "RadarSettings.h"
#import "RadarUtils.h"
#import <BackgroundTasks/BackgroundTasks.h>
#import "Radar+Internal.h"
#import <objc/runtime.h>

@implementation RadarNotificationHelper

static NSString *const kEventNotificationIdentifierPrefix = @"radar_event_notification_";
static NSString *const kSyncGeofenceIdentifierPrefix = @"radar_geofence_";

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

+ (void)swizzleNotificationCenterDelegate {
    id<UNUserNotificationCenterDelegate> delegate = UNUserNotificationCenter.currentNotificationCenter.delegate;
    if (!delegate) {
        NSLog(@"Error: UNUserNotificationCenter delegate is nil.");
        return;
    }
    Class class = [UNUserNotificationCenter.currentNotificationCenter.delegate class];
    SEL originalSelector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
    SEL swizzledSelector = @selector(swizzled_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);

    if (originalMethod && swizzledMethod) {
        BOOL didAddMethod = class_addMethod(class,
                                            swizzledSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            Method newSwizzledMethod = class_getInstanceMethod(class, swizzledSelector);
            method_exchangeImplementations(originalMethod, newSwizzledMethod);
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    } else {
        NSLog(@"Error: Methods not found for swizzling.");
    }
}

- (void)swizzled_userNotificationCenter:(UNUserNotificationCenter *)center
        didReceiveNotificationResponse:(UNNotificationResponse *)response
                 withCompletionHandler:(void (^)(void))completionHandler {

    RadarInitializeOptions *options = [RadarSettings initializeOptions];
    if (options.autoHandleNotificationDeepLinks) {
        [RadarNotificationHelper openURLFromNotification:response.notification];
    }
    if (options.autoLogNotificationConversions) {
        [RadarNotificationHelper logConversionWithNotificationResponse:response];
    }

    // Call the original method (which is now swizzled)
    [self swizzled_userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}

+ (void)openURLFromNotification:(UNNotification *)notification {

    if ([notification.request.identifier hasPrefix:@"radar_"]) {
        NSString *urlString = notification.request.content.userInfo[@"url"];
        if (urlString) {
            NSURL *url = [NSURL URLWithString:urlString];
            if (url) {
                UIApplication *application = [UIApplication sharedApplication];
                if ([application canOpenURL:url]) {
                   [application openURL:url options:@{} completionHandler:nil];
               }
            }
        }
    } 
}

+ (void)logConversionWithNotificationResponse:(UNNotificationResponse *)response {
    if ([RadarSettings useOpenedAppConversion]) {
        [RadarSettings updateLastAppOpenTime];
        
        if ([response.notification.request.identifier hasPrefix:@"radar_"]) {
            [[RadarLogger sharedInstance]
                            logWithLevel:RadarLogLevelDebug
                                message:[NSString stringWithFormat:@"Getting conversion from notification tap"]];
            [Radar logOpenedAppConversionWithNotification:response.notification.request conversionSource:@"radar_notification"];
        } else {
            [Radar logOpenedAppConversionWithNotification:response.notification.request conversionSource:@"notification"];
        }
    }
}

+ (void)removePendingNotificationsWithCompletionHandler:(void (^)(void))completionHandler {
    UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [notificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *_Nonnull requests) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Found %lu pending notifications", (unsigned long)requests.count]];
        NSMutableArray *identifiers = [NSMutableArray new];
        for (UNNotificationRequest *request in requests) {
            if ([request.identifier hasPrefix:kSyncGeofenceIdentifierPrefix]) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Found pending notification to remove | identifier = %@", request.identifier]];
                [identifiers addObject:request.identifier];
            }
        }

        if (identifiers.count > 0) {
            [notificationCenter removePendingNotificationRequestsWithIdentifiers:identifiers];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Removed pending notifications"];
        }

        completionHandler();
    }];
}

+ (void)addOnPremiseNotificationRequests:(NSArray<UNNotificationRequest *> *)requests {
    [RadarNotificationHelper checkNotificationPermissionsWithCompletionHandler:^(BOOL granted) {
        if (granted) {
            UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
            [RadarState setRegisteredNotifications: [NSArray new]];
            for (UNNotificationRequest *request in requests) {
                [notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
                    if (error) {
                        [[RadarLogger sharedInstance]
                            logWithLevel:RadarLogLevelError
                                message:[NSString stringWithFormat:@"Error adding local notification | identifier = %@; error = %@", request.identifier, error]];
                    } else {
                        NSDictionary *userInfo = request.content.userInfo;
                        if (userInfo) {
                            [RadarState addRegisteredNotification:userInfo];
                        }

                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                        message:[NSString stringWithFormat:@"Added local notification | identifier = %@", request.identifier]];
                    }
                }];
            }
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Notification permissions not granted. Skipping adding notifications."];
            return;
        }
    }];
}

+ (void)getNotificationDiffWithCompletionHandler:(void (^)(NSArray *notificationsDelivered, NSArray *notificationsRemaining))completionHandler {
    if (NSClassFromString(@"XCTestCase") != nil) {
        if (completionHandler) {
            completionHandler(@[], @[]);
        }
        return;
    }
    UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    NSArray *registeredNotifications = [RadarState registeredNotifications];
    
    [notificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
        NSMutableArray *currentNotifications = [NSMutableArray new];
        
        for (UNNotificationRequest *request in requests) {
            if (request.content.userInfo) {
                [currentNotifications addObject:request.content.userInfo];
            }
        }
        
        NSMutableArray *notificationsDelivered = [NSMutableArray arrayWithArray:registeredNotifications];
        [notificationsDelivered removeObjectsInArray:currentNotifications];
        
        if (completionHandler) {
            completionHandler(notificationsDelivered, currentNotifications);
        }
    }];
}

+ (void)checkNotificationPermissionsWithCompletionHandler:(NotificationPermissionCheckCompletion)completionHandler {
    if (NSClassFromString(@"XCTestCase") == nil) {
        UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
        [notificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
            BOOL granted = (settings.authorizationStatus == UNAuthorizationStatusAuthorized);
            [RadarState setNotificationPermissionGranted:granted];
            if (!granted) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Notification permissions not granted."];
            }
            if (completionHandler) {
                completionHandler(granted);
            }
        }];
    } else {
        if (completionHandler) {
            completionHandler(NO);
        }
    } 
}

@end
