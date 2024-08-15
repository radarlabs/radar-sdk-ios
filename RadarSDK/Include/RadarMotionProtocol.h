//
//  RadarMotion.h
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RadarMotionProtocol<NSObject>

- (void)startActivityUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMMotionActivityHandler)handler;
- (void)stopActivityUpdates;

@end

NS_ASSUME_NONNULL_END
