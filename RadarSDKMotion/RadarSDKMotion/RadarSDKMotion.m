//
//  RadarMotion.m
//  RadarMotion
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarSDKMotion.h"

@interface RadarSDKMotion ()

@property (nonatomic, strong) CMMotionActivityManager *activityManager;
@property (nonatomic, strong) CMAltimeter *altimeterManager;
@property (nonatomic, strong) CMMotionManager *motionManager;


@end

@implementation RadarSDKMotion

- (instancetype)init {
    self = [super init];
    if (self) {
        _activityManager = [[CMMotionActivityManager alloc] init];
        _altimeterManager = [[CMAltimeter alloc] init];
        _motionManager = [[CMMotionManager alloc] init];
    }
    return self;
}


- (void)startActivityUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMMotionActivityHandler)handler {
    if ([CMMotionActivityManager isActivityAvailable]) {
        [self.activityManager startActivityUpdatesToQueue:queue withHandler:handler];
    }
}

- (void)stopActivityUpdates {
    [self.activityManager stopActivityUpdates];
}


- (void)startRelativeAltitudeUpdatesToQueue:(NSOperationQueue *) queue
                                 withHandler:(CMAltitudeHandler) handler {
    if([CMAltimeter isRelativeAltitudeAvailable]) {
        [self.altimeterManager startRelativeAltitudeUpdatesToQueue:queue withHandler:handler];
    }
}

- (void)stopRelativeAltitudeUpdates {
    [self.altimeterManager stopRelativeAltitudeUpdates];
}

- (void)startAbsoluteAltitudeUpdatesToQueue:(NSOperationQueue *) queue
                                withHandler:(CMAbsoluteAltitudeHandler) handler  API_AVAILABLE(ios(15.0)){
    if([CMAltimeter isAbsoluteAltitudeAvailable]) {
        [self.altimeterManager startAbsoluteAltitudeUpdatesToQueue:queue withHandler:handler];
    }
}

- (void)stopAbsoluteAltitudeUpdates {
    if (@available(iOS 15.0, *)) {
        [self.altimeterManager stopAbsoluteAltitudeUpdates];
    } else {
        // Fallback on earlier versions
    }
}


@end
