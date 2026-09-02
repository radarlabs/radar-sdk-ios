//
//  RadarLocationManagerSwift.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//
//  ObjC-visible interface for RadarLocationManager methods that have been ported to
//  Swift. The implementation lives in RadarLocationManager+Swift.swift. RadarLocationManager.m
//  imports this header and dispatches to these methods when useSwiftLocationManager is set.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "RadarBeacon.h"
#import "RadarGeofence.h"
#import "Radar.h"
#import "RadarMeta.h"
#import "RadarTrackingOptions.h"

@protocol RadarLocationManagerSwiftHost;

NS_ASSUME_NONNULL_BEGIN

@interface RadarLocationManagerSwift : NSObject

+ (CLLocationAccuracy)clLocationAccuracyForDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy;
+ (BOOL)shouldBypassDeviceLocationStateForSource:(RadarLocationSource)source;

+ (void)startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions;

+ (void)restartPreviousTrackingOptions;
+ (void)stopTrackingOnLocationManager:(CLLocationManager *)locationManager
                      activityManager:(nullable id)activityManager;
+ (void)startUpdatesWithHost:(id<RadarLocationManagerSwiftHost>)host
              locationManager:(CLLocationManager *)locationManager
       lowPowerLocationManager:(CLLocationManager *)lowPowerLocationManager
                      interval:(int)interval
                       blueBar:(BOOL)blueBar;
+ (void)stopUpdatesWithHost:(id<RadarLocationManagerSwiftHost>)host
             locationManager:(CLLocationManager *)locationManager;
+ (void)getLocationWithHost:(id<RadarLocationManagerSwiftHost>)host
          authorizationStatus:(CLAuthorizationStatus)authorizationStatus
              locationManager:(CLLocationManager *)locationManager
             completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
+ (void)getLocationWithDesiredAccuracyOnHost:(id<RadarLocationManagerSwiftHost>)host
                           authorizationStatus:(CLAuthorizationStatus)authorizationStatus
                               locationManager:(CLLocationManager *)locationManager
                              desiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy
                             completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;

+ (NSArray<NSString *> *)matchBeaconIdsWithRanged:(NSArray<RadarBeacon *> *)rangedBeacons
                                           synced:(NSArray<RadarBeacon *> *)syncedBeacons;

+ (void)replaceSyncedBeaconsOnLocationManager:(CLLocationManager *)locationManager
                                      beacons:(nullable NSArray<RadarBeacon *> *)beacons;
+ (void)replaceSyncedBeaconUUIDsOnLocationManager:(CLLocationManager *)locationManager
                                            uuids:(nullable NSArray<NSString *> *)uuids;
+ (void)removeSyncedBeaconsOnLocationManager:(CLLocationManager *)locationManager;

+ (void)replaceBubbleGeofenceOnLocationManager:(CLLocationManager *)locationManager
                                      location:(CLLocation *)location
                                        radius:(int)radius;
+ (void)removeBubbleGeofenceOnLocationManager:(CLLocationManager *)locationManager;
+ (void)replaceSyncedGeofencesOnLocationManager:(CLLocationManager *)locationManager
                                      geofences:(nullable NSArray<RadarGeofence *> *)geofences;
+ (void)removeSyncedGeofencesOnLocationManager:(CLLocationManager *)locationManager;
+ (void)removeAllRegionsOnLocationManager:(CLLocationManager *)locationManager;

+ (nullable CLLocation *)effectiveLocationForLocationManager:(CLLocationManager *)locationManager;

+ (void)applyRemoteTrackingOptions:(nullable RadarMeta *)meta;
+ (void)updateTrackingFromMeta:(nullable RadarMeta *)meta;

+ (BOOL)shouldHandleRegionWithIdentifier:(NSString *)identifier action:(NSString *)action;

+ (void)didUpdateLocations:(nullable NSArray<CLLocation *> *)updates completionHandlerCount:(NSUInteger)completionHandlerCount;
+ (void)didVisitOnLocationManager:(CLLocationManager *)locationManager visit:(CLVisit *)visit;
+ (void)didDetermineStateOnLocationManager:(CLLocationManager *)locationManager
                                     state:(CLRegionState)state
                                    region:(CLRegion *)region;

+ (void)didUpdateHeading:(CLHeading *)newHeading;
+ (void)didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
+ (void)didFailWithError:(NSError *)error;

+ (void)shutDownOnLocationManager:(CLLocationManager *)locationManager
          lowPowerLocationManager:(CLLocationManager *)lowPowerLocationManager;
+ (void)requestLocationOnLocationManager:(CLLocationManager *)locationManager;

@end

NS_ASSUME_NONNULL_END
