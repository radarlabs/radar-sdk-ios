// RadarActivityManager.m

#import "RadarActivityManager.h"
#import "RadarLogger.h"
#import "RadarState.h"

@interface RadarActivityManager ()

@property (nonatomic, strong, nullable) NSOperationQueue *activityQueue;

// @property (nonatomic, strong) CMMotionActivityManager *motionActivityManager;
// @property (nonatomic, strong, nullable) CMMotionManager *motionManager;
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
        // _motionActivityManager = [[CMMotionActivityManager alloc] init];
        // _motionManager = [[CMMotionManager alloc] init];
        _isUpdatingActivity = NO;
    }
    return self;
}

- (void)startActivityUpdatesWithHandler:(void (^)(CMMotionActivity *activity))handler {
    
    // if (![CMMotionActivityManager isActivityAvailable]) {
    //     [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Motion activity is not available on this device"];
    //     return;
    // }

    if (!self.radarMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"RadarMotion is not set"];
        return;
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"RadarMotion is set"];

    if (self.isUpdatingActivity) {
        return;
    }
    self.isUpdatingActivity = YES;

    [self.radarMotion startActivityUpdatesToQueue:self.activityQueue withHandler:^(CMMotionActivity *activity) {
        if (activity) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(activity);
            });
        }
    }];
    
//    [self.motionActivityManager startActivityUpdatesToQueue:self.activityQueue withHandler:^(CMMotionActivity *activity) {
//        if (activity) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                handler(activity);
//            });
//        }
//    }];
}

- (void)stopActivityUpdates {
    if (!self.radarMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"RadarMotion is not set"];
        return;
    }
//    [self.motionActivityManager stopActivityUpdates];
    [self.radarMotion stopActivityUpdates];
    self.isUpdatingActivity = NO;
}

- (void)startMotionUpdates {
    if (!self.radarMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"RadarMotion is not set"];
        return;
    }
    [self.radarMotion startAccelerometerUpdates];
    [self.radarMotion startGyroUpdates];
    [self.radarMotion startMagnetometerUpdates];

//    if (self.motionManager.isAccelerometerAvailable) {
//        [self.motionManager startAccelerometerUpdates];
//    }
//    if (self.motionManager.isGyroAvailable) {
//        [self.motionManager startGyroUpdates];
//    }
//    if (self.motionManager.isMagnetometerAvailable) {
//        [self.motionManager startMagnetometerUpdates];
//    }
}

- (void)stopMotionUpdates {
    if (!self.radarMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"RadarMotion is not set"];
        return;
    }
    [self.radarMotion stopAccelerometerUpdates];
    [self.radarMotion stopGyroUpdates];
    [self.radarMotion stopMagnetometerUpdates];

//    [self.motionManager stopAccelerometerUpdates];
//    [self.motionManager stopGyroUpdates];
//    [self.motionManager stopMagnetometerUpdates];
}

- (void)requestLatestMotionData {
    if (!self.radarMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"RadarMotion is not set"];
        return;
    }

       CMAccelerometerData *accelerometerData = [self.radarMotion getAccelerometerData];
       if (accelerometerData) {
           [RadarState setLastAccelerometerData:@{
               @"x": @(accelerometerData.acceleration.x),
               @"y": @(accelerometerData.acceleration.y),
               @"z": @(accelerometerData.acceleration.z)
           }];
       }
   
       CMGyroData *gyroData = [self.radarMotion getGyroData];
       if (gyroData) {
           [RadarState setLastGyroData:@{
               @"xRotationRate" : @(gyroData.rotationRate.x),
               @"yRotationRate" : @(gyroData.rotationRate.y),
               @"zRotationRate" : @(gyroData.rotationRate.z),
           }];
       }
   
       CMMagnetometerData *magnetometerData = [self.radarMotion getMagnetometerData];
       if (magnetometerData) {
           [RadarState setLastMagnetometerData:@{
               @"x": @(magnetometerData.magneticField.x),
               @"y": @(magnetometerData.magneticField.y),
               @"z": @(magnetometerData.magneticField.z)
           }];
       }

//    if (self.motionManager.isAccelerometerActive) {
//        CMAccelerometerData *accelerometerData = self.motionManager.accelerometerData;
//        if (accelerometerData) {
//            [RadarState setLastAccelerometerData:@{
//                @"x": @(accelerometerData.acceleration.x),
//                @"y": @(accelerometerData.acceleration.y),
//                @"z": @(accelerometerData.acceleration.z)
//            }];
//        }
//    }
//    
//    if (self.motionManager.isGyroActive) {
//        CMGyroData *gyroData = self.motionManager.gyroData;
//        if (gyroData) {
//            [RadarState setLastGyroData:@{
//                @"xRotationRate" : @(gyroData.rotationRate.x),
//                @"yRotationRate" : @(gyroData.rotationRate.y),
//                @"zRotationRate" : @(gyroData.rotationRate.z),
//            }];
//        }
//    }
//    
//    if (self.motionManager.isMagnetometerActive) {
//        CMMagnetometerData *magnetometerData = self.motionManager.magnetometerData;
//        if (magnetometerData) {
//            [RadarState setLastMagnetometerData:@{
//                @"x": @(magnetometerData.magneticField.x),
//                @"y": @(magnetometerData.magneticField.y),
//                @"z": @(magnetometerData.magneticField.z)
//            }];
//        }
//    }
}

@end
