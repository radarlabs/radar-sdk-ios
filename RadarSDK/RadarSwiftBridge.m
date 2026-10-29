//
//  RadarSwiftBridge.m
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarSwiftBridge.h"
#import "RadarBeacon+Internal.h"
#import "RadarEvent+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarUser+Internal.h"
#import "RadarReplayBuffer.h"
#import "Radar+Internal.h"
#import "RadarState.h"
#import "RadarLogger.h"
#import "RadarUtils.h"
#import "RadarDelegateHolder.h"
#import "RadarAPIClient.h"
#import "RadarIndoors.h"
#import "RadarLocationManager.h"

@interface RadarLocationManager (SwiftBeaconLocation)
- (void)handleLocation:(CLLocation *)location
                source:(RadarLocationSource)source
               beacons:(NSArray<RadarBeacon *> *)beacons;
@end

@implementation RadarSwiftBridge

- (void)flushReplays {
    [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
}

- (void)stopIndoorTracking {
    [[RadarIndoors shared] stopWithCompletionHandler:^{}];
}

- (void)updateIndoorTrackingWithGeofences:(NSArray<RadarGeofence *> *)geofences {
    [[RadarIndoors shared] updateTrackingWithGeofences:geofences completionHandler:^{}];
}

- (void)updateTracking {
    [[RadarLocationManager sharedInstance] updateTracking];
}

- (void)updateTrackingFromInitialize {
    [[RadarLocationManager sharedInstance] updateTrackingFromInitialize];
}

- (void)logOpenedAppConversion {
    [Radar logOpenedAppConversion];
}

- (NSArray<NSString *> * _Nullable)geofenceIds {
    return RadarState.shared.geofenceIds;
}

- (NSArray<NSString *> * _Nullable)beaconIds {
    return RadarState.shared.beaconIds;
}

- (NSString * _Nullable)placeId {
    return RadarState.shared.placeId;
}

- (RadarTripOptions * _Nullable)getTripOptions {
    return [Radar getTripOptions];
}

- (CLLocation * _Nullable)lastLocation {
    return RadarState.shared.lastLocation;
}

- (BOOL)isStopped {
    return RadarState.shared.stopped;
}

- (void)setStopped:(BOOL)stopped {
    RadarState.shared.stopped = stopped;
}

- (void)setLastLocation:(CLLocation * _Nullable)location {
    RadarState.shared.lastLocation = location;
}

- (CLLocation * _Nullable)lastMovedLocation {
    return RadarState.shared.lastMovedLocation;
}

- (void)setLastMovedLocation:(CLLocation * _Nullable)location {
    RadarState.shared.lastMovedLocation = location;
}

- (NSDate * _Nullable)lastMovedAt {
    return RadarState.shared.lastMovedAt;
}

- (void)setLastMovedAt:(NSDate *)date {
    RadarState.shared.lastMovedAt = date;
}

- (CLLocation * _Nullable)lastFailedStoppedLocation {
    return RadarState.shared.lastFailedStoppedLocation;
}

- (void)setLastFailedStoppedLocation:(CLLocation * _Nullable)location {
    RadarState.shared.lastFailedStoppedLocation = location;
}

- (NSDate * _Nullable)lastSentAt {
    return RadarState.shared.lastSentAt;
}

- (void)updateLastSentAt {
    [RadarState.shared updateLastSentAt];
}

- (BOOL)canExit {
    return RadarState.shared.canExit;
}

- (void)logCampaignConversionWithName:(NSString *)name metadata:(NSDictionary<NSString *, id> * _Nonnull)metadata campaign:(NSString * _Nullable)campaign {
    [Radar sendLogConversionRequestWithName:name metadata:metadata campaign:campaign completionHandler:^(RadarStatus status, RadarEvent * _Nullable event) {
        NSString *message = [NSString stringWithFormat:@"Conversion name = %@: status = %@; event = %@", event.conversionName, [Radar stringForStatus:status], event];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:message];
    }];
}

- (RadarEvent * _Nullable)createEventWithDict:(NSDictionary *)dict {
    return [[RadarEvent alloc] initWithObject:dict];
}

- (RadarUser * _Nullable)createUserWithDict:(NSDictionary *)dict {
    return [[RadarUser alloc] initWithObject:dict];
}

- (RadarGeofence * _Nullable)createGeofenceWithDict:(NSDictionary *)dict {
    return [[RadarGeofence alloc] initWithObject:dict];
}

- (RadarPlace * _Nullable)createPlaceWithDict:(NSDictionary *)dict {
    return [[RadarPlace alloc] initWithObject:dict];
}

- (BOOL)isForeground {
    return [RadarUtilsDeprecated foreground];
}

- (void)didReceiveEvents:(NSArray<RadarEvent *> *)events user:(RadarUser *)user {
    [[RadarDelegateHolder sharedInstance] didReceiveEvents:events user:user];
}

- (void)didUpdateClientLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source {
    [[RadarDelegateHolder sharedInstance] didUpdateClientLocation:location stopped:stopped source:source];
}

- (void)handleLocation:(CLLocation *)location source:(RadarLocationSource)source {
    [[RadarLocationManager sharedInstance] handleLocation:location source:source];
}

- (void)handleLocation:(CLLocation *)location source:(RadarLocationSource)source beacons:(NSArray<RadarBeacon *> *)beacons {
    [[RadarLocationManager sharedInstance] handleLocation:location source:source beacons:beacons];
}

- (RadarUser * _Nullable)radarUser {
    return RadarState.shared.radarUser;
}

- (void)flushReplaysRequest:(NSArray<NSDictionary *> *)replays
          completionHandler:(void (^)(RadarStatus, NSDictionary * _Nullable))completionHandler {
    [[RadarAPIClient sharedInstance] flushReplays:replays completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
        if (completionHandler) {
            completionHandler(status, res);
        }
    }];
}

- (void)didFailWithStatus:(RadarStatus)status {
    [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];
}

- (void)trackWithLocation:(CLLocation *)location
                  stopped:(BOOL)stopped
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
                  beacons:(NSArray<RadarBeacon *> *)beacons
           indoorLocation:(CLLocation *)indoorLocation
        completionHandler:(void (^)(RadarStatus, NSArray<RadarEvent *> *_Nullable, RadarUser *_Nullable, NSArray<RadarGeofence *> *_Nullable,
                                    RadarConfig *_Nullable))completionHandler {
    [[RadarAPIClient sharedInstance] trackWithLocation:location
                                               stopped:stopped
                                            foreground:[RadarUtilsDeprecated foreground]
                                                source:source
                                              replayed:replayed
                                               beacons:beacons
                                        indoorLocation:indoorLocation
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                         NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
        completionHandler(status, events, user, nearbyGeofences, config);
    }];
}

- (void)searchBeaconsNear:(CLLocation *)location
                   radius:(int)radius
                    limit:(int)limit
        completionHandler:(void (^)(RadarStatus, NSArray<RadarBeacon *> *_Nullable, NSArray<NSString *> *_Nullable))completionHandler {
    [[RadarAPIClient sharedInstance] searchBeaconsNear:location
                                                radius:radius
                                                 limit:limit
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons,
                                                         NSArray<NSString *> *_Nullable beaconUUIDs) {
        completionHandler(status, beacons, beaconUUIDs);
    }];
}

- (RadarBeacon * _Nonnull)createBeaconWithUuid:(NSString *)uuid major:(NSString *)major minor:(NSString *)minor rssi:(NSInteger)rssi {
    return [[RadarBeacon alloc] initWithUUID:uuid major:major minor:minor rssi:rssi];
}

- (RadarBeacon * _Nonnull)createBeaconFromRegion:(CLBeaconRegion *)region {
    return [RadarBeacon fromCLBeaconRegion:region];
}

- (void)setRssi:(NSInteger)rssi onBeacon:(RadarBeacon *)beacon {
    [beacon setRssi:rssi];
}

@end
