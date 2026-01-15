//
//  RadarState.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <Foundation/Foundation.h>
#import "RadarGeofence.h"
#import "RadarUser+Internal.h"

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
+ (NSArray<RadarBeacon *> *_Nullable)nearbyBeacons NS_SWIFT_NAME(nearbyBeacons());
+ (void)setNearbyBeacons:(NSArray<RadarBeacon *> *_Nullable)nearbyBeacons NS_SWIFT_NAME(setNearbyBeacons(_:));
+ (void)setMotionAuthorization:(CMAuthorizationStatus)status;
+ (CMAuthorizationStatus)motionAuthorization;
+ (NSArray<NSDictionary *> *_Nullable)registeredNotifications;
+ (void)setRegisteredNotifications:(NSArray<NSDictionary *> *_Nullable)registeredNotifications;
+ (void)addRegisteredNotification:(NSDictionary *)registeredNotification;
+ (void)setRadarUser:(RadarUser *_Nullable)radarUser NS_SWIFT_NAME(setRadarUser(_:));
+ (RadarUser *_Nullable)radarUser NS_SWIFT_NAME(radarUser());
+ (CLCircularRegion *)syncedRegion;
+ (void)setSyncedRegion:(CLCircularRegion *_Nullable)syncedRegion;
+ (NSDictionary *)lastRelativeAltitudeData;
+ (void)setLastRelativeAltitudeData:(NSDictionary *_Nullable)lastRelativeAltitudeData;

@end

NS_ASSUME_NONNULL_END
