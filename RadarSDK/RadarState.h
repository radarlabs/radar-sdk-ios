//
//  RadarState.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "RadarGeofence+Internal.h"

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
+ (NSDictionary *)lastHeadingData;
+ (void)setLastHeadingData:(NSDictionary *_Nullable)lastHeadingData;
+ (NSDictionary *)lastMotionActivityData;
+ (void)setLastMotionActivityData:(NSDictionary *_Nullable)lastMotionActivityData;
+ (void)setNotificationPermissionGranted:(BOOL)granted;
+ (BOOL)notificationPermissionGranted;
+ (NSArray<NSDictionary *> *_Nullable)registeredNotifications;
+ (void)setRegisteredNotifications:(NSArray<NSDictionary *> *_Nullable)registeredNotifications;
+ (void)addRegisteredNotification:(NSDictionary *)registeredNotification;
+ (NSDictionary *)lastRelativeAltitudeData;
+ (void)setLastRelativeAltitudeData:(NSDictionary *_Nullable)lastRelativeAltitudeData;
+ (NSArray<RadarGeofence*>*)getNearbyGeofences;
+ (void)setNearbyGeofences:(NSArray<RadarGeofence*>*)geofences;

@end

NS_ASSUME_NONNULL_END
