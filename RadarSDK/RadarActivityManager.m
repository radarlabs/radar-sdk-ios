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

@property (nonatomic, strong, nullable) NSOperationQueue *activityQueue;
#if HAS_RADARSDKMOTION
@property (nonatomic, strong, nullable) RadarSDKMotion *radarSDKMotion;
#endif
@property (nonatomic) BOOL activityRegistered;

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
        _radarSDKMotion = [[RadarSDKMotion alloc] init];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"Starting activity manager"];
        #else
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"Not starting activity manager" ];
        #endif
        _activityRegistered = YES;
    }
    return self;
}

- (void)startActivityUpdatesWithHandler:(void (^)(CMMotionActivity *activity))handler {
    if (_activityRegistered) {
        return;
    }
    
    #if HAS_RADARSDKMOTION
    [_radarSDKMotion startActivityUpdatesToQueue:self.activityQueue withHandler:^(CMMotionActivity *activity) {
        if (activity) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(activity);
                self->_activityRegistered = YES;
            });
        }
    }];
    #endif
}

- (void)stopActivityUpdates {
    #if HAS_RADARSDKMOTION
    [_radarSDKMotion stopActivityUpdates];
    #endif
    _activityRegistered = NO;
}

- (void)startMotionUpdates {
    #if HAS_RADARSDKMOTION
    [_radarSDKMotion startMagnetometerUpdates];
    [_radarSDKMotion startAccelerometerUpdates];
    [_radarSDKMotion startGyroUpdates];
    #endif
}

- (void)stopMotionUpdates {
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
}

@end
