//
//  RadarLocationManager.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarDelegate.h"
#import "RadarMeta.h"
#import "RadarPermissionsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarLocationManager : NSObject<CLLocationManagerDelegate>

@property (nonnull, strong, nonatomic) CLLocationManager *locationManager;
@property (nonnull, strong, nonatomic) UNUserNotificationCenter *notificationCenter;
@property (nonnull, strong, nonatomic) CLLocationManager *lowPowerLocationManager;
@property (nonnull, strong, nonatomic) RadarPermissionsHelper *permissionsHelper;

+ (instancetype)sharedInstance;
- (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
- (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
- (void)startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions;
- (void)stopTracking;
- (void)replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences;
- (void)replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons;
- (void)updateSyncedBeacons:(NSArray<RadarBeacon *> *)beacons;
- (void)updateSyncedBeaconUUIDs:(NSArray<NSString *> *)uuids;
- (void)replaceSyncedBeaconUUIDs:(NSArray<NSString *> *)uuids;
- (void)updateTracking;
- (void)updateTrackingFromMeta:(RadarMeta *_Nullable)meta;
- (void)updateTrackingFromInitialize;

/**
 If `[RadarSettings previousTrackingOptions]` is not `nil`, remove them and
 replace the `[RadarSettings trackingOptions]` with them, and restart tracking.
 If they *are* `nil`, then tracking wasn't active prior to the trip, so don't
 restart tracking. This is called when completing or canceling a trip.
 */
- (void)restartPreviousTrackingOptions;

@end

NS_ASSUME_NONNULL_END
