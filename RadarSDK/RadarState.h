//
//  RadarState.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "RadarGeofence.h"

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
+ (NSArray<NSString *> *)geofenceIds NS_SWIFT_NAME(geofenceIds());
+ (void)setGeofenceIds:(NSArray<NSString *> *_Nullable)geofenceIds NS_SWIFT_NAME(setGeofenceIds(_:));
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
+ (void)setNearbyGeofences:(NSArray<RadarGeofence *> *_Nullable)nearbyGeofences NS_SWIFT_NAME(setNearbyGeofences(_:));
+ (NSArray<RadarGeofence *> *_Nullable)nearbyGeofences NS_SWIFT_NAME(nearbyGeofences());

@end

NS_ASSUME_NONNULL_END
