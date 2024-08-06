//
//  RadarMotion.m
//  RadarMotion
//
//  Created by Kenny Hu on 8/5/24.
//

#import <Foundation/Foundation.h>
#import "RadarSDKMotion.h"

@interface RadarSDKMotion ()

@property (nonatomic, strong) CMMotionActivityManager *activityManager;
@property (nonatomic, strong) CMMotionManager *motionManager;

@end

@implementation RadarSDKMotion

- (instancetype)init {
    self = [super init];
    if (self) {
        _activityManager = [[CMMotionActivityManager alloc] init];
        _motionManager = [[CMMotionManager alloc] init];
    }
    NSLog(@"RadarSDKMotion initialized");
    return self;
}

- (void)stopActivityUpdates {
    [self.activityManager stopActivityUpdates];
}

- (void)startActivityUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMMotionActivityHandler)handler {
    NSLog(@"RadarSDKMotion startActivityUpdatesToQueue");
    if ([CMMotionActivityManager isActivityAvailable]) {
        [self.activityManager startActivityUpdatesToQueue:queue withHandler:handler];
    }
}

- (void)startAccelerometerUpdates {
    if (self.motionManager.isAccelerometerAvailable) {
        [self.motionManager startAccelerometerUpdates];
    }
}

- (CMAccelerometerData *)getAccelerometerData {
    
    if (self.motionManager.isAccelerometerActive) {
        return self.motionManager.accelerometerData;
    }
    return nil;
}

- (void)stopAccelerometerUpdates {
    [self.motionManager stopAccelerometerUpdates];
}

- (void)startGyroUpdates {
    if (self.motionManager.isGyroAvailable) {
        [self.motionManager startGyroUpdates];
    }
}

- (CMGyroData *)getGyroData {
    if (self.motionManager.isGyroActive) {
        return self.motionManager.gyroData;
    }
    return nil;
}

- (void)stopGyroUpdates {
    [self.motionManager stopGyroUpdates];
}

- (void)startMagnetometerUpdates {
    if (self.motionManager.isMagnetometerAvailable) {
        [self.motionManager startMagnetometerUpdates];
    }
}

- (CMMagnetometerData *)getMagnetometerData {
    if (self.motionManager.isMagnetometerActive) {
        return self.motionManager.magnetometerData;
    }
    return nil;
}

- (void)stopMagnetometerUpdates {
    [self.motionManager stopMagnetometerUpdates];
}

@end
