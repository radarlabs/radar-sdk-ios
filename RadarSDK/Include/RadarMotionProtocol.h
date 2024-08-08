//
//  RadarMotionProtocol.h
//  RadarSDK
//
//  Created by Kenny Hu on 8/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "Radar.h"


@protocol RadarMotionProtocol<NSObject>


- (void)stopActivityUpdates;
- (void)startActivityUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMMotionActivityHandler)handler;

- (void)startAccelerometerUpdates;
- (CMAccelerometerData *)getAccelerometerData;
- (void)stopAccelerometerUpdates;
- (void)startGyroUpdates;
- (CMGyroData *)getGyroData;
- (void)stopGyroUpdates;
- (void)startMagnetometerUpdates;
- (CMMagnetometerData *)getMagnetometerData;
- (void)stopMagnetometerUpdates;

@end
