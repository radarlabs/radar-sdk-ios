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

+ (void)updateClientSideCampaignsWithPrefix:(NSString *)prefix notificationRequests:(NSArray<UNNotificationRequest *> *)requests;

+ (void)removeNotificationRequestsByIdentifiers:(NSArray<NSString*>*) identifiers;

+ (void)addOnPremiseNotificationRequests:(NSArray<UNNotificationRequest *> *)requests completionHandler:(void (^)(void))completionHandler;

+ (void)checkNotificationPermissionsWithCompletionHandler:(nullable NotificationPermissionCheckCompletion)completionHandler;

+ (void)logConversionWithNotificationResponse:(UNNotificationResponse *)response;

+ (void)openURLFromNotification:(UNNotification *)notification;

+ (nullable UNMutableNotificationContent *)extractContentFromMetadata:(nullable NSDictionary *)metadata identifier:(nullable NSString *)identifier;


+ (void)getNotificationDiffWithCompletionHandler:(void (^)(NSArray *notificationsDelivered, NSArray *notificationsRemaining))completionHandler;
@end

NS_ASSUME_NONNULL_END
