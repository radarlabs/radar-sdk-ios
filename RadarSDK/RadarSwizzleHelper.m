//
//  RadarSwizzleHelper.m
//  RadarSDK
//
//  Created by Alan Charles on 7/21/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarSwizzleHelper.h"
#import <RadarSDK/RadarSDK-Swift.h>
#import "RadarSettings.h"
#import "RadarLogger.h"
#import "Radar+Internal.h"

@implementation RadarSwizzleHelper

- (void)swizzled_userNotificationCenter:(UNUserNotificationCenter *)center
       didReceiveNotificationResponse:(UNNotificationResponse *)response
                withCompletionHandler:(void (^)(void))completionHandler {

    RadarInitializeOptions *options = [RadarSettings initializeOptions];

    if (options.autoHandleNotificationDeepLinks) {
        [RadarNotificationSwizzling openURLFromNotification:response.notification];
    }
    if (options.autoLogNotificationConversions) {
        [Radar logConversionWithNotificationResponse:response];
    }

    if ([self respondsToSelector:@selector(swizzled_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
        [self swizzled_userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    } else {
        completionHandler();
    }
}

- (void)swizzled_application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
      fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {

    dispatch_group_t group = dispatch_group_create();
    __block UIBackgroundFetchResult finalResult = UIBackgroundFetchResultNewData;

    RadarInitializeOptions *options = [RadarSettings initializeOptions];

    if (options.silentPush) {
        dispatch_group_enter(group);
        [Radar didReceivePushNotificationPayload:userInfo completionHandler:^{
            dispatch_group_leave(group);
        }];
    }

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

- (void)swizzled_application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    const unsigned char *bytes = (const unsigned char *)[deviceToken bytes];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:[deviceToken length] * 2];
    for (NSUInteger i = 0; i < [deviceToken length]; ++i) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    [RadarSettings setPushNotificationToken:hexString];

    if ([self respondsToSelector:@selector(swizzled_application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
        [self swizzled_application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

@end
