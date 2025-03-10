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
@property (nonatomic, strong, nullable) NSOperationQueue *accelerometerQueue;
@property (nonatomic, strong, nullable) NSOperationQueue *magnetometerQueue;
@property (nonatomic) BOOL isUpdatingActivity;
@property (nonatomic) BOOL isUpdatingPressure;
@property (nonatomic) BOOL isUpdatingAbsoluteAltitude;
@property (nonatomic) BOOL isUpdatingAccelerometer;
@property (nonatomic) BOOL isUpdatingMagnetometer;

@property (nonatomic, strong) NSMutableArray *accelerometerBuffer;
@property (nonatomic, strong) NSMutableArray *magnetometerBuffer;
@property (nonatomic, strong) dispatch_queue_t accelerometerBufferQueue;
@property (nonatomic, strong) dispatch_queue_t magnetometerBufferQueue;

@end

static const NSInteger kMaxBufferSize = 1500;

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
        _accelerometerQueue = [[NSOperationQueue alloc] init];
        _magnetometerQueue = [[NSOperationQueue alloc] init];
        _activityQueue.name = @"com.radar.activityQueue";
        _pressureQueue.name = @"com.radar.pressureQueue";
        _absoluteAltitudeQueue.name = @"com.radar.absoluteAltitudeQueue";
        _accelerometerQueue.name = @"com.radar.accelerometerQueue";
        _magnetometerQueue.name = @"com.radar.magnetometerQueue";
        _isUpdatingActivity = NO;
        _isUpdatingPressure = NO;
        _isUpdatingAbsoluteAltitude = NO;
        _isUpdatingAccelerometer = NO;
        _isUpdatingMagnetometer = NO;

        _accelerometerBuffer = [NSMutableArray array];
        _accelerometerBufferQueue = dispatch_queue_create("com.your.app.accelerometer", DISPATCH_QUEUE_SERIAL);
        _magnetometerBuffer = [NSMutableArray array];
        _magnetometerBufferQueue = dispatch_queue_create("com.your.app.magnetometer", DISPATCH_QUEUE_SERIAL);

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

- (void)startAccelerometerUpdates{
    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }
    self.isUpdatingAccelerometer = YES;
    [self.radarSDKMotion startAccelerometerUpdatesToQueue:self.accelerometerQueue withHandler:^(CMAccelerometerData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            return;
        }
        
        dispatch_async(self.accelerometerBufferQueue, ^{
            // Create measurement dictionary
            NSDictionary *measurement = @{
                @"x": @(data.acceleration.x),
                @"y": @(data.acceleration.y),
                @"z": @(data.acceleration.z),
                @"timestamp": @([[NSDate date] timeIntervalSince1970])  // Current time in seconds since 1970
            };
            
            // Prune buffer if needed
            if (self.accelerometerBuffer.count >= kMaxBufferSize) {
                [self.accelerometerBuffer removeObjectAtIndex:0];
            }
            
            // Add new measurement
            [self.accelerometerBuffer addObject:measurement];
        });
    }];
}

- (NSArray *)getAccelerometerData {
    __block NSArray *bufferCopy;
    dispatch_sync(self.accelerometerBufferQueue, ^{
        bufferCopy = [self.accelerometerBuffer copy];
        self.accelerometerBuffer = [NSMutableArray array];
    });
    return bufferCopy;
}

- (void)stopAccelerometerUpdates {
    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }
    self.isUpdatingAccelerometer = NO;
    [self.radarSDKMotion stopAccelerometerUpdates];
}

- (void)startMagnetometerUpdates {
    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }
    self.isUpdatingMagnetometer = YES;
    [self.radarSDKMotion startMagnetometerUpdatesToQueue:self.magnetometerQueue withHandler:^(CMMagnetometerData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Create measurement dictionary
            NSDictionary *measurement = @{
                @"x": @(data.magneticField.x),
                @"y": @(data.magneticField.y),
                @"z": @(data.magneticField.z),
                @"timestamp": @([[NSDate date] timeIntervalSince1970])  // Current time in seconds since 1970
            };
            
            // Prune buffer if needed
            if (self.magnetometerBuffer.count >= kMaxBufferSize) {
                [self.magnetometerBuffer removeObjectAtIndex:0];
            }
            
            // Add new measurement
            [self.magnetometerBuffer addObject:measurement];
        });
    }];
}

- (NSArray *)getMagnetometerData {
    __block NSArray *bufferCopy;
    dispatch_sync(self.magnetometerBufferQueue, ^{
        bufferCopy = [self.magnetometerBuffer copy];
        self.magnetometerBuffer = [NSMutableArray array];
    });
    return bufferCopy;
}

- (void)stopMagnetometerUpdates {
    if (!self.radarSDKMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"radarSDKMotion is not set"];
        return;
    }
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"stopMagnetometerUpdates"];
    self.isUpdatingMagnetometer = NO;
    [self.radarSDKMotion stopMagnetometerUpdates];
}

@end
