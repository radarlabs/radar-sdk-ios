//
//  RadarOfflineManager.m
//  RadarSDK
//
//  Created by Alan Charles on 1/15/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarOfflineManager.h"
#import "RadarState.h"
#import "RadarSettings.h"
#import "RadarLogger.h"
#import "RadarCircleGeometry.h"
#import "RadarPolygonGeometry.h"
#import "RadarRemoteTrackingOptions.h"
#import "Radar.h"

@implementation RadarOfflineManager

+ (BOOL)isPointInsideCircleWithCenter:(CLLocationCoordinate2D)center radius:(double)radius point:(CLLocation *)point {
    CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
    CLLocationDistance distance = [centerLocation distanceFromLocation:point];
    return distance <= radius;
}

+ (NSArray<RadarGeofence *> *)getUserGeofencesFromLocation:(CLLocation *)location {
    NSArray<RadarGeofence *> *nearbyGeofences = [RadarState nearbyGeofences];
    if (nearbyGeofences == nil) {
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
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"error parsing geometry with no circular representation"];
            continue;
        }
        
        if ([self isPointInsideCircleWithCenter:center.coordinate radius:radius point:location]) {
            [userGeofences addObject:geofence];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Radar offline manager detected user inside geofence: %@", geofence._id]];
        }
    }
    
    return userGeofences;
}

+ (NSArray<RadarBeacon *> *)getBeaconsFromLocation:(CLLocation *)location {
    NSArray<RadarBeacon *> *nearbyBeacons = [RadarState nearbyBeacons];
    if (nearbyBeacons == nil) {
        return @[];
    }
    
    NSMutableArray<RadarBeacon *> *userBeacons = [NSMutableArray array];
    
    for (RadarBeacon *beacon in nearbyBeacons) {
        if (beacon.geometry != nil) {
            CLLocation *beaconLocation = [[CLLocation alloc] initWithLatitude:beacon.geometry.coordinate.latitude 
                                                                    longitude:beacon.geometry.coordinate.longitude];
            CLLocationDistance distance = [location distanceFromLocation:beaconLocation];
            
            // Bluetooth beacons typically have a range of 1-100 meters
            // Using a reasonable range of 100 meters for offline detection
            double beaconRange = 100.0;
            
            if (distance <= beaconRange) {
                [userBeacons addObject:beacon];
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Radar offline manager detected user near beacon: %@", beacon._id ?: @"unknown"]];
            }
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"error parsing beacon geometry for beacon: %@", beacon._id ?: @"unknown"]];
        }
    }
    
    return userBeacons;
}

+ (void)updateTrackingOptionsFromOfflineLocation:(NSArray<RadarGeofence *> *)userGeofences completionHandler:(void (^)(RadarConfig *))completionHandler {
    NSMutableArray<NSString *> *newGeofenceTags = [NSMutableArray array];
    RadarSdkConfiguration *sdkConfig = [RadarSettings sdkConfiguration];
    
    for (RadarGeofence *userGeofence in userGeofences) {
        if (userGeofence.tag != nil) {
            [newGeofenceTags addObject:userGeofence.tag];
        }
    }
    
    NSArray<NSString *> *rampUpGeofenceTags = [RadarRemoteTrackingOptions getGeofenceTagsWithKey:@"inGeofence" remoteTrackingOptions:sdkConfig.remoteTrackingOptions];
    BOOL inRampedUpGeofence = NO;
    
    if (rampUpGeofenceTags != nil) {
        NSSet<NSString *> *rampUpSet = [NSSet setWithArray:rampUpGeofenceTags];
        NSSet<NSString *> *newTagsSet = [NSSet setWithArray:newGeofenceTags];
        inRampedUpGeofence = [rampUpSet intersectsSet:newTagsSet];
    }
    
    RadarTrackingOptions *newTrackingOptions = nil;
    
    if (inRampedUpGeofence) {
        // ramp up
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ramping up from Radar offline manager"];
        newTrackingOptions = [RadarRemoteTrackingOptions getTrackingOptionsWithKey:@"inGeofence" remoteTrackingOptions:sdkConfig.remoteTrackingOptions];
    } else {
        // ramp down if needed
        RadarTrackingOptions *onTripOptions = [RadarRemoteTrackingOptions getTrackingOptionsWithKey:@"onTrip" remoteTrackingOptions:sdkConfig.remoteTrackingOptions];
        RadarTripOptions *tripOptions = [Radar getTripOptions];
        
        if (onTripOptions != nil && tripOptions != nil) {
            newTrackingOptions = onTripOptions;
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ramping down from Radar offline manager to trip tracking options"];
        } else {
            newTrackingOptions = [RadarRemoteTrackingOptions getTrackingOptionsWithKey:@"default" remoteTrackingOptions:sdkConfig.remoteTrackingOptions];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ramping down from Radar offline manager to default tracking options"];
        }
    }
    
    if (newTrackingOptions != nil) {
        NSDictionary *metaDict = @{@"trackingOptions": [newTrackingOptions dictionaryValue] ?: [NSNull null]};
        NSDictionary *configDict = @{@"meta": metaDict};
        RadarConfig *radarConfig = [RadarConfig fromDictionary:configDict];
        if (radarConfig != nil) {
            return completionHandler(radarConfig);
        }
    }
    
    return completionHandler(nil);
}

+ (void)generateEventsFromOfflineLocations:(CLLocation *)location userGeofences:(NSArray<RadarGeofence *> *)userGeofences completionHandler:(void (^)(NSArray<RadarEvent *> *, RadarUser *, CLLocation *))completionHandler {
    RadarUser *user = [RadarState radarUser];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"Got this user: %@", user]];
    
    if (user == nil) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"error getting user from offline manager"];
        return completionHandler(@[], user, location);
    }
    
    NSArray<RadarGeofence *> *nearbyGeofences = [RadarState nearbyGeofences];
    NSArray<NSString *> *previousUserGeofenceIds = [RadarState geofenceIds];
    NSMutableArray<RadarEvent *> *events = [NSMutableArray array];
    NSMutableArray<NSString *> *newUserGeofenceIds = [NSMutableArray array];
    
    // Generate geofence entry events
    for (RadarGeofence *userGeofence in userGeofences) {
        if (![previousUserGeofenceIds containsObject:userGeofence._id]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"Adding geofence entry event for: %@", userGeofence._id]];
            
            NSDictionary *eventDict = @{
                @"_id": userGeofence._id,
                @"createdAt": [[RadarUtils isoDateFormatter] stringFromDate:[NSDate date]],
                @"actualCreatedAt": [[RadarUtils isoDateFormatter] stringFromDate:[NSDate date]],
                @"live": @([RadarUtils isLive]),
                @"type": @"user.entered_geofence",
                @"geofence": [userGeofence dictionaryValue],
                @"verification": @(RadarEventVerificationUnverify),
                @"confidence": @(RadarEventConfidenceLow),
                @"duration": @0,
                @"location": @{
                    @"coordinates": @[@(location.coordinate.longitude), @(location.coordinate.latitude)]
                },
                @"locationAccuracy": @(location.horizontalAccuracy),
                @"replayed": @NO,
                @"metadata": @{@"offline": @YES}
            };
            
            RadarEvent *event = [[RadarEvent alloc] initWithObject:eventDict];
            if (event != nil) {
                [events addObject:event];
            } else {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"error parsing event from offline manager"];
            }
        }
        [newUserGeofenceIds addObject:userGeofence._id];
    }
    
    // Generate geofence exit events
    for (NSString *previousGeofenceId in previousUserGeofenceIds) {
        if (![newUserGeofenceIds containsObject:previousGeofenceId]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"Adding geofence exit event for: %@", previousGeofenceId]];
            
            // Find the geofence from nearby geofences
            id geofenceDict = [NSNull null];
            for (RadarGeofence *geofence in nearbyGeofences) {
                if ([geofence._id isEqualToString:previousGeofenceId]) {
                    geofenceDict = [geofence dictionaryValue];
                    break;
                }
            }
            
            NSDictionary *eventDict = @{
                @"_id": previousGeofenceId,
                @"createdAt": [[RadarUtils isoDateFormatter] stringFromDate:[NSDate date]],
                @"actualCreatedAt": [[RadarUtils isoDateFormatter] stringFromDate:[NSDate date]],
                @"live": @([RadarUtils isLive]),
                @"type": @"user.exited_geofence",
                @"geofence": geofenceDict,
                @"verification": @(RadarEventVerificationUnverify),
                @"confidence": @(RadarEventConfidenceLow),
                @"duration": @0,
                @"location": @{
                    @"coordinates": @[@(location.coordinate.longitude), @(location.coordinate.latitude)]
                },
                @"locationAccuracy": @(location.horizontalAccuracy),
                @"replayed": @NO,
                @"metadata": @{@"offline": @YES}
            };
            
            RadarEvent *event = [[RadarEvent alloc] initWithObject:eventDict];
            if (event != nil) {
                [events addObject:event];
            } else {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"error parsing event from offline manager"];
            }
        }
    }
    
    // Build new user dictionary
    NSMutableArray *geofenceDicts = [NSMutableArray array];
    for (RadarGeofence *geofence in userGeofences) {
        [geofenceDicts addObject:[geofence dictionaryValue]];
    }
    
    NSDictionary *newUserDict = @{
        @"_id": user._id ?: [NSNull null],
        @"userId": user.userId ?: [NSNull null],
        @"deviceId": user.deviceId ?: [NSNull null],
        @"description": user.__description ?: [NSNull null],
        @"metadata": user.metadata ?: [NSNull null],
        @"location": @{
            @"coordinates": @[@(location.coordinate.longitude), @(location.coordinate.latitude)]
        },
        @"locationAccuracy": @(location.horizontalAccuracy),
        @"activityType": @(user.activityType),
        @"geofences": geofenceDicts,
        @"place": user.place ?: [NSNull null],
        @"beacons": user.beacons ?: [NSNull null],
        @"stopped": @([RadarState stopped]),
        @"foreground": @([RadarUtils foreground]),
        @"country": user.country ?: [NSNull null],
        @"state": user.state ?: [NSNull null],
        @"dma": user.dma ?: [NSNull null],
        @"postalCode": user.postalCode ?: [NSNull null],
        @"nearbyPlaceChains": user.nearbyPlaceChains ?: [NSNull null],
        @"segments": user.segments ?: [NSNull null],
        @"topChains": user.topChains ?: [NSNull null],
        @"source": @(RadarLocationSourceOffline),
        @"trip": user.trip ?: [NSNull null],
        @"debug": @(user.debug),
        @"fraud": user.fraud ?: [NSNull null]
    };
    
    [RadarState setGeofenceIds:newUserGeofenceIds];
    
    RadarUser *newUser = [[RadarUser alloc] initWithObject:newUserDict];
    if (newUser != nil) {
        completionHandler(events, newUser, location);
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"error parsing user from offline manager"];
        completionHandler(events, user, location);
    }
}

@end
