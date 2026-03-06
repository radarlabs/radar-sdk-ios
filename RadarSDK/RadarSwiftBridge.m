//
//  RadarSwiftBridge.m
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarSwiftBridge.h"
#import "RadarReplayBuffer.h"
#import "Radar+Internal.h"
#import "RadarState.h"
#import "RadarAPIClient.h"

@implementation RadarSwiftBridge

- (void)setLogBufferPersistantLog:(BOOL)value {
    [[RadarLogBuffer sharedInstance] setPersistentLogFeatureFlag:value];
}

- (void)writeToLogBufferWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString * _Nonnull)message forcePersist:(BOOL)forcePersist {
    [[RadarLogBuffer sharedInstance] write:level type:type message:message forcePersist:forcePersist];
}

- (void)flushReplays {
    [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
}

- (void)logOpenedAppConversion {
    [Radar logOpenedAppConversion];
}

- (CLCircularRegion * _Nullable)syncedRegion {
    return [RadarState syncedRegion];
}

- (NSArray<NSString *> * _Nullable)geofenceIds {
    return [RadarState geofenceIds];
}

- (NSArray<NSString *> * _Nullable)beaconIds {
    return [RadarState beaconIds];
}

- (NSString * _Nullable)placeId {
    return [RadarState placeId];
}

- (NSArray<RadarGeofence *> * _Nullable)geofencesFromObject:(id _Nonnull)object {
    return [RadarGeofence geofencesFromObject:object];
}

- (NSArray<RadarPlace *> * _Nullable)placesFromObject:(id _Nonnull)object {
    return [RadarPlace placesFromObject:object];
}

- (NSArray<RadarBeacon *> * _Nullable)beaconsFromObject:(id _Nonnull)object {
    return [RadarBeacon beaconsFromObject:object];
}

- (NSArray<RadarGeofence *> * _Nullable)syncedGeofences {
    return [RadarState syncedGeofences];
}

- (NSArray<RadarBeacon *> * _Nullable)syncedBeacons {
    return [RadarState syncedBeacons];
}

- (NSArray<RadarPlace *> * _Nullable)syncedPlaces {
    return [RadarState syncedPlaces];
}

- (RadarTripOptions * _Nullable)getTripOptions {
    return [Radar getTripOptions];
}

- (CLLocation * _Nullable)lastLocation {
    return [RadarState lastLocation];
}

- (void)fetchSyncRegionWithLatitude:(double)latitude longitude:(double)longitude completionHandler:(void (^)(RadarStatus status, NSDictionary * _Nullable res))completionHandler {
    [[RadarAPIClient sharedInstance] syncRegionWithLatitude:latitude longitude:longitude completionHandler:completionHandler];
}

- (void)setSyncedGeofences:(NSArray<RadarGeofence *> * _Nullable)geofences {
    [RadarState setSyncedGeofences:geofences];
}

- (void)setSyncedBeacons:(NSArray<RadarBeacon *> * _Nullable)beacons {
    [RadarState setSyncedBeacons:beacons];
}

- (void)setSyncedPlaces:(NSArray<RadarPlace *> * _Nullable)places {
    [RadarState setSyncedPlaces:places];
}

- (void)setSyncedRegion:(CLCircularRegion * _Nullable)region {
    [RadarState setSyncedRegion:region];
}

- (NSArray<NSString *> * _Nonnull)lastSyncedGeofenceIds {
    return [RadarState lastSyncedGeofenceIds];
}

- (void)setLastSyncedGeofenceIds:(NSArray<NSString *> * _Nullable)ids {
    [RadarState setLastSyncedGeofenceIds:ids];
}

- (NSArray<NSString *> * _Nonnull)lastSyncedPlaceIds {
    return [RadarState lastSyncedPlaceIds];
}

- (void)setLastSyncedPlaceIds:(NSArray<NSString *> * _Nullable)ids {
    [RadarState setLastSyncedPlaceIds:ids];
}

- (NSArray<NSString *> * _Nonnull)lastSyncedBeaconIds {
    return [RadarState lastSyncedBeaconIds];
}

- (void)setLastSyncedBeaconIds:(NSArray<NSString *> * _Nullable)ids {
    [RadarState setLastSyncedBeaconIds:ids];
}

- (NSDictionary<NSString *, NSDate *> * _Nonnull)geofenceEntryTimestamps {
    return [RadarState geofenceEntryTimestamps];
}

- (void)setGeofenceEntryTimestamps:(NSDictionary<NSString *, NSDate *> * _Nullable)timestamps {
    [RadarState setGeofenceEntryTimestamps:timestamps];
}

- (NSArray<NSString *> * _Nonnull)dwellEventsFired {
    return [RadarState dwellEventsFired];
}

- (void)setDwellEventsFired:(NSArray<NSString *> * _Nullable)ids {
    [RadarState setDwellEventsFired:ids];
}

- (BOOL)isStopped {
    return [RadarState stopped];
}

@end
