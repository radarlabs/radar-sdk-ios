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
@property (nonatomic) BOOL isUpdatingActivity;
@property (nonatomic) BOOL isUpdatingPressure;

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
        _activityQueue.name = @"com.radar.activityQueue";
        _pressureQueue.name = @"com.radar.pressureQueue";
        _isUpdatingActivity = NO;
        _isUpdatingPressure = NO;
    }
    return self;
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
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"startRelativeAltitudeWithHandler"];
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
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"startRelativeAltitudeWithHandler dispatch_async main_queue: %@", altitudeData]];
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

@end
