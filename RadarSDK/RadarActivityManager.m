// RadarActivityManager.m

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
    
}

- (void)stopActivityUpdates {
    if (!self.radarMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"RadarMotion is not set"];
        return;
    }
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

}

- (void)stopMotionUpdates {
    if (!self.radarMotion) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"RadarMotion is not set"];
        return;
    }
    [self.radarMotion stopAccelerometerUpdates];
    [self.radarMotion stopGyroUpdates];
    [self.radarMotion stopMagnetometerUpdates];

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

}

@end
