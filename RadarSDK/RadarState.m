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
        [migrationResultArray addObject:[NSString stringWithFormat:@"lastLocation: %@", [RadarUtils dictionaryToJson:lastLocationDict]]];
    }
    NSDictionary *lastMovedLocationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastMovedLocation];
    CLLocation *lastMovedLocation = [RadarUtils locationForDictionary:lastMovedLocationDict];
    if (lastMovedLocation.isValid) {
        [self setLastMovedLocation: lastMovedLocation];
        [migrationResultArray addObject:[NSString stringWithFormat:@"lastMovedLocation: %@", [RadarUtils dictionaryToJson:lastMovedLocationDict]]];
    }
    NSDate *lastMovedAt = [[NSUserDefaults standardUserDefaults] objectForKey:kLastMovedAt];
    [self setLastMovedAt: lastMovedAt];
    [migrationResultArray addObject:[NSString stringWithFormat:@"lastMovedAt: %@", lastMovedAt]];

    BOOL stopped = [[NSUserDefaults standardUserDefaults] boolForKey:kStopped];
    [self setStopped: stopped];
    [migrationResultArray addObject:[NSString stringWithFormat:@"stopped: %@", stopped ? @"YES" : @"NO"]];

    NSDate *lastSentAt = [[NSUserDefaults standardUserDefaults] objectForKey:kLastSentAt];
    [self updateLastSentAt];
    [migrationResultArray addObject:[NSString stringWithFormat:@"lastSentAt: %@", lastSentAt]];

    BOOL canExit = [[NSUserDefaults standardUserDefaults] boolForKey:kCanExit];
    [self setCanExit: canExit];
    [migrationResultArray addObject:[NSString stringWithFormat:@"canExit: %@", canExit ? @"YES" : @"NO"]];

    NSDictionary *lastFailedStoppedLocationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastFailedStoppedLocation];
    CLLocation *lastFailedStoppedLocation = [RadarUtils locationForDictionary:lastFailedStoppedLocationDict];
    if (lastFailedStoppedLocation.isValid) {
        [self setLastFailedStoppedLocation: lastFailedStoppedLocation];
        [migrationResultArray addObject:[NSString stringWithFormat:@"lastFailedStoppedLocation: %@", [RadarUtils dictionaryToJson:lastFailedStoppedLocationDict]]];
    }
    
    NSArray<NSString *> *geofenceIds = [[NSUserDefaults standardUserDefaults] objectForKey:kGeofenceIds];
    [self setGeofenceIds: geofenceIds];
    [migrationResultArray addObject:[NSString stringWithFormat:@"geofenceIds: %@", geofenceIds]];

    NSString *placeId = [[NSUserDefaults standardUserDefaults] stringForKey:kPlaceId];
    [self setPlaceId: placeId];
    [migrationResultArray addObject:[NSString stringWithFormat:@"placeId: %@", placeId]];

    NSArray<NSString *> *regionIds = [[NSUserDefaults standardUserDefaults] objectForKey:kRegionIds];
    [self setRegionIds: regionIds];
    [migrationResultArray addObject:[NSString stringWithFormat:@"regionIds: %@", regionIds]];

    NSArray<NSString *> *beaconIds = [[NSUserDefaults standardUserDefaults] objectForKey:kBeaconIds];
    [self setBeaconIds: beaconIds];
    [migrationResultArray addObject:[NSString stringWithFormat:@"beaconIds: %@", beaconIds]];

    NSString *migrationResultString = [migrationResultArray componentsJoinedByString:@"\n"];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Migration of RadarState: %@", migrationResultString]];
}

+ (CLLocation *)lastLocation {
    NSObject *lastLocationObject = [[RadarKVStore sharedInstance] objectForKey:kLastLocation];
    if (!lastLocationObject || ![lastLocationObject isKindOfClass:[CLLocation class]]) {
        return nil;
    }
    CLLocation *lastLocation = (CLLocation *)lastLocationObject;
    if (!lastLocation.isValid) {
        return nil;
    }
    return lastLocation;
}

+ (void)setLastLocation:(CLLocation *)lastLocation {
    if (!lastLocation.isValid) {
        return;
    }
    [[RadarKVStore sharedInstance] setObject:lastLocation forKey:kLastLocation];
}

+ (CLLocation *)lastMovedLocation {
    NSObject *lastMovedLocationObject = [[RadarKVStore sharedInstance] objectForKey:kLastMovedLocation];
    if (!lastMovedLocationObject || ![lastMovedLocationObject isKindOfClass:[CLLocation class]]) {
        return nil;
    }
    CLLocation *lastMovedLocation = (CLLocation *)lastMovedLocationObject;
    if (!lastMovedLocation.isValid) {
        return nil;
    }
    return lastMovedLocation;
}

+ (void)setLastMovedLocation:(CLLocation *)lastMovedLocation {
    if (!lastMovedLocation.isValid) {
        return;
    }

    [[RadarKVStore sharedInstance] setObject:lastMovedLocation forKey:kLastMovedLocation];
}

+ (NSDate *)lastMovedAt {
    NSObject *lastMovedAt = [[RadarKVStore sharedInstance] objectForKey:kLastMovedAt];
    if (!lastMovedAt || ![lastMovedAt isKindOfClass:[NSDate class]]) {
        return nil;
    }
    return (NSDate *)lastMovedAt;
}

+ (void)setLastMovedAt:(NSDate *)lastMovedAt {
    [[RadarKVStore sharedInstance] setObject:lastMovedAt forKey:kLastMovedAt];
}

+ (BOOL)stopped {
    return [[RadarKVStore sharedInstance] boolForKey:kStopped];
}

+ (void)setStopped:(BOOL)stopped {
    [[RadarKVStore sharedInstance] setBool:stopped forKey:kStopped];
}

+ (void)updateLastSentAt {
    NSDate *now = [NSDate new];
    [[RadarKVStore sharedInstance] setObject:now forKey:kLastSentAt];
}

+ (NSDate *)lastSentAt {
    NSObject *lastSentAt = [[RadarKVStore sharedInstance] objectForKey:kLastSentAt];
    if (!lastSentAt || ![lastSentAt isKindOfClass:[NSDate class]]) {
        return nil;
    }
    return (NSDate *)lastSentAt;
}

+ (BOOL)canExit {
    return [[RadarKVStore sharedInstance] boolForKey:kCanExit];
}

+ (void)setCanExit:(BOOL)canExit {
    [[RadarKVStore sharedInstance] setBool:canExit forKey:kCanExit];
}

+ (CLLocation *)lastFailedStoppedLocation {
    NSObject *lastFailedStoppedLocationObject = [[RadarKVStore sharedInstance] objectForKey:kLastFailedStoppedLocation];
    if (!lastFailedStoppedLocationObject || ![lastFailedStoppedLocationObject isKindOfClass:[CLLocation class]]) {
        return nil;
    }
    CLLocation *lastFailedStoppedLocation = (CLLocation *)lastFailedStoppedLocationObject;
    if (!lastFailedStoppedLocation.isValid) {
        return nil;
    }
    return lastFailedStoppedLocation;
}

+ (void)setLastFailedStoppedLocation:(CLLocation *)lastFailedStoppedLocation {
    if (!lastFailedStoppedLocation.isValid) {
        [[RadarKVStore sharedInstance] setObject:nil forKey:kLastFailedStoppedLocation];

        return;
    }
    [[RadarKVStore sharedInstance] setObject:lastFailedStoppedLocation forKey:kLastFailedStoppedLocation];
}

+ (NSArray<NSString *> *)geofenceIds {
    NSObject *geofenceIds = [[RadarKVStore sharedInstance] objectForKey:kGeofenceIds];
    if (!geofenceIds || ![geofenceIds isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return (NSArray<NSString *> *)geofenceIds;
}

+ (void)setGeofenceIds:(NSArray<NSString *> *)geofenceIds {
    [[RadarKVStore sharedInstance] setObject:geofenceIds forKey:kGeofenceIds];
}

+ (NSString *)placeId {
    NSObject *placeId = [[RadarKVStore sharedInstance] objectForKey:kPlaceId];
    if (!placeId || ![placeId isKindOfClass:[NSString class]]) {
        return nil;
    }
    return (NSString *)placeId;
}

+ (void)setPlaceId:(NSString *)placeId {
    [[RadarKVStore sharedInstance] setObject:placeId forKey:kPlaceId];
}

+ (NSArray<NSString *> *)regionIds {
    NSObject *regionIds = [[RadarKVStore sharedInstance] objectForKey:kRegionIds];
    if (!regionIds || ![regionIds isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return (NSArray<NSString *> *)regionIds;
}

+ (void)setRegionIds:(NSArray<NSString *> *)regionIds {
    [[RadarKVStore sharedInstance] setObject:regionIds forKey:kRegionIds];
}

+ (NSArray<NSString *> *)beaconIds {
    NSObject *beaconIds = [[RadarKVStore sharedInstance] objectForKey:kBeaconIds];
    if (!beaconIds || ![beaconIds isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return (NSArray<NSString *> *)beaconIds;
}

+ (void)setBeaconIds:(NSArray<NSString *> *)beaconIds {
    [[RadarKVStore sharedInstance] setObject:beaconIds forKey:kBeaconIds];
}

@end
