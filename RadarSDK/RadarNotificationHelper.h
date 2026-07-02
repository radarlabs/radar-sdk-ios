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

+ (void)swizzleApplicationDelegate;

+ (void)updateClientSideCampaignsWithPrefix:(NSString *)prefix notificationRequests:(NSArray<UNNotificationRequest *> *)requests;

+ (void)checkNotificationPermissionsWithCompletionHandler:(nullable NotificationPermissionCheckCompletion)completionHandler;

+ (void)logConversionWithNotificationResponse:(UNNotificationResponse *)response;

+ (void)openURLFromNotification:(UNNotification *)notification;

+ (nullable UNMutableNotificationContent *)extractContentFromMetadata:(nullable NSDictionary *)metadata identifier:(nullable NSString *)identifier;

/// Returns whether a client-side notification carrying `metadata` should be scheduled at `now`:
/// within the optional `radar:startsAt`/`radar:endsAt` window (inclusive, parsed as wall-clock local
/// time) and active on the local day in `radar:daysOfWeek`. Absent/empty values mean "no constraint".
/// Used by the geofence notification path so the window + day-of-week evaluation stays in one place.
+ (BOOL)isNotificationActiveForMetadata:(nullable NSDictionary *)metadata now:(NSDate *)now;

+ (void)getNotificationDiffWithCompletionHandler:(void (^)(NSArray *notificationsDelivered, NSArray *notificationsRemaining))completionHandler;
@end

@interface RadarNotificationHelper_Swift : NSObject
+ (RadarNotificationHelper_Swift*) shared;
- (void)registerGeofenceNotificationsWithGeofences:(NSArray<NSDictionary<NSString *, id> *> * _Nullable)geofences completionHandler:(void (^ _Nonnull)(void))completionHandler;
- (void)getDeliveredNotificationsWithCompletionHandler:(void (^ _Nonnull)(NSArray<NSDictionary<NSString *, id> *> * _Nonnull))completionHandler;
- (void)removeRegisteredNotificationsWithNotifications:(NSArray<NSDictionary<NSString *, id> *> * _Nullable)notifications completionHandler:(void (^ _Nonnull)(void))completionHandler;
- (void)refreshGeofenceNotificationsWithCompletionHandler:(void (^ _Nonnull)(void))completionHandler;
@end

NS_ASSUME_NONNULL_END
