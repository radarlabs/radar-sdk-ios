//
//  RadarLocationManagerImplementation.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "RadarActivityManager.h"
#import "RadarLocationManager.h"
#import "RadarMeta.h"
#import "RadarPermissionsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RadarLocationManagerImplementation <NSObject>

@property (nonnull, strong, nonatomic) CLLocationManager *locationManager;
@property (nonnull, strong, nonatomic) CLLocationManager *lowPowerLocationManager;
@property (nonnull, strong, nonatomic) RadarPermissionsHelper *permissionsHelper;
@property (nullable, strong, nonatomic) RadarActivityManager *activityManager;

- (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler
    NS_SWIFT_NAME(getLocation(completionHandler:));
- (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy
                     completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler
    NS_SWIFT_NAME(getLocation(desiredAccuracy:completionHandler:));
- (void)startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions
    NS_SWIFT_NAME(startTracking(options:));
- (void)stopTracking NS_SWIFT_NAME(stopTracking());
- (void)replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences
    NS_SWIFT_NAME(replaceSyncedGeofences(_:));
- (void)replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons
    NS_SWIFT_NAME(replaceSyncedBeacons(_:));
- (void)replaceSyncedBeaconUUIDs:(NSArray<NSString *> *)uuids
    NS_SWIFT_NAME(replaceSyncedBeaconUUIDs(_:));
- (void)updateTracking NS_SWIFT_NAME(updateTracking());
- (void)updateTrackingFromMeta:(RadarMeta *_Nullable)meta
    NS_SWIFT_NAME(updateTracking(fromMeta:));
- (void)updateTrackingFromInitialize NS_SWIFT_NAME(updateTrackingFromInitialize());
- (void)performIndoorScanIfConfigured:(CLLocation *)location
                               beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                     completionHandler:(void (^)(NSArray<RadarBeacon *> *_Nullable, NSString *_Nullable))completionHandler
    NS_SWIFT_NAME(performIndoorScanIfConfigured(location:beacons:completionHandler:));
- (void)restartPreviousTrackingOptions NS_SWIFT_NAME(restartPreviousTrackingOptions());
- (void)callCompletionHandlersWithStatus:(RadarStatus)status
                                location:(CLLocation *_Nullable)location
    NS_SWIFT_NAME(callCompletionHandlers(status:location:));

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
    NS_SWIFT_NAME(handleLocationManager(_:didUpdateLocations:));
- (void)locationManager:(CLLocationManager *)manager
        didEnterRegion:(CLRegion *)region
    NS_SWIFT_NAME(handleLocationManager(_:didEnterRegion:));
- (void)locationManager:(CLLocationManager *)manager
         didExitRegion:(CLRegion *)region
    NS_SWIFT_NAME(handleLocationManager(_:didExitRegion:));
- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region
    NS_SWIFT_NAME(handleLocationManager(_:didDetermineState:forRegion:));
- (void)locationManager:(CLLocationManager *)manager
               didVisit:(CLVisit *)visit
    NS_SWIFT_NAME(handleLocationManager(_:didVisit:));
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
    NS_SWIFT_NAME(handleLocationManager(_:didFailWithError:));
- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
    NS_SWIFT_NAME(handleLocationManager(_:didUpdateHeading:));
- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status
    NS_SWIFT_NAME(handleLocationManager(_:didChangeAuthorizationStatus:));

@end

NS_ASSUME_NONNULL_END
