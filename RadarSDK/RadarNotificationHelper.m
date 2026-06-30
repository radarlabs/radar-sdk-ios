//
//  RadarNotificationHelper.m
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>
#import <CoreLocation/CoreLocation.h>

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

+ (BOOL)isNotificationActiveForMetadata:(NSDictionary *)metadata now:(NSDate *)now {
    // No (or non-dictionary) metadata means no scheduling constraint, so the notification is
    // active — the same fail-open default as the absent-value cases below and the Swift path's
    // isActiveOnDayOfWeek. Callers (e.g. RadarLocationManager) already guard against nil.
    if (![metadata isKindOfClass:[NSDictionary class]]) {
        return YES;
    }

    // "yyyy-MM-dd'T'HH:mm:ss.SSS" is 23 chars; prefix to this length strips any trailing timezone suffix so the string is parsed as wall-clock local time
    static const NSUInteger kSchedulingWindowDatePrefixLength = 23;
    static NSDateFormatter *windowFormatter;
    static dispatch_once_t windowFormatterOnce;
    dispatch_once(&windowFormatterOnce, ^{
        windowFormatter = [[NSDateFormatter alloc] init];
        windowFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        windowFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
    });

    NSString *startsAtString = [metadata objectForKey:@"radar:startsAt"];
    // Window is [startsAt, endsAt]: skip when now is before the window opens
    if ([startsAtString isKindOfClass:[NSString class]] && startsAtString.length >= kSchedulingWindowDatePrefixLength) {
        NSDate *startsAt = [windowFormatter dateFromString:[startsAtString substringToIndex:kSchedulingWindowDatePrefixLength]];
        if (startsAt && [now compare:startsAt] == NSOrderedAscending) {
            return NO;
        }
    }
    NSString *endsAtString = [metadata objectForKey:@"radar:endsAt"];
    // Window is [startsAt, endsAt]: skip when now is strictly past the end (end is inclusive)
    if ([endsAtString isKindOfClass:[NSString class]] && endsAtString.length >= kSchedulingWindowDatePrefixLength) {
        NSDate *endsAt = [windowFormatter dateFromString:[endsAtString substringToIndex:kSchedulingWindowDatePrefixLength]];
        if (endsAt && [now compare:endsAt] == NSOrderedDescending) {
            return NO;
        }
    }

    // `radar:daysOfWeek` is a comma-separated list of day abbreviations ("Sun"…"Sat"); skip when
    // today (device-local) is not listed. An absent or empty value means every day of the week.
    NSString *daysOfWeekString = [metadata objectForKey:@"radar:daysOfWeek"];
    if ([daysOfWeekString isKindOfClass:[NSString class]] && daysOfWeekString.length > 0) {
        static NSArray<NSString *> *daysOfWeekAbbr;
        static dispatch_once_t daysOfWeekAbbrOnce;
        dispatch_once(&daysOfWeekAbbrOnce, ^{
            daysOfWeekAbbr = @[ @"sun", @"mon", @"tue", @"wed", @"thu", @"fri", @"sat" ];
        });
        NSMutableSet<NSString *> *allowedDays = [NSMutableSet set];
        for (NSString *day in [daysOfWeekString componentsSeparatedByString:@","]) {
            NSString *trimmed = [[day stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
            if (trimmed.length > 0) {
                [allowedDays addObject:trimmed];
            }
        }
        NSInteger weekdayIndex = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] component:NSCalendarUnitWeekday fromDate:now] - 1;
        NSString *today = (weekdayIndex >= 0 && weekdayIndex < (NSInteger)daysOfWeekAbbr.count) ? daysOfWeekAbbr[weekdayIndex] : nil;
        if (today && allowedDays.count > 0 && ![allowedDays containsObject:today]) {
            return NO;
        }
    }

    return YES;
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
        } else if (event.type == RadarEventTypeUserExitedBeacon && event.beacon && event.beacon.metadata) {
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

+ (void)swizzleDelegate:(id)delegate
                 method:(SEL) originalSelector
                withNew:(SEL) swizzledSelector {
    if (!delegate) {
        return;
    }
    Class class = [delegate class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
    
    if (!swizzledMethod) {
        return;
    }
    
    // if there was no original implementation, we just set our method as the original
    if (!originalMethod) {
        class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        return;
    }
    
    BOOL didAddMethod = class_addMethod(class, swizzledSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    }
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

+ (void)swizzleNotificationCenterDelegate {
    id<UNUserNotificationCenterDelegate> delegate = UNUserNotificationCenter.currentNotificationCenter.delegate;
    
    [self swizzleDelegate:delegate
                   method:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
                  withNew:@selector(swizzled_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)];
}

+ (void)swizzleApplicationDelegate {
    id<UIApplicationDelegate> applicationDelegate = UIApplication.sharedApplication.delegate;
    
    [self swizzleDelegate:applicationDelegate
                   method:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)
                  withNew:@selector(swizzled_application:didReceiveRemoteNotification:fetchCompletionHandler:)];
    
    [self swizzleDelegate:applicationDelegate
                   method:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)
                  withNew:@selector(swizzled_application:didRegisterForRemoteNotificationsWithDeviceToken:)];
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
    if ([self respondsToSelector:@selector(swizzled_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
        [self swizzled_userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    } else {
        completionHandler();
    }
}

- (void)swizzled_application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
      fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    // dispatch group so that Radar.didReceivePushNotificationPayload and any swizzled delegate method runs at the same time.
    dispatch_group_t group = dispatch_group_create();
    __block UIBackgroundFetchResult finalResult = UIBackgroundFetchResultNewData;
    
    RadarInitializeOptions *options = [RadarSettings initializeOptions];
    
    // Process the remote notification if silentPush is enabled.
    if (options.silentPush) {
        dispatch_group_enter(group);
        [Radar didReceivePushNotificationPayload:userInfo completionHandler:^() {
            dispatch_group_leave(group);
        }];
    }
    
    // Call the original method and use its result if available, otherwise we fallback to the finalResult's initial value above
    if ([self respondsToSelector:@selector(swizzled_application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
        dispatch_group_enter(group);
        [self swizzled_application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
            finalResult = result;
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        completionHandler(finalResult);
    });
}

- (void)swizzled_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // save device token
    if (deviceToken != nil){
        const unsigned char* bytes = (const unsigned char*)[deviceToken bytes];
        NSMutableString *hexString = [NSMutableString stringWithCapacity:[deviceToken length] * 2];
        
        for (NSUInteger i = 0; i < [deviceToken length]; ++i) {
            [hexString appendFormat:@"%02x", bytes[i]];
        }
        [RadarSettings setPushNotificationToken:hexString];
    }
    
    if ([self respondsToSelector:@selector(swizzled_application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
        [self swizzled_application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
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

// A stable identity for a notification used to diff desired vs. already-pending requests. Covers
// everything that determines whether re-adding would change behavior — identifier, content, and the
// location trigger's region — but deliberately excludes userInfo (its registeredAt is stamped fresh
// on every build, so including it would make every request look changed and defeat the diff).
+ (NSString *)notificationUniqueIdentifierForRequest:(UNNotificationRequest *)request {
    UNNotificationContent *content = request.content;
    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithObjects:request.identifier ?: @"", content.title ?: @"", content.subtitle ?: @"", content.body ?: @"", nil];
    if ([request.trigger isKindOfClass:[UNLocationNotificationTrigger class]]) {
        UNLocationNotificationTrigger *trigger = (UNLocationNotificationTrigger *)request.trigger;
        if ([trigger.region isKindOfClass:[CLCircularRegion class]]) {
            CLCircularRegion *region = (CLCircularRegion *)trigger.region;
            [parts addObject:[NSString stringWithFormat:@"%.6f,%.6f,%.2f", region.center.latitude, region.center.longitude, region.radius]];
            [parts addObject:region.notifyOnEntry ? @"1" : @"0"];
            [parts addObject:region.notifyOnExit ? @"1" : @"0"];
            [parts addObject:trigger.repeats ? @"1" : @"0"];
        }
    }
    return [parts componentsJoinedByString:@"|"];
}

// IMPORTANT: All campaigns request must have the same identifier prefix or frequency capping will be wrong
+ (void) updateClientSideCampaignsWithPrefix:(NSString *)prefix notificationRequests:(NSArray<UNNotificationRequest *> *)requests {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(notificationSemaphore, DISPATCH_TIME_FOREVER);
        UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
        [notificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *_Nonnull pending) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Found %lu pending notifications", (unsigned long)pending.count]];

            // Diff against the currently-pending notifications instead of removing all prefixed ones
            // and re-adding. updateClientSideCampaigns runs on every track (replaceSyncedGeofences)
            // and re-builds the same requests; re-adding an unchanged UNLocationNotificationTrigger
            // re-arms it, and iOS will not fire an entry for a trigger scheduled while the device is
            // already inside the region. Leaving unchanged triggers in place preserves their arm
            // point so an in-progress geofence entry still fires.
            NSMutableSet<NSString *> *desiredUniqueIdentifiers = [NSMutableSet new];
            for (UNNotificationRequest *request in requests) {
                [desiredUniqueIdentifiers addObject:[self notificationUniqueIdentifierForRequest:request]];
            }

            NSMutableSet<NSString *> *existingUniqueIdentifiers = [NSMutableSet new];
            NSMutableArray *identifiersToRemove = [NSMutableArray new];
            NSMutableArray *userInfosToKeep = [NSMutableArray new];
            for (UNNotificationRequest *request in pending) {
                if ([request.identifier hasPrefix:prefix]) {
                    NSString *uniqueIdentifier = [self notificationUniqueIdentifierForRequest:request];
                    if ([desiredUniqueIdentifiers containsObject:uniqueIdentifier]) {
                        // Unchanged: leave it armed and keep it registered.
                        [existingUniqueIdentifiers addObject:uniqueIdentifier];
                        if (request.content.userInfo) {
                            [userInfosToKeep addObject:request.content.userInfo];
                        }
                    } else {
                        [identifiersToRemove addObject:request.identifier];
                    }
                } else if (request.content.userInfo) {
                    [userInfosToKeep addObject:request.content.userInfo];
                }
            }
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Found %lu pending notifications to remove", (unsigned long)identifiersToRemove.count]];
            [RadarState setRegisteredNotifications:userInfosToKeep];
            if (identifiersToRemove.count > 0) {
                [notificationCenter removePendingNotificationRequestsWithIdentifiers:identifiersToRemove];
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Removed pending notifications"];
            }

            // Add only requests that aren't already pending unchanged, so triggers we left in place
            // keep their arm point.
            NSMutableArray<UNNotificationRequest *> *requestsToAdd = [NSMutableArray new];
            for (UNNotificationRequest *request in requests) {
                if (![existingUniqueIdentifiers containsObject:[self notificationUniqueIdentifierForRequest:request]]) {
                    [requestsToAdd addObject:request];
                }
            }
            [self addOnPremiseNotificationRequests:requestsToAdd];
        }];
    });
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
    
    if ([RadarSettings sdkConfiguration].useNotificationDiffV2) {
        [[RadarNotificationHelper_Swift shared] getDeliveredNotificationsWithCompletionHandler:^(NSArray* notificationsDelivered) {
            completionHandler(notificationsDelivered, @[]);
        }];
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
