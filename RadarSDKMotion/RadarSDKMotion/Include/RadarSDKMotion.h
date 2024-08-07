//
//  RadarMotion.h
//  RadarMotion
//
//  Created by Kenny Hu on 8/5/24.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@interface RadarSDKMotion : NSObject
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


