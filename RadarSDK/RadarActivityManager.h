// RadarActivityManager.h

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "RadarMotion.h"

@interface RadarActivityManager : NSObject

@property (nullable, weak, nonatomic) id<RadarMotion> radarMotion;

+ (instancetype _Nonnull )sharedInstance;
- (void)startActivityUpdatesWithHandler:(void (^_Nullable)(CMMotionActivity * _Nonnull activity))handler;
- (void)stopActivityUpdates;
- (void)startMotionUpdates;
- (void)stopMotionUpdates;
- (void)requestLatestMotionData;

@end
