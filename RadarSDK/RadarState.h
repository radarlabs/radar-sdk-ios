//
//  RadarState.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarState : NSObject

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

+ (void)setDebugHandler:(RadarDebugHandler *_Nullable)debugHandler;
+ (void)callDebugHandler:(NSString *)status location:(CLLocation *_Nullable)location bubble:(CLRegion *_Nullable)bubble deviceGeofences:(NSArray<RadarGeofence *> *_Nullable)deviceGeofences events:(NSArray<RadarEvent *> *_Nullable)events user:(RadarUser *_Nullable)user geofences:(NSArray<RadarGeofence *> *_Nullable)geofences places:(NSArray<RadarPlace *> *_Nullable)places;

+ (void)setLastGeofences:(NSArray<RadarGeofence *> *_Nullable)geofences;
+ (NSArray<RadarGeofence *> *_Nullable)lastGeofences;
+ (void)setLastBubble:(CLRegion *_Nullable)region;
+ (CLRegion *_Nullable)lastBubble;

@end

NS_ASSUME_NONNULL_END
