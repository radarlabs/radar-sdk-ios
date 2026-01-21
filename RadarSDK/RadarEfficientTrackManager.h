//
//  RadarEfficientTrackManager.h
//  RadarSDK
//
//  Created by Alan Charles on 1/21/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarGeofence.h"
#import "RadarBeacon.h"
#import "RadarPlace.h"
#import "RadarTrackingOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarEfficientTrackManager : NSObject

/**
 Determines whether a /track API call should be made for the given location.
 Checks based on which sync options are enabled in tracking options.
 
 @param location The user's current location.
 @param options The tracking options with syncOnGeofenceEvents/syncOnPlaceEvents/syncOnBeaconEvents flags.
 @return YES if /track should be called, NO if it can be skipped.
 */
+ (BOOL)shouldTrackLocation:(CLLocation *)location options:(RadarTrackingOptions *)options;

/**
 Returns the geofences the user is currently inside based on local calculation
 using cached nearbyGeofences from RadarState.
 
 @param location The user's current location.
 @return Array of geofences the user is inside.
 */
+ (NSArray<RadarGeofence *> *)getGeofencesForLocation:(CLLocation *)location;

/**
 Returns the beacons the user is currently near based on local calculation
 using cached nearbyBeacons from RadarState.
 
 @param location The user's current location.
 @return Array of beacons the user is near.
 */
+ (NSArray<RadarBeacon *> *)getBeaconsForLocation:(CLLocation *)location;

/**
 Checks if the user's geofence state has changed by comparing
 server-known state (lastKnownGeofenceIds) with local detection.
 
 @param location The user's current location.
 @return YES if geofence entry or exit detected.
 */
+ (BOOL)hasGeofenceStateChanged:(CLLocation *)location;

/**
 Checks if the user's beacon state has changed by comparing
 server-known state (lastKnownBeaconIds) with local detection.
 
 @param location The user's current location.
 @return YES if beacon entry or exit detected.
 */
+ (BOOL)hasBeaconStateChanged:(CLLocation *)location;


/**
 Returns the places the user is currently inside based on local calculation
 using cached nearbyPlaces from RadarState.
 
 @param location The user's current location.
 @return Array of places the user is near.
 */
+ (NSArray<RadarPlace *> *)getPlacesForLocation:(CLLocation *)location;

/**
 Checks if the user's place state has changed by comparing
 server-known state (placeId) with local detection.
 
 @param location The user's current location.
 @return YES if place entry or exit detected.
 */
+ (BOOL)hasPlacesStateChanged:(CLLocation *)location;

/**
 Checks if the user is outside the synced region where cached data is valid.
 
 @param location The user's current location.
 @return YES if outside synced region (need fresh data from server).
 */
+ (BOOL)isOutsideSyncedRegion:(CLLocation *)location;

/**
 Checks if a point is inside a circle.
 
 @param point The point to check.
 @param center The center of the circle.
 @param radius The radius of the circle in meters.
 @return YES if point is inside the circle.
 */
+ (BOOL)isPoint:(CLLocation *)point insideCircleCenter:(CLLocationCoordinate2D)center radius:(double)radius;

@end

NS_ASSUME_NONNULL_END

