//
//  RadarLocationManager.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

#import "Radar.h"
#import "RadarDelegate.h"
#import "RadarMeta.h"
#import "RadarPermissionsHelper.h"
#import "RadarActivityManager.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface RadarLocationManagerSwift : NSObject

@property (nonatomic, strong) CLLocationManager * _Nullable locationManager;

+ (RadarLocationManagerSwift * _Nonnull)shared;
- (void)replaceMonitoredRegionsWithGeofences:(NSArray<RadarGeofence *> * _Nonnull)geofences;
- (nonnull instancetype)initWithLocationManager:(CLLocationManager * _Nonnull)locationManager;
@end


@interface RadarLocationManager : NSObject<CLLocationManagerDelegate>

@property (nonnull, strong, nonatomic) CLLocationManager *locationManager;
@property (nonnull, strong, nonatomic) CLLocationManager *lowPowerLocationManager;
@property (nonnull, strong, nonatomic) RadarPermissionsHelper *permissionsHelper;
@property (nullable, strong, nonatomic) RadarActivityManager *activityManager;

+ (instancetype)sharedInstance;
- (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
- (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
- (void)startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions;
- (void)stopTracking;
- (void)replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences;
- (void)replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons;
- (void)replaceSyncedBeaconUUIDs:(NSArray<NSString *> *)uuids;
- (void)updateTracking;
- (void)updateTrackingFromMeta:(RadarMeta *_Nullable)meta;
- (void)updateTrackingFromInitialize;
- (void)performIndoorScanIfConfigured:(CLLocation *)location 
                               beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                     completionHandler:(void (^)(NSArray<RadarBeacon *> *_Nullable, NSString *_Nullable))completionHandler;

/**
 If `[RadarSettings previousTrackingOptions]` is not `nil`, remove them and
 replace the `[RadarSettings trackingOptions]` with them, and restart tracking.
 If they *are* `nil`, then tracking wasn't active prior to the trip, so don't
 restart tracking. This is called when completing or canceling a trip.
 */
- (void)restartPreviousTrackingOptions;

@end

NS_ASSUME_NONNULL_END
