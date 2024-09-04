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

    NSDate *lastCheckedTime = [RadarState lastCheckedOnPremiseNotification];
    if ([response.notification.request.identifier hasPrefix:@"radar_"]) {
        [[RadarLogger sharedInstance]
                        logWithLevel:RadarLogLevelDebug
                            message:[NSString stringWithFormat:@"Getting conversion from notification tap"]];
        [Radar logConversionWithNotification:response.notification.request eventName:@"opened_app" conversionSource:@"radar_notification" deliveredAfter:lastCheckedTime];
    } else {
        [Radar logConversionWithNotification:response.notification.request eventName:@"opened_app" conversionSource:@"notification" deliveredAfter:lastCheckedTime];
    }
    [RadarSettings updateLastAppOpenTime];

    if ([RadarUtils foreground]) {
        [RadarNotificationHelper checkForSentOnPremiseNotifications];
        [RadarState removePendingNotificationRequest:response.notification.request];
    } 
    // Call the original method (which is now swizzled)
    [self swizzled_userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}

+ (void)checkForSentOnPremiseNotifications {
    NSArray<UNNotificationRequest *> *registeredNotifications = [RadarState pendingNotificationRequests];
    if (NSClassFromString(@"XCTestCase") == nil) {
        [[UNUserNotificationCenter currentNotificationCenter] getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *_Nonnull requests) {
            NSMutableSet *pendingIdentifiers = [NSMutableSet new];
                
            for (UNNotificationRequest *request in requests) {
                [pendingIdentifiers addObject:request.identifier];
            }
                
            for (UNNotificationRequest *request in registeredNotifications) {
                if (![pendingIdentifiers containsObject:request.identifier]) {
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"Found sent notification, creating converison | identifier = %@", request]];
                    NSDate *lastCheckedTime = [RadarState lastCheckedOnPremiseNotification];
                    [Radar logConversionWithNotification:request eventName:@"delivered_on_premise_notification" conversionSource:nil deliveredAfter:lastCheckedTime];
                    // prevent double counting of the same notification
                    [RadarState removePendingNotificationRequest:request];
                }
            }            
        }];
    }
    [RadarState lastCheckedOnPremiseNotification];
}

+ (void)removePendingNotificationsWithCompletionHandler:(void (^)(void))completionHandler {
    UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [notificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *_Nonnull requests) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Found %lu pending notifications", (unsigned long)requests.count]];
        NSMutableArray *identifiers = [NSMutableArray new];
        for (UNNotificationRequest *request in requests) {
            if ([request.identifier hasPrefix:kSyncGeofenceIdentifierPrefix]) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"Found pending notification | identifier = %@", request.identifier]];
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

    [RadarNotificationHelper checkNotificationPermissionsWithCompletion:^(BOOL granted) {
        if (granted) {
            UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
            for (UNNotificationRequest *request in requests) {
                [notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
                    if (error) {
                        [[RadarLogger sharedInstance]
                            logWithLevel:RadarLogLevelInfo
                                message:[NSString stringWithFormat:@"Error adding local notification | identifier = %@; error = %@", request.identifier, error]];
                    } else {
                        [RadarState addPendingNotificationRequest:request];
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
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

+ (void)registerBackgroundNotificationChecks {
    NSURL *webhookURL = [NSURL URLWithString:@"https://webhook.site/76c1a57d-e047-4c96-8ee2-307de5d49376/bginit"];
    [self sendGetRequestToWebhookURL:webhookURL];
    if (@available(iOS 13.0, *)) {
        [[BGTaskScheduler sharedScheduler] registerForTaskWithIdentifier:@"io.radar.notificationCheck" usingQueue:nil launchHandler:^(BGTask *task) {
            [self handleAppRefreshTask:task];
        }];
    }
}

+ (void)scheduleBackgroundNotificationChecks {
    if (@available(iOS 13.0, *)) {
        BGAppRefreshTaskRequest *request = [[BGAppRefreshTaskRequest alloc] initWithIdentifier:@"io.radar.notificationCheck"];
        request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:60*60];
        NSError *error = nil;
        
        [[BGTaskScheduler sharedScheduler] submitTaskRequest:request error:&error];
        if (error) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"Error scheduling app refresh task: %@", error]];
        }
    }
}

+ (void)sendGetRequestToWebhookURL:(NSURL *)url {
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];

    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"Error sending GET request to webhook URL: %@", error]];
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"Successfully sent GET request to webhook URL."];
            } else {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"Failed to send GET request to webhook URL. Status code: %ld", (long)httpResponse.statusCode]];
            }
        }
    }];

    [dataTask resume];
}

+ (void)handleAppRefreshTask:(BGTask *)task  API_AVAILABLE(ios(13.0)){
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"Performing background task of checking for notification sent"]];
    [self scheduleBackgroundNotificationChecks];
    [self checkForSentOnPremiseNotifications];
    NSURL *webhookURL = [NSURL URLWithString:@"https://webhook.site/76c1a57d-e047-4c96-8ee2-307de5d49376/bgtask"];
    [self sendGetRequestToWebhookURL:webhookURL];
    [task setTaskCompletedWithSuccess:YES];
}

+ (void)checkNotificationPermissionsWithCompletion:(NotificationPermissionCheckCompletion)completion {
    UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    [notificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        BOOL granted = (settings.authorizationStatus == UNAuthorizationStatusAuthorized);
        [RadarState setNotificationPermissionGranted:granted];
        if (!granted) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Notification permissions not granted."];
        }
        if (completion) {
            completion(granted);
        }
    }];
}

@end
