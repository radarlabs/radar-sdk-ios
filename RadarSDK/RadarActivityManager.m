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

@property (nonatomic) BOOL isUpdatingActivity;

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
        _activityQueue.name = @"com.radar.activityQueue";
        _isUpdatingActivity = NO;
    }
    return self;
}

- (void)startActivityUpdatesWithHandler:(void (^)(CMMotionActivity *activity))handler {

    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is set"];

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

@end
