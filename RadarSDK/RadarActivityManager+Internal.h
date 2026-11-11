//
//  RadarActivityManager+Internal.h
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <Foundation/Foundation.h>

#import "RadarMotionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

// Declares the internal Swift RadarActivityManager for Objective-C callers, since internal Swift
// classes are not emitted into RadarSDK-Swift.h. Call the start and stop methods on the main thread.
@interface RadarActivityManager : NSObject

@property (class, nonatomic, readonly) RadarActivityManager *sharedInstance;

@property (nullable, strong, nonatomic) id<RadarMotionProtocol> radarSDKMotion;

- (void)requestPermission;
- (void)startActivityUpdatesWithHandler:(void (^_Nullable)(CMMotionActivity *activity))handler;
- (void)stopActivityUpdates;
- (void)startRelativeAltitudeWithHandler:(void (^_Nullable)(CMAltitudeData *_Nullable altitudeData))handler;
- (void)stopRelativeAltitudeUpdates;
- (void)startAbsoluteAltitudeWithHandler:(void (^_Nullable)(CMAbsoluteAltitudeData *_Nullable altitudeData))handler;
- (void)stopAbsoluteAltitudeUpdates;

@end

NS_ASSUME_NONNULL_END
