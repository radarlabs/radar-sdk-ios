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
- (void)startRelativeAltitudeUpdatesToQueue:(NSOperationQueue *) queue
                                 withHandler:(CMAltitudeHandler) handler;
- (void)stopRelativeAltitudeUpdates;
- (void)startAbsoluteAltitudeUpdatesToQueue:(NSOperationQueue *) queue
                                 withHandler:(CMAltitudeHandler) handler;
- (void)stopAbsoluteAltitudeUpdates;

- (void)startAccelerometerUpdatesToQueue:(NSOperationQueue *) queue
                              withHandler:(CMAccelerometerHandler) handler;

- (void)stopAccelerometerUpdates;
- (void)startMagnetometerUpdatesToQueue:(NSOperationQueue *) queue
                            withHandler:(CMMagnetometerHandler) handler;
- (void)stopMagnetometerUpdates;

@end

NS_ASSUME_NONNULL_END
