//
//  RadarEfficientTrackManager.m
//  RadarSDK
//
//  Created by Alan Charles on 1/21/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarEfficientTrackManager.h"
#import "RadarState.h"
#import "RadarLogger.h"
#import "RadarCircleGeometry+Internal.h"
#import "RadarPolygonGeometry+Internal.h"
#import "RadarPlace+Internal.h"
#import "Radar.h"

@implementation RadarEfficientTrackManager

static const double kPlaceDetectionRadius = 100.0;

+ (BOOL)shouldTrackLocation:(CLLocation *)location options:(RadarTrackingOptions *)options {
    CLCircularRegion *syncedRegion = [RadarState syncedRegion];
    if (syncedRegion == nil) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"EfficientTrack: No synced region, should track"];
        
        return YES;
    }
    
    if ([self isOutsideSyncedRegion:location]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"EfficientTrack: Outside synced region, should track"];
        
        return YES;
    }
    
    if ([Radar getTripOptions] != nil) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"EfficientTrack: On active trip, should always track"];
        
        return YES;
    }
    
    if (options.syncOnGeofenceEvents && [self hasGeofenceStateChanged:location]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"EfficientTrack: Geofence state changed, should track"];
        
        return YES;
    }
    
    if (options.syncOnPlaceEvents && [self hasPlacesStateChanged:location]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"EfficientTrack: Places state changed, should track"];
        
        return YES;
    }
    
    if (options.syncOnBeaconEvents && [self hasBeaconStateChanged:location]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"EfficientTrack: Beacon state changed, should track"];
        
        return YES;
    }
    
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"EfficientTrack: No state change detected, skipping track"];
    
    return NO;
}


+ (BOOL)hasGeofenceStateChanged:(CLLocation *)location {
    NSArray<NSString *> *lastKnownGeofenceIds = [RadarState geofenceIds];
    NSArray<RadarGeofence *> *currentGeofences = [self getGeofencesForLocation: location];
    
    NSMutableSet<NSString *> *currentGeofenceIds = [NSMutableSet set];
    for (RadarGeofence *geofence in currentGeofences) {
        if (geofence._id) {
            [currentGeofenceIds addObject:geofence._id];
        }
    }
    
    NSSet<NSString *> *lastKnownSet = lastKnownGeofenceIds ? [NSSet setWithArray:lastKnownGeofenceIds] : [NSSet set];
    
    for (NSString *currentId in currentGeofenceIds) {
        if (![lastKnownSet containsObject:currentId]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"EfficientTrack: Detected geofence entry: %@", currentId]];
            
            return YES;
        }
    }
    
    for (NSString *lastKnownId in lastKnownGeofenceIds) {
        if (![currentGeofenceIds containsObject:lastKnownId]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"EfficientTrack: Detected geofence exit: %@", lastKnownId]];
            
            return YES;
        }
    }
    
    return NO;
}

+ (NSArray<RadarGeofence *> *)getGeofencesForLocation:(CLLocation *)location {
    NSArray<RadarGeofence *> *nearbyGeofences = [RadarState nearbyGeofences];
    if (nearbyGeofences == nil || nearbyGeofences.count == 0) {
        return @[];
    }
    
    NSMutableArray<RadarGeofence *> *userGeofences = [NSMutableArray array];
    
    for (RadarGeofence *geofence in nearbyGeofences) {
        RadarCoordinate *center = nil;
        double radius = 100;
        
        if ([geofence.geometry isKindOfClass:[RadarCircleGeometry class]]) {
            RadarCircleGeometry *geometry = (RadarCircleGeometry *)geofence.geometry;
            center = geometry.center;
            radius = geometry.radius;
        } else if ([geofence.geometry isKindOfClass:[RadarPolygonGeometry class]]) {
            RadarPolygonGeometry *geometry = (RadarPolygonGeometry *)geofence.geometry;
            center = geometry.center;
            radius = geometry.radius;
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"EfficientTrack: Skipping geofence with unsupported geometry"];
            
            continue;
        }
        
        if (center && [self isPoint:location insideCircleCenter:center.coordinate radius:radius]) {
            [userGeofences addObject:geofence];
        }
    }
    
    return  userGeofences;
}

+ (NSArray<RadarBeacon *> *)getBeaconsForLocation:(CLLocation *)location {
    NSArray<RadarBeacon *> *nearbyBeacons = [RadarState nearbyBeacons];
    if (nearbyBeacons == nil || nearbyBeacons.count == 0) {
        return @[];
    }
    
    NSMutableArray<RadarBeacon *> *userBeacons = [NSMutableArray array];
    
    static const double kBeaconRange = 100.0;
    
    for (RadarBeacon *beacon in nearbyBeacons) {
        if (beacon.geometry != nil) {
            CLLocation *beaconLocation = [[CLLocation alloc] initWithLatitude:beacon.geometry.coordinate.latitude longitude:beacon.geometry.coordinate.longitude];
            CLLocationDistance distance = [location distanceFromLocation:beaconLocation];
            
            if (distance <= kBeaconRange) {
                [userBeacons addObject:beacon];
            }
        }
    }
    
    return userBeacons;
}

+ (BOOL)hasBeaconStateChanged:(CLLocation *)location {
    NSArray<NSString *> *lastKnownBeaconIds = [RadarState beaconIds];
    NSArray<RadarBeacon *> *currentBeacons = [self getBeaconsForLocation:location];
    
    NSMutableSet<NSString *> *currentBeaconIds = [NSMutableSet set];
    for (RadarBeacon *beacon in currentBeacons) {
        if (beacon._id) {
            [currentBeaconIds addObject:beacon._id];
        }
    }
    
    NSSet<NSString *> *lastKnownSet = lastKnownBeaconIds ? [NSSet setWithArray:lastKnownBeaconIds] : [NSSet set];
    
    for (NSString *currentId in currentBeaconIds) {
        if (![lastKnownSet containsObject:currentId]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"EfficientTrack: Detected beacon entry: %@", currentId]];
            
            return YES;
        }
    }
    
    for (NSString *lastKnownId in lastKnownBeaconIds) {
        if (![currentBeaconIds containsObject:lastKnownId]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"EfficientTrack: Detected beacon exit: %@", lastKnownId]];
            
            return YES;
        }
    }
    
    return NO;
}

+ (NSArray<RadarPlace *> *)getPlacesForLocation:(CLLocation *)location {
    NSArray<RadarPlace *> *nearbyPlaces = [RadarState nearbyPlaces];
    if (nearbyPlaces == nil || nearbyPlaces.count == 0) {
        return @[];
    }
    
    NSMutableArray<RadarPlace *> *userPlaces = [NSMutableArray array];
    
    for (RadarPlace *place in nearbyPlaces) {
        if (place.location != nil) {
            if ([self isPoint:location insideCircleCenter:place.location.coordinate radius:kPlaceDetectionRadius]) {
                [userPlaces addObject:place];
            }
        }
    }
    
    return userPlaces;
}

+ (BOOL)hasPlacesStateChanged:(CLLocation *)location {
    NSString *lastKnownPlaceId = [RadarState placeId];
    NSArray<RadarPlace *> *currentPlaces = [self getPlacesForLocation:location];
    
    NSMutableSet<NSString *> *currentPlaceIds = [NSMutableSet set];
    for (RadarPlace *place in currentPlaces) {
        if (place._id) {
            [currentPlaceIds addObject:place._id];
        }
    }
    
    BOOL wasInPlace = (lastKnownPlaceId != nil && lastKnownPlaceId.length > 0);
    BOOL isInPlace = [currentPlaceIds containsObject:lastKnownPlaceId];
    
    // Entry: now in a place that isn't the last known one
    if (currentPlaceIds.count > 0 && !isInPlace) {
        return YES;
    }
    
    // Exit: was in a place but no longer in any place (or different place)
    if (wasInPlace && ![currentPlaceIds containsObject:lastKnownPlaceId]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)isOutsideSyncedRegion:(CLLocation *)location {
    CLCircularRegion *syncedRegion = [RadarState syncedRegion];
    if (syncedRegion == nil) {
        return YES;
    }
    return ![syncedRegion containsCoordinate:location.coordinate];
}

+ (BOOL)isPoint:(CLLocation *)point insideCircleCenter:(CLLocationCoordinate2D)center radius:(double)radius {
    CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
    CLLocationDistance distance = [centerLocation distanceFromLocation:point];
    return distance <= radius;
}

@end
