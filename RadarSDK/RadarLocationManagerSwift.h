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

NS_ASSUME_NONNULL_BEGIN

@interface RadarLocationManagerSwift : NSObject

+ (void)restartPreviousTrackingOptions;

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
+ (void)removeSyncedGeofencesOnLocationManager:(CLLocationManager *)locationManager;
+ (void)removeAllRegionsOnLocationManager:(CLLocationManager *)locationManager;

@end

NS_ASSUME_NONNULL_END
