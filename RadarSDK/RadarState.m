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

+ (CLLocation *)getCLLocation:(NSString *)key errorMessage:(NSString *)errorMessage {
    NSObject *RadarKVStoreObj = [[RadarKVStore sharedInstance] objectForKey:key];
    CLLocation *RadarKVStoreRes = nil;
    if (RadarKVStoreObj && [RadarKVStoreObj isKindOfClass:[CLLocation class]]) {
        RadarKVStoreRes = (CLLocation *)RadarKVStoreObj;
        if (!RadarKVStoreRes.isValid) {
            RadarKVStoreRes = nil;
        }
    }

    if ([RadarSettings useRadarKVStore]) {
        return RadarKVStoreRes;
    }

    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
    CLLocation *NSUserDefaultRes = [RadarUtils locationForDictionary:dict];
    if (!NSUserDefaultRes.isValid) {
        NSUserDefaultRes = nil;
    }

    if (![RadarUtils compareCLLocation:RadarKVStoreRes with:NSUserDefaultRes]) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:errorMessage];
    }

    return NSUserDefaultRes; 
}

+ (CLLocation *)lastLocation {
    return [self getCLLocation:kLastLocation errorMessage:@"RadarState: lastLocation mismatch."];
}

+ (void)setLastLocation:(CLLocation *)lastLocation {
    if (!lastLocation.isValid) {
        return;
    }
    [[RadarKVStore sharedInstance] setObject:lastLocation forKey:kLastLocation];

    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:[RadarUtils dictionaryForLocation:lastLocation] forKey:kLastLocation];
    }
}

+ (CLLocation *)lastMovedLocation {
    return [self getCLLocation:kLastMovedLocation errorMessage:@"RadarState: lastMovedLocation mismatch."];
}

+ (void)setLastMovedLocation:(CLLocation *)lastMovedLocation {
    if (!lastMovedLocation.isValid) {
        return;
    }

    [[RadarKVStore sharedInstance] setObject:lastMovedLocation forKey:kLastMovedLocation];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:[RadarUtils dictionaryForLocation:lastMovedLocation] forKey:kLastMovedLocation];
    }
}

+ (NSDate *)lastMovedAt {
    NSObject *lastMovedAt = [[RadarKVStore sharedInstance] objectForKey:kLastMovedAt];
    NSDate *lastMovedAtDate = nil;
    if (lastMovedAt  && [lastMovedAt isKindOfClass:[NSDate class]]) {
        lastMovedAtDate = (NSDate *)lastMovedAt;
    }
    if ([RadarSettings useRadarKVStore]) {
        return lastMovedAtDate;
    }
    NSDate *NSUserDefaultRes = [[NSUserDefaults standardUserDefaults] objectForKey:kLastMovedAt];
    if ((lastMovedAtDate && ![lastMovedAtDate isEqual:NSUserDefaultRes]) || (NSUserDefaultRes && ![NSUserDefaultRes isEqual:lastMovedAtDate])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:@"RadarState: lastMovedAt mismatch."];
    }

    return NSUserDefaultRes;
}

+ (void)setLastMovedAt:(NSDate *)lastMovedAt {
    [[RadarKVStore sharedInstance] setObject:lastMovedAt forKey:kLastMovedAt];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:lastMovedAt forKey:kLastMovedAt];
    }
}

+ (BOOL)stopped {
    BOOL stopped = [[RadarKVStore sharedInstance] boolForKey:kStopped];
    if ([RadarSettings useRadarKVStore]) {
        return stopped;
    }
    BOOL NSUserDefaultRes = [[NSUserDefaults standardUserDefaults] boolForKey:kStopped];
    if (stopped != NSUserDefaultRes) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:@"RadarState: stopped mismatch."];
    }
    return NSUserDefaultRes;
}

+ (void)setStopped:(BOOL)stopped {
    [[RadarKVStore sharedInstance] setBool:stopped forKey:kStopped];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setBool:stopped forKey:kStopped];
    }
}

+ (void)updateLastSentAt {
    NSDate *now = [NSDate new];
    [[RadarKVStore sharedInstance] setObject:now forKey:kLastSentAt];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:now forKey:kLastSentAt];
    }
}

+ (NSDate *)lastSentAt {
    NSObject *lastSentAt = [[RadarKVStore sharedInstance] objectForKey:kLastSentAt];
    NSDate *lastSentAtDate = nil;
    if (lastSentAt  && [lastSentAt isKindOfClass:[NSDate class]]) {
        lastSentAtDate = (NSDate *)lastSentAt;
    }
    if ([RadarSettings useRadarKVStore]) {
        return lastSentAtDate;
    }
    NSDate *NSUserDefaultRes = [[NSUserDefaults standardUserDefaults] objectForKey:kLastSentAt];
    if ((lastSentAtDate && ![lastSentAtDate isEqual:NSUserDefaultRes]) || (NSUserDefaultRes && ![NSUserDefaultRes isEqual:lastSentAtDate])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:@"RadarState: lastSentAt mismatch."];
    }

    return NSUserDefaultRes;
}

+ (BOOL)canExit {
    BOOL canExit = [[RadarKVStore sharedInstance] boolForKey:kCanExit];
    if ([RadarSettings useRadarKVStore]) {
        return canExit;
    }
    BOOL NSUserDefaultRes = [[NSUserDefaults standardUserDefaults] boolForKey:kCanExit];
    if (canExit != NSUserDefaultRes) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:@"RadarState: canExit mismatch."];
    }
    return NSUserDefaultRes;
}

+ (void)setCanExit:(BOOL)canExit {
    [[RadarKVStore sharedInstance] setBool:canExit forKey:kCanExit];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setBool:canExit forKey:kCanExit];
    }
}

+ (CLLocation *)lastFailedStoppedLocation {
    return [self getCLLocation:kLastFailedStoppedLocation errorMessage:@"RadarState: lastFailedStoppedLocation mismatch."];
}

+ (void)setLastFailedStoppedLocation:(CLLocation *)lastFailedStoppedLocation {
    if (!lastFailedStoppedLocation.isValid) {
        [[RadarKVStore sharedInstance] setObject:nil forKey:kLastFailedStoppedLocation];
        if (![RadarSettings useRadarKVStore]) {
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kLastFailedStoppedLocation];
        }
        return;
    }
    [[RadarKVStore sharedInstance] setObject:lastFailedStoppedLocation forKey:kLastFailedStoppedLocation];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:[RadarUtils dictionaryForLocation:lastFailedStoppedLocation] forKey:kLastFailedStoppedLocation];
    }
}

+ (NSArray<NSString *> *)getStringarray:(NSString*)key errorMessage:(NSString*)errorMessage {
    NSObject *RadarKVStoreObj = [[RadarKVStore sharedInstance] objectForKey:key];
    NSArray<NSString *> *RadarKVStoreRes = nil;
    if (RadarKVStoreObj && [RadarKVStoreObj isKindOfClass:[NSArray class]]) {
        RadarKVStoreRes = (NSArray<NSString *> *)RadarKVStoreObj;
    }

    if ([RadarSettings useRadarKVStore]) {
        return RadarKVStoreRes;
    }

    NSArray<NSString *> *NSUserDefaultRes = [[NSUserDefaults standardUserDefaults] objectForKey:key];

    if ((NSUserDefaultRes && ![NSUserDefaultRes isEqual:RadarKVStoreRes]) || (RadarKVStoreRes && ![RadarKVStoreRes isEqual:NSUserDefaultRes])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:errorMessage];
    }

    return NSUserDefaultRes; 
}

+ (NSArray<NSString *> *)geofenceIds {
    return [self getStringarray:kGeofenceIds errorMessage:@"RadarState: geofenceIds mismatch."];
}

+ (void)setGeofenceIds:(NSArray<NSString *> *)geofenceIds {
    [[RadarKVStore sharedInstance] setObject:geofenceIds forKey:kGeofenceIds];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:geofenceIds forKey:kGeofenceIds];
    }
}

+ (NSString *)placeId {
    NSObject *placeId = [[RadarKVStore sharedInstance] objectForKey:kPlaceId];
    NSString *placeIdString = nil;
    if (placeId && [placeId isKindOfClass:[NSString class]]) {
        placeIdString = (NSString *)placeId;
    }
    if ([RadarSettings useRadarKVStore]) {
        return placeIdString;
    }
    NSString *NSUserDefaultRes = [[NSUserDefaults standardUserDefaults] stringForKey:kPlaceId];
    if ((placeIdString && ![placeIdString isEqual:NSUserDefaultRes]) || (NSUserDefaultRes && ![NSUserDefaultRes isEqual:placeIdString])) {
        [[RadarLogBuffer sharedInstance] write:RadarLogLevelError type:RadarLogTypeSDKError message:@"RadarState: placeId mismatch."];
    }
    return NSUserDefaultRes;
}

+ (void)setPlaceId:(NSString *)placeId {
    [[RadarKVStore sharedInstance] setObject:placeId forKey:kPlaceId];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:placeId forKey:kPlaceId];
    }
}

+ (NSArray<NSString *> *)regionIds {
    return [self getStringarray:kRegionIds errorMessage:@"RadarState: regionIds mismatch."];
}

+ (void)setRegionIds:(NSArray<NSString *> *)regionIds {
    [[RadarKVStore sharedInstance] setObject:regionIds forKey:kRegionIds];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:regionIds forKey:kRegionIds];
    }
}

+ (NSArray<NSString *> *)beaconIds {
    return [self getStringarray:kBeaconIds errorMessage:@"RadarState: beaconIds mismatch."];
}

+ (void)setBeaconIds:(NSArray<NSString *> *)beaconIds {
    [[RadarKVStore sharedInstance] setObject:beaconIds forKey:kBeaconIds];
    if (![RadarSettings useRadarKVStore]) {
        [[NSUserDefaults standardUserDefaults] setObject:beaconIds forKey:kBeaconIds];
    }
}

@end
