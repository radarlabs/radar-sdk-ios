//
//  RadarState.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarState : NSObject

+ (CLLocation *)lastLocation;
+ (void)setLastLocation:(CLLocation *_Nullable)lastLocation;
+ (CLLocation *)lastMovedLocation;
+ (void)setLastMovedLocation:(CLLocation *_Nullable)lastMovedLocation;
+ (NSDate *)lastMovedAt;
+ (void)setLastMovedAt:(NSDate *)lastMovedAt;
+ (BOOL)stopped;
+ (void)setStopped:(BOOL)stopped;
+ (void)updateLastSentAt;
+ (NSDate *)lastSentAt;
+ (BOOL)canExit;
+ (void)setCanExit:(BOOL)canExit;
+ (CLLocation *)lastFailedStoppedLocation;
+ (void)setLastFailedStoppedLocation:(CLLocation *_Nullable)lastFailedStoppedLocation;
+ (NSArray<NSString *> *)geofenceIds;
+ (void)setGeofenceIds:(NSArray<NSString *> *_Nullable)geofenceIds;
+ (NSArray<NSString *> *)placeId;
+ (void)setPlaceId:(NSString *_Nullable)placeId;
+ (NSArray<NSString *> *)regionIds;
+ (void)setRegionIds:(NSArray<NSString *> *_Nullable)regionIds;
+ (NSArray<NSString *> *)beaconIds;
+ (void)setBeaconIds:(NSArray<NSString *> *_Nullable)beaconIds;
+ (NSArray<UNNotificationRequest *> *)pendingNotificationRequests;
+ (void)addPendingNotificationRequest:(UNNotificationRequest *)request;
+ (void)clearPendingNotificationRequests;
+ (BOOL)hasPendingNotificationRequest:(UNNotificationRequest *)request;
+ (void)removePendingNotificationRequest:(UNNotificationRequest *)request;
+ (BOOL)notificationSentInBackground;
+ (void)setNotificationSentInBackground:(BOOL)notificationSentInBackground;

@end

NS_ASSUME_NONNULL_END
