// RadarActivityManager.h

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@interface RadarActivityManager : NSObject

@property (nonatomic, strong) CMMotionActivityManager *motionActivityManager;
@property (nonatomic, strong) CMMotionManager *motionManager;

+ (instancetype)sharedInstance;
- (void)startActivityUpdatesWithHandler:(void (^)(CMMotionActivity *activity))handler;
- (void)stopActivityUpdates;
- (void)startMotionUpdates;
- (void)stopMotionUpdates;
- (void)requestLatestMotionData;

@end



// what we want to do, can we get away with only making the user init the RadarActivityManager and then we can call the startMotionUpdates and stopMotionUpdates from the RadarActivityManager class?

// that is number 1 plan

// if not, then we will most likely need to implement all the callbacks, but then its kinda pointless and not feasible for x-platform

