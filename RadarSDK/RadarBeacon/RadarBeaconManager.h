
#import "Radar.h"
#import "RadarBeacon.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RadarBeaconMonitorCompletionHandler)(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons);

/// Manager class for beacon monitoring
@interface RadarBeaconManager : NSObject

+ (instancetype)sharedInstance;

/// One time detection on nearby beacons
/// @param radarBeacons the list of beacons to monitor / detect
/// @param block completion block which will be called on the internal queue of RadarBeaconManager
- (void)monitorOnceForRadarBeacons:(NSArray<RadarBeacon *> *)radarBeacons completionBlock:(RadarBeaconMonitorCompletionHandler)block;

@end

NS_ASSUME_NONNULL_END
