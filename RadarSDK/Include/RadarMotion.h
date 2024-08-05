//
//  RadarMotion.h
//  RadarSDK
//
//  Created by Kenny Hu on 8/5/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@protocol RadarMotion <NSObject>


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
