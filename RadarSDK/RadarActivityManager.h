// RadarActivityManager.h

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@interface RadarActivityManager : NSObject

+ (instancetype)sharedInstance;
- (void)startActivityUpdatesWithHandler:(void (^)(CMMotionActivity *activity))handler;
- (void)stopActivityUpdates;
- (void)startMotionUpdates;
- (void)stopMotionUpdates;
- (NSDictionary *)getLatestMotionData;

@end
