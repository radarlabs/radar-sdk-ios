// RadarActivityManager.m

#import "RadarActivityManager.h"
#import "RadarLogger.h"

@interface RadarActivityManager ()

@property (nonatomic, strong) CMMotionActivityManager *motionActivityManager;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) dispatch_queue_t activityQueue;

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
        _activityQueue = dispatch_queue_create("com.radar.activityQueue", DISPATCH_QUEUE_SERIAL);
        _motionActivityManager = [[CMMotionActivityManager alloc] init];
        _motionManager = [[CMMotionManager alloc] init];
    }
    return self;
}

- (void)startActivityUpdatesWithHandler:(void (^)(CMMotionActivity *activity))handler {
    if (![CMMotionActivityManager isActivityAvailable]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Motion activity is not available on this device"];
        return;
    }

    dispatch_async(self.activityQueue, ^{
        [self.motionActivityManager startActivityUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMotionActivity *activity) {
            if (activity) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(activity);
                });
            }
        }];
    });
}

- (void)stopActivityUpdates {
    dispatch_async(self.activityQueue, ^{
        [self.motionActivityManager stopActivityUpdates];
    });
}

- (void)startMotionUpdates {
    if (self.motionManager.isAccelerometerAvailable) {
        [self.motionManager startAccelerometerUpdates];
    }
    if (self.motionManager.isGyroAvailable) {
        [self.motionManager startGyroUpdates];
    }
    if (self.motionManager.isMagnetometerAvailable) {
        [self.motionManager startMagnetometerUpdates];
    }
}

- (void)stopMotionUpdates {
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager stopGyroUpdates];
    [self.motionManager stopMagnetometerUpdates];
}

- (NSDictionary *)getLatestMotionData {
    NSMutableDictionary *motionData = [NSMutableDictionary dictionary];
    
    if (self.motionManager.isAccelerometerActive) {
        CMAccelerometerData *accelerometerData = self.motionManager.accelerometerData;
        if (accelerometerData) {
            [RadarState setLastAccelerometerData:@{
                @"x": @(accelerometerData.acceleration.x),
                @"y": @(accelerometerData.acceleration.y),
                @"z": @(accelerometerData.acceleration.z)
            };
        }
    }
    
    if (self.motionManager.isGyroActive) {
        CMGyroData *gyroData = self.motionManager.gyroData;
        if (gyroData) {
            [RadarState setLastGyroData:@{
                        @"xRotationRate" : @(gyroData.rotationRate.x),
                        @"yRotationRate" : @(gyroData.rotationRate.y),
                        @"zRotationRate" : @(gyroData.rotationRate.z),
                    }];
        }
    }
    
    if (self.motionManager.isMagnetometerActive) {
        CMMagnetometerData *magnetometerData = self.motionManager.magnetometerData;
        if (magnetometerData) {
            [RadarState setLastMagnetometerData:@{
                @"x": @(magnetometerData.magneticField.x),
                @"y": @(magnetometerData.magneticField.y),
                @"z": @(magnetometerData.magneticField.z)
            };
        }
    }
    
    return motionData;
}

@end