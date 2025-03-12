//
// RadarActivityManager.h
// RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarActivityManager.h"
#import "RadarLogger.h"
#import "RadarState.h"

@interface RadarActivityManager ()

@property (nonatomic, strong, nullable) NSOperationQueue *activityQueue;
@property (nonatomic, strong, nullable) NSOperationQueue *pressureQueue;
@property (nonatomic, strong, nullable) NSOperationQueue *absoluteAltitudeQueue;
@property (nonatomic) BOOL isUpdatingActivity;
@property (nonatomic) BOOL isUpdatingPressure;
@property (nonatomic) BOOL isUpdatingAbsoluteAltitude;

@end

@implementation RadarActivityManager

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _activityQueue = [[NSOperationQueue alloc] init];
        _pressureQueue = [[NSOperationQueue alloc] init];
        _absoluteAltitudeQueue = [[NSOperationQueue alloc] init];
        _activityQueue.name = @"com.radar.activityQueue";
        _pressureQueue.name = @"com.radar.pressureQueue";
        _absoluteAltitudeQueue.name = @"com.radar.absoluteAltitudeQueue";
        _isUpdatingActivity = NO;
        _isUpdatingPressure = NO;
        _isUpdatingAbsoluteAltitude = NO;

    }
    return self;
}

- (void)requestPermission {

     if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }

    if (!self.isUpdatingAbsoluteAltitude && !self.isUpdatingActivity && !self.isUpdatingPressure) {
        [self.radarSDKMotion startActivityUpdatesToQueue:self.activityQueue withHandler:^(CMMotionActivity *activity) {
            [self.radarSDKMotion stopActivityUpdates];
        }];
        [self.radarSDKMotion startRelativeAltitudeUpdatesToQueue:self.pressureQueue withHandler:^(CMAltitudeData *altitudeData, NSError *error) {
            [self.radarSDKMotion stopRelativeAltitudeUpdates];
        }];
        if (@available(iOS 15.0, *)) {
            [self.radarSDKMotion startAbsoluteAltitudeUpdatesToQueue:self.absoluteAltitudeQueue withHandler:^(CMAbsoluteAltitudeData *altitudeData, NSError *error) {
                [self.radarSDKMotion stopAbsoluteAltitudeUpdates];
            }];
        } 
    }
}

- (void)startActivityUpdatesWithHandler:(void (^)(CMMotionActivity *activity))handler {

    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"startActivityUpdatesWithHandler"];

    if (self.isUpdatingActivity) {
        return;
    }
    self.isUpdatingActivity = YES;

    [self.radarSDKMotion startActivityUpdatesToQueue:self.activityQueue withHandler:^(CMMotionActivity *activity) {
        if (activity) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(activity);
            });
        }
    }];
    
}

- (void)stopActivityUpdates {
    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }
    [self.radarSDKMotion stopActivityUpdates];
    self.isUpdatingActivity = NO;
}

- (void)startRelativeAltitudeWithHandler:(void (^)(CMAltitudeData * _Nullable altitudeData))handler {
    
    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }
    if (self.isUpdatingPressure) {
        return;
    }
    self.isUpdatingPressure = YES;
    [self.radarSDKMotion startRelativeAltitudeUpdatesToQueue:self.pressureQueue withHandler:^(CMAltitudeData *altitudeData, NSError *error) {
        if (error) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"startRelativeAltitudeWithHandler error: %@", error]];
            return;
        }
        if (altitudeData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(altitudeData);
            });
        }
    }];
}

- (void)stopRelativeAltitudeUpdates {
    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"stopRelativeAltitudeUpdates"];
    self.isUpdatingPressure = NO;
    [self.radarSDKMotion stopRelativeAltitudeUpdates];
}

- (void)startAbsoluteAltitudeWithHandler:(void (^)(CMAbsoluteAltitudeData * _Nullable))handler {
    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }
    self.isUpdatingAbsoluteAltitude = YES;
    [self.radarSDKMotion startAbsoluteAltitudeUpdatesToQueue:self.absoluteAltitudeQueue withHandler:^(CMAbsoluteAltitudeData *altitudeData, NSError *error) {
        if (error) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"startAbsoluteAltitudeUpdatesToQueue error: %@", error]];
            return;
        }
        if (altitudeData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(altitudeData);
            });
        }
    }];
}

- (void)stopAbsoluteAltitudeUpdates {
    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }
    self.isUpdatingAbsoluteAltitude = NO;
    [self.radarSDKMotion stopAbsoluteAltitudeUpdates];
}


@end
