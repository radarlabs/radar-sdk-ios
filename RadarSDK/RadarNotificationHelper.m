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
static dispatch_semaphore_t notificationSemaphore;

+ (void)initialize {
    if (self == [RadarNotificationHelper class]) {
        notificationSemaphore = dispatch_semaphore_create(1);
    }
}

+ (void)showNotificationsForEvents:(NSArray<RadarEvent *> *)events {
    if (!events || !events.count) {
        return;
    }
    
    for (RadarEvent *event in events) {
        NSString *identifier = [NSString stringWithFormat:@"%@%@", kEventNotificationIdentifierPrefix, event._id];
        NSString *categoryIdentifier = [RadarEvent stringForType:event.type];
        UNMutableNotificationContent *content = [RadarNotificationHelper extractContentFromMetadata:event.metadata identifier:identifier];
        if (content) {
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
            continue;
        }

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

+ (UNMutableNotificationContent *)extractContentFromMetadata:(NSDictionary *)metadata identifier:(NSString *)identifier {
    
    if (!metadata) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError
                                                       message:[NSString stringWithFormat:@"No metadata found for identifier = %@", identifier]];
        return nil;
    }

    NSString *notificationText = [metadata objectForKey:@"radar:notificationText"];
    NSString *notificationTitle = [metadata objectForKey:@"radar:notificationTitle"];
    NSString *notificationSubtitle = [metadata objectForKey:@"radar:notificationSubtitle"];
    NSString *notificationURL = [metadata objectForKey:@"radar:notificationURL"];
    NSString *campaignId = [metadata objectForKey:@"radar:campaignId"];
    NSString *campaignMetadata = [metadata objectForKey:@"radar:campaignMetadata"];

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

// IMPORTANT: All campaigns request must have the same identifier prefix or frequency capping will be wrong
+ (void) updateClientSideCampaignsWithPrefix:(NSString *)prefix notificationRequests:(NSArray<UNNotificationRequest *> *)requests {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(notificationSemaphore, DISPATCH_TIME_FOREVER);
        [self removePendingNotificationsWithPrefix:prefix completionHandler:^{
            [self addOnPremiseNotificationRequests:requests];
        }];
    });
}

+ (void)removePendingNotificationsWithPrefix:(NSString *)prefix completionHandler:(void (^)(void))completionHandler {
    UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [notificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *_Nonnull requests) {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Found %lu pending notifications", (unsigned long)requests.count]];
        NSMutableArray *identifiersToRemove = [NSMutableArray new];
        NSMutableArray *userInfosToKeep = [NSMutableArray new];
        for (UNNotificationRequest *request in requests) {
            if ([request.identifier hasPrefix:prefix]) {
                [identifiersToRemove addObject:request.identifier];
            } else {
                [userInfosToKeep addObject:request.content.userInfo];
            }
        }
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Found %lu pending notifications to remove", (unsigned long)identifiersToRemove.count]];        
        [RadarState setRegisteredNotifications:userInfosToKeep];
        if (identifiersToRemove.count > 0) {
            [notificationCenter removePendingNotificationRequestsWithIdentifiers:identifiersToRemove];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Removed pending notifications"];
        }

        completionHandler();
    }];

}

+ (void)addOnPremiseNotificationRequests:(NSArray<UNNotificationRequest *> *)requests {
    [RadarNotificationHelper checkNotificationPermissionsWithCompletionHandler:^(BOOL granted) {
        if (granted) {
            UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
            dispatch_group_t group = dispatch_group_create();
            
            for (UNNotificationRequest *request in requests) {
                dispatch_group_enter(group);
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
                    dispatch_group_leave(group);
                }];
            }
            
            dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_semaphore_signal(notificationSemaphore);
            });
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Notification permissions not granted. Skipping adding notifications."];
            dispatch_semaphore_signal(notificationSemaphore);
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
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Found pending registered notification | userInfo = %@", request.content.userInfo]];
            }
        }
        
        NSMutableArray *notificationsDelivered = [NSMutableArray arrayWithArray:registeredNotifications];

        [notificationsDelivered removeObjectsInArray:currentNotifications];

        if (completionHandler) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Setting %lu notifications remaining after re-registering", (unsigned long)notificationsDelivered.count]];
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

+ (BOOL)isNotificationCampaign:(NSDictionary *)metadata {
    return [metadata objectForKey:@"radar:campaignType"] != nil && ([[metadata objectForKey:@"radar:campaignType"] isEqual:@"clientSide"] || [[metadata objectForKey:@"radar:campaignType"] isEqual:@"eventBased"]);
}

@end
