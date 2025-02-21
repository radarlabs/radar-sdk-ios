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
@property (nonatomic, strong) CMAltimeter *altimiterManager;

@end

@implementation RadarSDKMotion

- (instancetype)init {
    self = [super init];
    if (self) {
        _activityManager = [[CMMotionActivityManager alloc] init];
        _altimiterManager = [[CMAltimeter alloc] init];
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
        [self.altimiterManager startRelativeAltitudeUpdatesToQueue:queue withHandler:handler];
    }
}

- (void)stopRelativeAltitudeUpdates {
    [self.altimiterManager stopRelativeAltitudeUpdates];
}

- (void)startAbsoluteAltitudeUpdatesToQueue:(NSOperationQueue *) queue
                                withHandler:(CMAbsoluteAltitudeHandler) handler  API_AVAILABLE(ios(15.0)){
    if([CMAltimeter isAbsoluteAltitudeAvailable]) {
        [self.altimiterManager startAbsoluteAltitudeUpdatesToQueue:queue withHandler:handler];
    }
}

- (void)stopAbsoluteAltitudeUpdates {
    [self.altimiterManager stopAbsoluteAltitudeUpdates];
}

@end
