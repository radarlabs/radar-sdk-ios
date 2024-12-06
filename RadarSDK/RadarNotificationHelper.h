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

+ (void)removePendingNotificationsWithCompletionHandler:(void (^)(void))completionHandler;

+ (void)addOnPremiseNotificationRequests:(NSArray<UNNotificationRequest *> *)requests;

+ (void)checkNotificationPermissionsWithCompletionHandler:(nullable NotificationPermissionCheckCompletion)completionHandler;

+ (void)logConversionWithNotificationResponse:(UNNotificationResponse *)response;

+ (void)openURLFromNotification:(UNNotification *)notification;

+ (NSString *)getNotificationIdentifier:(NSString *)geofenceId campaignName:(NSString *)campaignName;

+ (NSDictionary<NSString *, NSString *> *)extractMetadataFromNotificationIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
