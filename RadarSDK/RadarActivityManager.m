// RadarActivityManager.m

#import "RadarActivityManager.h"
#import "RadarLogger.h"
#import "RadarState.h"

#if __has_include("RadarSDKMotion.h")
#import "RadarSDKMotion.h"
#define HAS_RADARSDKMOTION 1
#else
#define HAS_RADARSDKMOTION 0
#endif

@interface RadarActivityManager ()


//@property (nonatomic, strong) CMMotionActivityManager *motionActivityManager;
//@property (nonatomic, strong, nullable) CMMotionManager *motionManager;
@property (nonatomic, strong, nullable) NSOperationQueue *activityQueue;
#if HAS_RADARSDKMOTION
@property (nonatomic, strong, nullable) RadarSDKMotion *radarSDKMotion;
#endif

@end

@implementation RadarActivityManager

+ (instancetype)sharedInstance {
    static RadarActivityManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _activityQueue = [[NSOperationQueue alloc] init];
        _activityQueue.name = @"com.radar.activityQueue";
        
//        if we have imports
//        _motionActivityManager = [[CMMotionActivityManager alloc] init];
//        _motionManager = [[CMMotionManager alloc] init];
        #if HAS_RADARSDKMOTION
        _radarSDKMotion = [[RadarSDKMotion alloc] init];
        #endif
        
        

    }
    return self;
}

// do we need to case this to a different type to beat the analysis? not going to do that for now
- (void)startActivityUpdatesWithHandler:(void (^)(CMMotionActivity *activity))handler {
    
    #if HAS_RADARSDKMOTION
    [_radarSDKMotion startActivityUpdatesToQueue:self.activityQueue withHandler:^(CMMotionActivity *activity) {
        if (activity) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(activity);
            });
        }
    }];
    #endif
    
    
//    if (![CMMotionActivityManager isActivityAvailable]) {
//        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Motion activity is not available on this device"];
//        return;
//    }
//
//    [self.motionActivityManager startActivityUpdatesToQueue:self.activityQueue withHandler:^(CMMotionActivity *activity) {
//        if (activity) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                handler(activity);
//            });
//        }
//    }];
}

- (void)stopActivityUpdates {
//    [self.motionActivityManager stopActivityUpdates];
    #if HAS_RADARSDKMOTION
    [_radarSDKMotion stopActivityUpdates];
    #endif
    
    
}

- (void)startMotionUpdates {
//    if (self.motionManager.isAccelerometerAvailable) {
//        [self.motionManager startAccelerometerUpdates];
//    }
//    if (self.motionManager.isGyroAvailable) {
//        [self.motionManager startGyroUpdates];
//    }
//    if (self.motionManager.isMagnetometerAvailable) {
//        [self.motionManager startMagnetometerUpdates];
//    }
    #if HAS_RADARSDKMOTION
    [_radarSDKMotion startMagnetometerUpdates];
    [_radarSDKMotion startAccelerometerUpdates];
    [_radarSDKMotion startGyroUpdates];
    #endif
}

- (void)stopMotionUpdates {
//    [self.motionManager stopAccelerometerUpdates];
//    [self.motionManager stopGyroUpdates];
//    [self.motionManager stopMagnetometerUpdates];
    #if HAS_RADARSDKMOTION
    [_radarSDKMotion stopGyroUpdates];
    [_radarSDKMotion stopMagnetometerUpdates];
    [_radarSDKMotion stopAccelerometerUpdates];
    #endif
}

- (void)requestLatestMotionData {
    #if HAS_RADARSDKMOTION
    CMAccelerometerData *accelerometerData = [_radarSDKMotion getAccelerometerData];
    if (accelerometerData) {
        [RadarState setLastAccelerometerData:@{
            @"x": @(accelerometerData.acceleration.x),
            @"y": @(accelerometerData.acceleration.y),
            @"z": @(accelerometerData.acceleration.z)
        }];
    }
    CMGyroData *gyroData = [_radarSDKMotion getGyroData];
    if (gyroData) {
        [RadarState setLastGyroData:@{
            @"xRotationRate" : @(gyroData.rotationRate.x),
            @"yRotationRate" : @(gyroData.rotationRate.y),
            @"zRotationRate" : @(gyroData.rotationRate.z),
        }];
    }
    CMMagnetometerData *magnetometerData = [_radarSDKMotion getMagnetometerData];
    if (magnetometerData) {
        [RadarState setLastMagnetometerData:@{
            @"x": @(magnetometerData.magneticField.x),
            @"y": @(magnetometerData.magneticField.y),
            @"z": @(magnetometerData.magneticField.z)
        }];
    }
    
    #endif
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
//                        @"xRotationRate" : @(gyroData.rotationRate.x),
//                        @"yRotationRate" : @(gyroData.rotationRate.y),
//                        @"zRotationRate" : @(gyroData.rotationRate.z),
//                    }];
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
