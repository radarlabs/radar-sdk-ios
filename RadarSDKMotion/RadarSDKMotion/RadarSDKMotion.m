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

@end

@implementation RadarSDKMotion

- (instancetype)init {
    self = [super init];
    if (self) {
        _activityManager = [[CMMotionActivityManager alloc] init];
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

@end
