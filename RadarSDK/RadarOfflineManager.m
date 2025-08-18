//
//  RadarOfflineManager.m
//  RadarSDK
//
//  Created by Kenny Hu on 10/16/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarOfflineManager.h"
#import "RadarState.h"
#import "RadarLogger.h"
#import "RadarSettings.h"
#import "RadarRemoteTrackingOptions.h"
#import "Radar+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarCircleGeometry.h"
#import "RadarPolygonGeometry.h"
#import "RadarCoordinate.h"

@implementation RadarOfflineManager

+ (NSArray<RadarGeofence *> *)getUserGeofencesFromLocation:(CLLocation *)location {
    NSArray<RadarGeofence *> *nearbyGeofences = [RadarState nearbyGeofences];
    if (!nearbyGeofences) {
        return @[];
    }

    NSMutableArray<RadarGeofence *> *userGeofences = [[NSMutableArray alloc] init];

    for (RadarGeofence *geofence in nearbyGeofences) {
        RadarCoordinate *center = nil;
        double radius = 100.0;

        if ([geofence.geometry isKindOfClass:[RadarCircleGeometry class]]) {
            RadarCircleGeometry *circleGeometry = (RadarCircleGeometry *)geofence.geometry;
            center = circleGeometry.center;
            radius = circleGeometry.radius;
        } else if ([geofence.geometry isKindOfClass:[RadarPolygonGeometry class]]) {
            RadarPolygonGeometry *polygonGeometry = (RadarPolygonGeometry *)geofence.geometry;
            center = polygonGeometry.center;
            radius = polygonGeometry.radius;
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

+ (void)updateTrackingOptionsFromOfflineLocation:(NSArray<RadarGeofence *> *)userGeofences completionHandler:(void (^)(RadarConfig *))completionHandler {
    NSMutableArray<NSString *> *newGeofenceTags = [[NSMutableArray alloc] init];
    RadarSdkConfiguration *sdkConfig = [RadarSettings sdkConfiguration];

    for (RadarGeofence *userGeofence in userGeofences) {
        if (userGeofence.tag) {
            [newGeofenceTags addObject:userGeofence.tag];
        }
    }

    NSArray<NSString *> *rampUpGeofenceTags = [RadarRemoteTrackingOptions getGeofenceTagsWithKey:@"inGeofence" remoteTrackingOptions:(sdkConfig ? sdkConfig.remoteTrackingOptions : nil)];
    BOOL inRampedUpGeofence = NO;

    if (rampUpGeofenceTags) {
        NSSet *rampUpSet = [NSSet setWithArray:rampUpGeofenceTags];
        NSSet *newTagsSet = [NSSet setWithArray:newGeofenceTags];
        inRampedUpGeofence = [rampUpSet intersectsSet:newTagsSet];
    }

    RadarTrackingOptions *newTrackingOptions = nil;

    if (inRampedUpGeofence) {
        // ramp up
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ramping up from Radar offline manager"];
        newTrackingOptions = [RadarRemoteTrackingOptions getTrackingOptionsWithKey:@"inGeofence" remoteTrackingOptions:(sdkConfig ? sdkConfig.remoteTrackingOptions : nil)];
    } else {
        // ramp down if needed
        RadarTrackingOptions *onTripOptions = [RadarRemoteTrackingOptions getTrackingOptionsWithKey:@"onTrip" remoteTrackingOptions:(sdkConfig ? sdkConfig.remoteTrackingOptions : nil)];
        RadarTripOptions *tripOptions = [Radar getTripOptions];

        if (onTripOptions && tripOptions) {
            newTrackingOptions = onTripOptions;
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ramping down from Radar offline manager to trip tracking options"];
        } else {
            newTrackingOptions = [RadarRemoteTrackingOptions getTrackingOptionsWithKey:@"default" remoteTrackingOptions:(sdkConfig ? sdkConfig.remoteTrackingOptions : nil)];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ramping down from Radar offline manager to default tracking options"];
        }
    }

    if (newTrackingOptions) {
        NSDictionary *metaDict = @{@"trackingOptions": [newTrackingOptions dictionaryValue]};
        NSDictionary *configDict = @{@"meta": metaDict};
        RadarConfig *radarConfig = [RadarConfig fromDictionary:configDict];
        if (radarConfig) {
            return completionHandler(radarConfig);
        }
    }

    return completionHandler(nil);
}

+ (void)generateEventsFromOfflineLocations:(CLLocation *)location userGeofences:(NSArray<RadarGeofence *> *)userGeofences completionHandler:(void (^)(NSArray<RadarEvent *> *, RadarUser *, CLLocation *))completionHandler {
    RadarUser *user = [RadarState radarUser];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"Got this user: %@", user]];

    if (!user) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"error getting user from offline manager"];
        return completionHandler(@[], user, location);
    }

    // generate geofence entry and exit events
    NSArray<RadarGeofence *> *nearbyGeofences = [RadarState nearbyGeofences];
    NSArray<NSString *> *previousUserGeofenceIds = [RadarState geofenceIds];
    NSMutableArray<RadarEvent *> *events = [[NSMutableArray alloc] init];
    NSMutableArray<NSString *> *newUserGeofenceIds = [[NSMutableArray alloc] init];

    // Check for geofence entries
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
            if (event) {
                [events addObject:event];
            } else {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"error parsing event from offline manager"];
            }
        }
        [newUserGeofenceIds addObject:userGeofence._id];
    }

    // Check for geofence exits
    for (NSString *previousGeofenceId in previousUserGeofenceIds) {
        if (![newUserGeofenceIds containsObject:previousGeofenceId]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"Adding geofence exit event for: %@", previousGeofenceId]];

            RadarGeofence *exitGeofence = nil;
            for (RadarGeofence *geofence in nearbyGeofences) {
                if ([geofence._id isEqualToString:previousGeofenceId]) {
                    exitGeofence = geofence;
                    break;
                }
            }

            NSDictionary *eventDict = @{
                @"_id": previousGeofenceId,
                @"createdAt": [[RadarUtils isoDateFormatter] stringFromDate:[NSDate date]],
                @"actualCreatedAt": [[RadarUtils isoDateFormatter] stringFromDate:[NSDate date]],
                @"live": @([RadarUtils isLive]),
                @"type": @"user.exited_geofence",
                @"geofence": exitGeofence ? [exitGeofence dictionaryValue] : [NSNull null],
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
            if (event) {
                [events addObject:event];
            } else {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"error parsing event from offline manager"];
            }
        }
    }

    NSMutableArray *userGeofenceDicts = [[NSMutableArray alloc] init];
    for (RadarGeofence *geofence in userGeofences) {
        [userGeofenceDicts addObject:[geofence dictionaryValue]];
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
        @"geofences": userGeofenceDicts,
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
    if (newUser) {
        completionHandler([events copy], newUser, location);
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"error parsing user from offline manager"];
        completionHandler([events copy], user, location);
    }
}

+ (BOOL)isPointInsideCircleWithCenter:(CLLocationCoordinate2D)center radius:(double)radius point:(CLLocation *)point {
    CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
    CLLocationDistance distance = [centerLocation distanceFromLocation:point];
    return distance <= radius;
}

@end
