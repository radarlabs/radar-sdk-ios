//
//  RadarNotificationHelper.h
//  RadarSDK
//
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarNotificationHelper_Swift : NSObject
+ (RadarNotificationHelper_Swift*) shared;
- (void)registerGeofenceNotificationsWithGeofences:(NSArray<NSDictionary<NSString *, id> *> * _Nullable)geofences completionHandler:(void (^ _Nonnull)(void))completionHandler;
- (void)getDeliveredNotificationsWithCompletionHandler:(void (^ _Nonnull)(NSArray<NSDictionary<NSString *, id> *> * _Nonnull))completionHandler;
- (void)removeRegisteredNotificationsWithNotifications:(NSArray<NSDictionary<NSString *, id> *> * _Nullable)notifications completionHandler:(void (^ _Nonnull)(void))completionHandler;
- (void)refreshGeofenceNotificationsWithCompletionHandler:(void (^ _Nonnull)(void))completionHandler;
@end

NS_ASSUME_NONNULL_END
