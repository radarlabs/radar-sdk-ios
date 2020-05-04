
#import "Radar.h"
#import "RadarBeacon.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RadarBeaconTrackCompletionHandler)(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons);

/// Manager class for beacon monitoring
@interface RadarBeaconManager : NSObject

+ (instancetype)sharedInstance;

/// Get beacons near the location and perform one time detection on nearby beacons.
/// @param location The geo location.
/// @param completionBlock The completion block which will be called on the internal queue of RadarBeaconManager.
- (void)detectOnceForLocation:(CLLocation *)location completionBlock:(RadarBeaconTrackCompletionHandler)completionBlock;

/// One time detection on nearby beacons
/// @param radarBeacons the list of beacons to monitor / detect
/// @param block completion block which will be called on the internal queue of RadarBeaconManager
- (void)detectOnceForRadarBeacons:(NSArray<RadarBeacon *> *)radarBeacons completionBlock:(RadarBeaconTrackCompletionHandler)block;

@end

NS_ASSUME_NONNULL_END
