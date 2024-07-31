//
//  RadarMotion.h
//  RadarSDK
//
//  Created by Kenny Hu on 7/31/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//
#import <CoreMotion/CoreMotion.h>

@interface RadarMotion : NSObject


- (void)stopActivityUpdates;
- (void)startActivityUpdatesToQueue: (NSOperationQueue *)queue withHandler : (CMMotionActivityHandler)handler;

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
