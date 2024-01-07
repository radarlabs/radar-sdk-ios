//
//  RadarState.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarState.h"
#import "CLLocation+Radar.h"
#import "RadarUtils.h"
#import "RadarUserDefaults.h"

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

+(void)migrateIfNeeded {
    if (![[RadarUserDefaults sharedInstance] migrationCompleteFlag]) {
        NSDictionary *lastLocationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastLocation];
        CLLocation *lastLocation = [RadarUtils locationForDictionary:lastLocationDict];

        if (lastLocation.isValid) {
            [self setLastLocation: lastLocation];
        }
        NSDictionary *lastMovedLocationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastMovedLocation];
        CLLocation *lastMovedLocation = [RadarUtils locationForDictionary:lastMovedLocationDict];
        if (lastMovedLocation.isValid) {
            [self setLastMovedLocation: lastMovedLocation];
        }
        [self setLastMovedAt:[[NSUserDefaults standardUserDefaults] objectForKey:kLastMovedAt]];
        [self setStopped:[[NSUserDefaults standardUserDefaults] boolForKey:kStopped]];
        [[RadarUserDefaults sharedInstance] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kLastSentAt] forKey:kLastSentAt];
        [self setCanExit:[[NSUserDefaults standardUserDefaults] boolForKey:kCanExit]];
        NSDictionary *lastFailedStoppedLocationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastFailedStoppedLocation];
        CLLocation *lastFailedStoppedLocation = [RadarUtils locationForDictionary:lastFailedStoppedLocationDict];
        if (lastFailedStoppedLocation.isValid) {
            [self setLastFailedStoppedLocation: lastFailedStoppedLocation];
        }
        [self setGeofenceIds:[[NSUserDefaults standardUserDefaults] objectForKey:kGeofenceIds]];
        [self setPlaceId:[[NSUserDefaults standardUserDefaults] stringForKey:kPlaceId]];
        [self setRegionIds:[[NSUserDefaults standardUserDefaults] objectForKey:kRegionIds]];
        [self setBeaconIds:[[NSUserDefaults standardUserDefaults] objectForKey:kBeaconIds]];
        [[RadarUserDefaults sharedInstance] setMigrationCompleteFlag:YES];
    }
}

+ (CLLocation *)lastLocation {
    NSDictionary *dict = [[RadarUserDefaults sharedInstance] dictionaryForKey:kLastLocation];
    CLLocation *lastLocation = [RadarUtils locationForDictionary:dict];

    if (!lastLocation.isValid) {
        return nil;
    }

    return lastLocation;
}

+ (void)setLastLocation:(CLLocation *)lastLocation {
    if (!lastLocation.isValid) {
        return;
    }

    NSDictionary *dict = [RadarUtils dictionaryForLocation:lastLocation];
    [[RadarUserDefaults sharedInstance] setDictionary:dict forKey:kLastLocation];
}

+ (CLLocation *)lastMovedLocation {
    NSDictionary *dict = [[RadarUserDefaults sharedInstance] dictionaryForKey:kLastMovedLocation];
    CLLocation *lastMovedLocation = [RadarUtils locationForDictionary:dict];

    if (!lastMovedLocation.isValid) {
        return nil;
    }

    return lastMovedLocation;
}

+ (void)setLastMovedLocation:(CLLocation *)lastMovedLocation {
    if (!lastMovedLocation.isValid) {
        return;
    }

    NSDictionary *dict = [RadarUtils dictionaryForLocation:lastMovedLocation];
    [[RadarUserDefaults sharedInstance] setDictionary:dict forKey:kLastMovedLocation];
}

+ (NSDate *)lastMovedAt {
    NSObject *lastMovedAt = [[RadarUserDefaults sharedInstance] objectForKey:kLastMovedAt];
    if (!lastMovedAt || ![lastMovedAt isKindOfClass:[NSDate class]]) {
        return nil;
    }
    return (NSDate *)lastMovedAt;
}

+ (void)setLastMovedAt:(NSDate *)lastMovedAt {
    [[RadarUserDefaults sharedInstance] setObject:lastMovedAt forKey:kLastMovedAt];
}

+ (BOOL)stopped {
    return [[RadarUserDefaults sharedInstance] boolForKey:kStopped];
}

+ (void)setStopped:(BOOL)stopped {
    [[RadarUserDefaults sharedInstance] setBool:stopped forKey:kStopped];
}

+ (void)updateLastSentAt {
    NSDate *now = [NSDate new];
    [[RadarUserDefaults sharedInstance] setObject:now forKey:kLastSentAt];
}

+ (NSDate *)lastSentAt {
    NSObject *lastSentAt = [[RadarUserDefaults sharedInstance] objectForKey:kLastSentAt];
    if (!lastSentAt || ![lastSentAt isKindOfClass:[NSDate class]]) {
        return nil;
    }
    return (NSDate *)lastSentAt;
}

+ (BOOL)canExit {
    return [[RadarUserDefaults sharedInstance] boolForKey:kCanExit];
}

+ (void)setCanExit:(BOOL)canExit {
    [[RadarUserDefaults sharedInstance] setBool:canExit forKey:kCanExit];
}

+ (CLLocation *)lastFailedStoppedLocation {
    NSDictionary *dict = [[RadarUserDefaults sharedInstance] dictionaryForKey:kLastFailedStoppedLocation];
    CLLocation *lastFailedStoppedLocation = [RadarUtils locationForDictionary:dict];

    if (!lastFailedStoppedLocation.isValid) {
        return nil;
    }

    return lastFailedStoppedLocation;
}

+ (void)setLastFailedStoppedLocation:(CLLocation *)lastFailedStoppedLocation {
    if (!lastFailedStoppedLocation.isValid) {
        [[RadarUserDefaults sharedInstance] setDictionary:nil forKey:kLastFailedStoppedLocation];

        return;
    }

    NSDictionary *dict = [RadarUtils dictionaryForLocation:lastFailedStoppedLocation];
    [[RadarUserDefaults sharedInstance] setDictionary:dict forKey:kLastFailedStoppedLocation];
}

+ (NSArray<NSString *> *)geofenceIds {
    NSObject *geofenceIds = [[RadarUserDefaults sharedInstance] objectForKey:kGeofenceIds];
    if (!geofenceIds || ![geofenceIds isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return (NSArray<NSString *> *)geofenceIds;
}

+ (void)setGeofenceIds:(NSArray<NSString *> *)geofenceIds {
    [[RadarUserDefaults sharedInstance] setObject:geofenceIds forKey:kGeofenceIds];
}

+ (NSString *)placeId {
    NSObject *placeId = [[RadarUserDefaults sharedInstance] objectForKey:kPlaceId];
    if (!placeId || ![placeId isKindOfClass:[NSString class]]) {
        return nil;
    }
    return (NSString *)placeId;
}

+ (void)setPlaceId:(NSString *)placeId {
    [[RadarUserDefaults sharedInstance] setObject:placeId forKey:kPlaceId];
}

+ (NSArray<NSString *> *)regionIds {
    NSObject *regionIds = [[RadarUserDefaults sharedInstance] objectForKey:kRegionIds];
    if (!regionIds || ![regionIds isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return (NSArray<NSString *> *)regionIds;
}

+ (void)setRegionIds:(NSArray<NSString *> *)regionIds {
    [[RadarUserDefaults sharedInstance] setObject:regionIds forKey:kRegionIds];
}

+ (NSArray<NSString *> *)beaconIds {
    NSObject *beaconIds = [[RadarUserDefaults sharedInstance] objectForKey:kBeaconIds];
    if (!beaconIds || ![beaconIds isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return (NSArray<NSString *> *)beaconIds;
}

+ (void)setBeaconIds:(NSArray<NSString *> *)beaconIds {
    [[RadarUserDefaults sharedInstance] setObject:beaconIds forKey:kBeaconIds];
}

@end
