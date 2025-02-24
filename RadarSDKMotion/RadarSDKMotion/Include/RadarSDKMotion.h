//
//  RadarMotion.h
//  RadarMotion
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@interface RadarSDKMotion : NSObject
- (void)startActivityUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMMotionActivityHandler)handler;
- (void)stopActivityUpdates;
- (void)startRelativeAltitudeUpdatesToQueue:(NSOperationQueue *) queue
                                 withHandler:(CMAltitudeHandler) handler;
- (void)stopRelativeAltitudeUpdates;
- (void)startAbsoluteAltitudeUpdatesToQueue:(NSOperationQueue *) queue
                                withHandler:(CMAbsoluteAltitudeHandler) handler API_AVAILABLE(ios(15.0));
- (void)stopAbsoluteAltitudeUpdates;

- (void)startAccelerometerUpdatesToQueue:(NSOperationQueue *) queue
                              withHandler:(CMAccelerometerHandler) handler;

- (void)stopAccelerometerUpdates;
- (void)startMagnetometerUpdatesToQueue:(NSOperationQueue *) queue
                            withHandler:(CMMagnetometerHandler) handler;

- (void)stopMagnetometerUpdates;


@end


