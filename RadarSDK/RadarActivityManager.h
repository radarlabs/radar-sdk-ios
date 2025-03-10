//
// RadarActivityManager.h
// RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "RadarMotionProtocol.h"

@interface RadarActivityManager : NSObject

@property (nullable, strong, nonatomic) id radarSDKMotion;
@property (nonatomic, readonly) NSInteger MAX_BUFFER_SIZE;

+ (instancetype _Nonnull )sharedInstance;
- (void)requestPermission;
- (void)startActivityUpdatesWithHandler:(void (^_Nullable)(CMMotionActivity * _Nonnull activity))handler;
- (void)stopActivityUpdates;
- (void)startRelativeAltitudeWithHandler:(void (^_Nullable)(CMAltitudeData * _Nullable altitudeData))handler;
- (void)stopRelativeAltitudeUpdates;
- (void)startAbsoluteAltitudeWithHandler:(void (^_Nullable)(CMAbsoluteAltitudeData * _Nullable altitudeData))handler API_AVAILABLE(ios(15.0));
- (void)stopAbsoluteAltitudeUpdates;

@end
