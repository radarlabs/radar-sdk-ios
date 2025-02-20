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

+ (instancetype _Nonnull )sharedInstance;
- (void)startActivityUpdatesWithHandler:(void (^_Nullable)(CMMotionActivity * _Nonnull activity))handler;
- (void)stopActivityUpdates;
- (void)startRelativeAltitudeWithHandler:(void (^_Nullable)(CMAltitudeData * _Nullable altitudeData))handler;
- (void)stopRelativeAltitudeUpdates;

@end
