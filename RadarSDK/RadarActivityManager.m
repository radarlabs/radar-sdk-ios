// RadarActivityManager.m

#import "RadarActivityManager.h"
#import "RadarLogger.h"
#import "RadarState.h"

#if __has_include("RadarMotion.h")
#import "RadarMotion.h"
#define HAS_RADARSDKMOTION 1
#else
#define HAS_RADARSDKMOTION 0
#endif

@interface RadarActivityManager ()

@property (nonatomic, strong, nullable) NSOperationQueue *activityQueue;
#if HAS_RADARSDKMOTION
@property (nonatomic, strong, nullable) RadarMotion *radarMotion;
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

        #if HAS_RADARSDKMOTION
        _radarMotion = [[RadarMotion alloc] init];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"Starting activity manager"];
        #else
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"Not starting activity manager" ];
        #endif
        
    }
    return self;
}

- (void)startActivityUpdatesWithHandler:(void (^)(CMMotionActivity *activity))handler {
    
    #if HAS_RADARSDKMOTION
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"Starting updates"];
    [_radarMotion startActivityUpdatesToQueue:self.activityQueue withHandler:^(CMMotionActivity *activity) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(activity);
        });
    }];
    #endif
}

- (void)stopActivityUpdates {
    #if HAS_RADARSDKMOTION
    [_radarMotion stopActivityUpdates];
    #endif
}

- (void)startMotionUpdates {
    #if HAS_RADARSDKMOTION
    [_radarMotion startMagnetometerUpdates];
    [_radarMotion startAccelerometerUpdates];
    [_radarMotion startGyroUpdates];
    #endif
}

- (void)stopMotionUpdates {
    #if HAS_RADARSDKMOTION
    [_radarMotion stopGyroUpdates];
    [_radarMotion stopMagnetometerUpdates];
    [_radarMotion stopAccelerometerUpdates];
    #endif
}

- (void)requestLatestMotionData {
    #if HAS_RADARSDKMOTION
    CMAccelerometerData *accelerometerData = [_radarMotion getAccelerometerData];
    if (accelerometerData) {
        [RadarState setLastAccelerometerData:@{
            @"x": @(accelerometerData.acceleration.x),
            @"y": @(accelerometerData.acceleration.y),
            @"z": @(accelerometerData.acceleration.z)
        }];
    }
    CMGyroData *gyroData = [_radarMotion getGyroData];
    if (gyroData) {
        [RadarState setLastGyroData:@{
            @"xRotationRate" : @(gyroData.rotationRate.x),
            @"yRotationRate" : @(gyroData.rotationRate.y),
            @"zRotationRate" : @(gyroData.rotationRate.z),
        }];
    }
    CMMagnetometerData *magnetometerData = [_radarMotion getMagnetometerData];
    if (magnetometerData) {
        [RadarState setLastMagnetometerData:@{
            @"x": @(magnetometerData.magneticField.x),
            @"y": @(magnetometerData.magneticField.y),
            @"z": @(magnetometerData.magneticField.z)
        }];
    }
    
    #endif
}

@end
