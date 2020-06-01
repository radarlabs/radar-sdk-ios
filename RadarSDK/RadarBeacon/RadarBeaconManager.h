
#import "Radar.h"
#import "RadarBeacon.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RadarBeaconDetectionCompletionHandler)(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons);

extern NSArray<NSString *> *BeaconIdsFromRadarBeacons(NSArray<RadarBeacon *> *radarBeacons);

/// Manager class for beacon monitoring
@interface RadarBeaconManager : NSObject

+ (instancetype)sharedInstance;

/// Get beacons near the location and perform one time detection on nearby beacons.
/// @param location The geo location.
/// @param completionBlock The completion block which will be called on the internal queue of RadarBeaconManager.
- (void)detectOnceForLocation:(CLLocation *)location completionBlock:(RadarBeaconDetectionCompletionHandler)completionBlock;

/// One time detection on nearby beacons
/// @param radarBeacons the list of beacons to monitor / detect
/// @param block completion block which will be called on the internal queue of RadarBeaconManager
- (void)detectOnceForRadarBeacons:(NSArray<RadarBeacon *> *)radarBeacons completionBlock:(RadarBeaconDetectionCompletionHandler)block;

#pragma mark-- continuous tracking

- (BOOL)isTracking;

- (void)startTracking;

- (void)updateTrackingWithLocation:(CLLocation *)location source:(RadarLocationSource)source completionHandler:(nullable RadarBeaconDetectionCompletionHandler)completionHandler;

- (void)stopTracking;

@end

NS_ASSUME_NONNULL_END
