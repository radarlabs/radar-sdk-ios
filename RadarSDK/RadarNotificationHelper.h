//
//  RadarNotificationHelper.h
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarNotificationHelper : NSObject

typedef void (^NotificationPermissionCheckCompletion)(BOOL granted);

+ (void)showNotificationsForEvents:(NSArray<RadarEvent *> *)events;

+ (void)swizzleNotificationCenterDelegate;

+ (void)checkForSentOnPremiseNotifications;

+ (void)removePendingNotificationsWithCompletionHandler:(void (^)(void))completionHandler;

+ (void)addOnPremiseNotificationRequests:(NSArray<UNNotificationRequest *> *)requests;

+ (void)registerBackgroundNotificationChecks;

+ (void)scheduleBackgroundNotificationChecks;

+ (void)checkNotificationPermissionsWithCompletion:(nullable NotificationPermissionCheckCompletion)completion;

@end

NS_ASSUME_NONNULL_END
