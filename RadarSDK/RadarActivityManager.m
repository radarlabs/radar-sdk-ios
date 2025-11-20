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
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"requestPermission: warming up CoreMotion sensors (activity, relative altitude, absolute altitude if available)"];
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
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"startRelativeAltitudeWithHandler: already updating pressure; ignoring duplicate call"];
        return;
    }
    self.isUpdatingPressure = YES;
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"startRelativeAltitudeWithHandler: starting CMAltimeter relative updates"];
    [self.radarSDKMotion startRelativeAltitudeUpdatesToQueue:self.pressureQueue withHandler:^(CMAltitudeData *altitudeData, NSError *error) {
        NSTimeInterval callbackTime = [[NSDate date] timeIntervalSince1970];
        CMAuthorizationStatus authStatus = [CMMotionActivityManager authorizationStatus];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Relative altitude callback invoked at %.3f, Motion & Fitness auth status: %@", callbackTime, [Radar stringForMotionAuthorization:authStatus]]];
        
        if (error) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"startRelativeAltitudeWithHandler error: %@ (domain: %@, code: %ld)", error.localizedDescription, error.domain, (long)error.code]];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"Ensure Motion & Fitness permissions are granted and device supports barometer (CMAltimeter)" ];
            return;
        }
        if (altitudeData) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Relative altitude sample: pressure=%.3f kPa (%.1f hPa), relative=%.3f m, timestamp=%.3f", altitudeData.pressure.doubleValue, altitudeData.pressure.doubleValue * 10.0, altitudeData.relativeAltitude.doubleValue, callbackTime]];
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(altitudeData);
            });
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:[NSString stringWithFormat:@"Relative altitude handler invoked with nil altitudeData at %.3f - this will cause altitude to be undefined", callbackTime]];
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
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"startAbsoluteAltitudeWithHandler: starting CMAltimeter absolute updates (iOS 15+)" ];
    [self.radarSDKMotion startAbsoluteAltitudeUpdatesToQueue:self.absoluteAltitudeQueue withHandler:^(CMAbsoluteAltitudeData *altitudeData, NSError *error) {
        NSTimeInterval callbackTime = [[NSDate date] timeIntervalSince1970];
        CMAuthorizationStatus authStatus = [CMMotionActivityManager authorizationStatus];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Absolute altitude callback invoked at %.3f, Motion & Fitness auth status: %@", callbackTime, [Radar stringForMotionAuthorization:authStatus]]];
        
        if (error) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"startAbsoluteAltitudeUpdatesToQueue error: %@ (domain: %@, code: %ld)", error.localizedDescription, error.domain, (long)error.code]];
            return;
        }
        if (altitudeData) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Absolute altitude sample: altitude=%.3f m, accuracy=%.3f m, precision=%.3f m, timestamp=%.3f", altitudeData.altitude, altitudeData.accuracy, altitudeData.precision, callbackTime]];
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(altitudeData);
            });
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:[NSString stringWithFormat:@"Absolute altitude handler invoked with nil altitudeData at %.3f - this will cause altitude to be undefined", callbackTime]];
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
