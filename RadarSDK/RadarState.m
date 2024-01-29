//
//  RadarState.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarState.h"
#import "CLLocation+Radar.h"
#import "RadarUtils.h"
#import "RadarKVStore.h"
#import "RadarLogger.h"
#import "RadarSettings.h"
#import "RadarLogBuffer.h"
#import "RadarUtils.h"

@implementation RadarState

static NSString *const kLastLocation = @"radar-lastLocation";
static NSString *const kLastMovedLocation = @"radar-lastMovedLocation";
static NSString *const kLastMovedAt = @"radar-lastMovedAt";
static NSString *const kStopped = @"radar-stopped";
static NSString *const kLastSentAt = @"radar-lastSentAt";
static NSString *const kCanExit = @"radar-canExit";
static NSString *const kLastFailedStoppedLocation = @"radar-lastFailedStoppedLocation";
static NSString *const kGeofenceIds = @"radar-geofenceIds";
static NSString *const kPlaceId = @"radar-placeId";
static NSString *const kRegionIds = @"radar-regionIds";
static NSString *const kBeaconIds = @"radar-beaconIds";

+ (void)migrateToRadarKVStore {
    NSMutableArray<NSString *> *migrationResultArray = [[NSMutableArray alloc] init];

    NSDictionary *lastLocationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastLocation];
    CLLocation *lastLocation = [RadarUtils locationForDictionary:lastLocationDict];
    if (lastLocation.isValid) {
        [self setLastLocation: lastLocation];
        // Log for testing purposes only, to be removed before merging to master.
        [migrationResultArray addObject:[NSString stringWithFormat:@"lastLocation: %@", [RadarUtils dictionaryToJson:[RadarUtils dictionaryForLocation:[self lastLocation]]]]];
    }
    NSDictionary *lastMovedLocationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastMovedLocation];
    CLLocation *lastMovedLocation = [RadarUtils locationForDictionary:lastMovedLocationDict];
    if (lastMovedLocation.isValid) {
        [self setLastMovedLocation: lastMovedLocation];
        // Log for testing purposes only, to be removed before merging to master.
        [migrationResultArray addObject:[NSString stringWithFormat:@"lastMovedLocation: %@", [RadarUtils dictionaryToJson:[RadarUtils dictionaryForLocation:[self lastMovedLocation]]]]];
    }
    NSDate *lastMovedAt = [[NSUserDefaults standardUserDefaults] objectForKey:kLastMovedAt];
    [self setLastMovedAt: lastMovedAt];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"lastMovedAt: %@", [self lastMovedAt]]];

    BOOL stopped = [[NSUserDefaults standardUserDefaults] boolForKey:kStopped];
    [self setStopped: stopped];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"stopped: %@", [self stopped] ? @"YES" : @"NO"]];

    NSDate *lastSentAt = [[NSUserDefaults standardUserDefaults] objectForKey:kLastSentAt];
    [[RadarKVStore sharedInstance] setObject:lastSentAt forKey:kLastSentAt];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"lastSentAt: %@", [self lastSentAt]]];

    BOOL canExit = [[NSUserDefaults standardUserDefaults] boolForKey:kCanExit];
    [self setCanExit: canExit];
    //  Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"canExit: %@", [self canExit] ? @"YES" : @"NO"]];

    NSDictionary *lastFailedStoppedLocationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastFailedStoppedLocation];
    CLLocation *lastFailedStoppedLocation = [RadarUtils locationForDictionary:lastFailedStoppedLocationDict];
    if (lastFailedStoppedLocation.isValid) {
        [self setLastFailedStoppedLocation: lastFailedStoppedLocation];
        // Log for testing purposes only, to be removed before merging to master.
        [migrationResultArray addObject:[NSString stringWithFormat:@"lastFailedStoppedLocation: %@", [RadarUtils dictionaryToJson:[RadarUtils dictionaryForLocation:[self lastFailedStoppedLocation]]]]];
    }
    
    NSArray<NSString *> *geofenceIds = [[NSUserDefaults standardUserDefaults] objectForKey:kGeofenceIds];
    [self setGeofenceIds: geofenceIds];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"geofenceIds: %@", [self geofenceIds]]];

    NSString *placeId = [[NSUserDefaults standardUserDefaults] stringForKey:kPlaceId];
    [self setPlaceId: placeId];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"placeId: %@", [self placeId]]];

    NSArray<NSString *> *regionIds = [[NSUserDefaults standardUserDefaults] objectForKey:kRegionIds];
    [self setRegionIds: regionIds];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"regionIds: %@", [self regionIds]]];

    NSArray<NSString *> *beaconIds = [[NSUserDefaults standardUserDefaults] objectForKey:kBeaconIds];
    [self setBeaconIds: beaconIds];
    // Log for testing purposes only, to be removed before merging to master.
    [migrationResultArray addObject:[NSString stringWithFormat:@"beaconIds: %@", [self beaconIds]]];

    // Log for testing purposes only, to be removed before merging to master.
    NSString *migrationResultString = [migrationResultArray componentsJoinedByString:@", "];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Migration of RadarState: %@", migrationResultString]];
}


+ (CLLocation *)lastLocation {
    return [[RadarKVStore sharedInstance] wrappedCLLocationGetter:kLastLocation];
}

+ (void)setLastLocation:(CLLocation *)lastLocation {
    if (!lastLocation.isValid) {
        return;
    }

    [[RadarKVStore sharedInstance] wrappedCLLocationSetter:kLastLocation value:lastLocation];
}

+ (CLLocation *)lastMovedLocation {
    return [[RadarKVStore sharedInstance] wrappedCLLocationGetter:kLastMovedLocation];
}

+ (void)setLastMovedLocation:(CLLocation *)lastMovedLocation {
    if (!lastMovedLocation.isValid) {
        return;
    }
    [[RadarKVStore sharedInstance] wrappedCLLocationSetter:kLastMovedLocation value:lastMovedLocation];
}

+ (NSDate *)lastMovedAt {
    return [[RadarKVStore sharedInstance] wrappedDateGetter:kLastMovedAt];
}

+ (void)setLastMovedAt:(NSDate *)lastMovedAt {
    [[RadarKVStore sharedInstance] wrappedDateSetter:kLastMovedAt value:lastMovedAt];
}

+ (BOOL)stopped {
    return [[RadarKVStore sharedInstance] wrappedBOOLGetter:kStopped];
}

+ (void)setStopped:(BOOL)stopped {
    [[RadarKVStore sharedInstance] wrappedBOOLSetter:kStopped value:stopped];
}

+ (void)updateLastSentAt {
    NSDate *now = [NSDate new];
    [[RadarKVStore sharedInstance] wrappedDateSetter:kLastSentAt value:now];
}

+ (NSDate *)lastSentAt {
    return [[RadarKVStore sharedInstance] wrappedDateGetter:kLastSentAt];
}

+ (BOOL)canExit {
    return [[RadarKVStore sharedInstance] wrappedBOOLGetter:kCanExit];
}

+ (void)setCanExit:(BOOL)canExit {
    [[RadarKVStore sharedInstance] wrappedBOOLSetter:kCanExit value:canExit];
}

+ (CLLocation *)lastFailedStoppedLocation {
    return [[RadarKVStore sharedInstance] wrappedCLLocationGetter:kLastFailedStoppedLocation];
}

+ (void)setLastFailedStoppedLocation:(CLLocation *)lastFailedStoppedLocation {
    if (!lastFailedStoppedLocation.isValid) {
        [[RadarKVStore sharedInstance] wrappedCLLocationSetter:kLastFailedStoppedLocation value:nil];
        return;
    }
    [[RadarKVStore sharedInstance] wrappedCLLocationSetter:kLastFailedStoppedLocation value:lastFailedStoppedLocation];
}

+ (NSArray<NSString *> *)geofenceIds {
    return [[RadarKVStore sharedInstance] wrappedStringArrayGetter:kGeofenceIds];
}

+ (void)setGeofenceIds:(NSArray<NSString *> *)geofenceIds {
    [[RadarKVStore sharedInstance] wrappedStringArraySetter:kGeofenceIds value:geofenceIds];
}

+ (NSString *)placeId {
   return [[RadarKVStore sharedInstance] wrappedStringGetter:kPlaceId];
}

+ (void)setPlaceId:(NSString *)placeId {
    [[RadarKVStore sharedInstance] wrappedStringSetter:kPlaceId value:placeId];
}

+ (NSArray<NSString *> *)regionIds {
    return [[RadarKVStore sharedInstance] wrappedStringArrayGetter:kRegionIds];
}

+ (void)setRegionIds:(NSArray<NSString *> *)regionIds {
    [[RadarKVStore sharedInstance] wrappedStringArraySetter:kRegionIds value:regionIds];
}

+ (NSArray<NSString *> *)beaconIds {
    return [[RadarKVStore sharedInstance] wrappedStringArrayGetter:kBeaconIds];
}

+ (void)setBeaconIds:(NSArray<NSString *> *)beaconIds {
    [[RadarKVStore sharedInstance] wrappedStringArraySetter:kBeaconIds value:beaconIds];
}

@end
