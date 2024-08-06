// RadarActivityManager.h

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "RadarMotionProtocol.h"

@interface RadarActivityManager : NSObject

@property (nullable, strong, nonatomic) id radarMotion;

+ (instancetype _Nonnull )sharedInstance;
- (void)startActivityUpdatesWithHandler:(void (^_Nullable)(CMMotionActivity * _Nonnull activity))handler;
- (void)stopActivityUpdates;
- (void)startMotionUpdates;
- (void)stopMotionUpdates;
- (void)requestLatestMotionData;

@end
