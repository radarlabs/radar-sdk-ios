//
//  RadarLocationManager+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarLocationManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RadarLocationManagerRouting <NSObject>

@property (nullable, nonatomic, weak) RadarLocationManager *owner;

- (void)didUpdateInjectedDependencies;

- (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
- (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy
                     completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
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
- (void)restartPreviousTrackingOptions;
- (void)callCompletionHandlersWithStatus:(RadarStatus)status location:(CLLocation *_Nullable)location;

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations;
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region;
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region;
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region;
- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading;
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;

@end

NS_ASSUME_NONNULL_END
