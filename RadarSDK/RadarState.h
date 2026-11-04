//
//  RadarState.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "RadarUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarState : NSObject

@property (class, nonatomic, readonly) RadarState *shared;

@property (nonatomic, strong, nullable) CLLocation *lastLocation;
@property (nonatomic, strong, nullable) CLLocation *lastMovedLocation;
@property (nonatomic, strong, nullable) NSDate *lastMovedAt;
@property (nonatomic, assign) BOOL stopped;
@property (nonatomic, strong, readonly, nullable) NSDate *lastSentAt;
@property (nonatomic, assign) BOOL canExit;
@property (nonatomic, strong, nullable) CLLocation *lastFailedStoppedLocation;
@property (nonatomic, copy, nullable) NSArray<NSString *> *geofenceIds;
@property (nonatomic, copy, nullable) NSString *placeId;
@property (nonatomic, copy, nullable) NSArray<NSString *> *regionIds;
@property (nonatomic, copy, nullable) NSArray<NSString *> *beaconIds;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSNumber *> *lastHeadingData;
@property (nonatomic, copy, nullable) NSDictionary *lastMotionActivityData;
@property (nonatomic, copy, nullable) NSDictionary *lastRelativeAltitudeData;
@property (nonatomic, assign) BOOL notificationPermissionGranted;
@property (nonatomic, copy, nullable) NSString *motionAuthorizationString;
@property (nonatomic, assign) CLAuthorizationStatus locationAuthorizationStatus;
@property (nonatomic, copy, nullable) NSArray<NSDictionary *> *registeredNotifications;
@property (nonatomic, copy, nullable) NSArray<NSDictionary *> *altitudeAdjustments;
@property (nonatomic, strong, nullable) RadarUser *radarUser;

- (void)updateLastSentAt;

@end

NS_ASSUME_NONNULL_END
