//
//  RadarLocationProviding.h
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "Radar.h"
#import "RadarPermissionsHelper.h"

@class RadarGeofence;
@class RadarBeacon;
@class RadarMeta;
@class RadarTrackingOptions;

NS_ASSUME_NONNULL_BEGIN

@protocol RadarLocationProviding <NSObject>

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
- (void)restartPreviousTrackingOptions;
- (void)performIndoorScanIfConfigured:(CLLocation *)location
                               beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                     completionHandler:(void (^)(NSArray<RadarBeacon *> *_Nullable, NSString *_Nullable))completionHandler;

@property (nonnull, strong, nonatomic, readonly) RadarPermissionsHelper *permissionsHelper;

@end

NS_ASSUME_NONNULL_END
