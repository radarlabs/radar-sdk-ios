//
//  RadarState.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarState.h"
#import "CLLocation+Radar.h"
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
static NSString *const kLastHeadingData = @"radar-lastHeadingData";
static NSString *const kLastMotionActivityData = @"radar-lastMotionActivityData";
static NSString *const kLastAccelerometerData = @"radar-lastAccelerometerData";
static NSString *const kLastGyroData = @"radar-lastGyroData";
static NSString *const kLastMagnetometerData = @"radar-lastMagnetometerData";

+ (CLLocation *)lastLocation {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastLocation];
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
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kLastLocation];
}

+ (CLLocation *)lastMovedLocation {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastMovedLocation];
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
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kLastMovedLocation];
}

+ (NSDate *)lastMovedAt {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kLastMovedAt];
}

+ (void)setLastMovedAt:(NSDate *)lastMovedAt {
    [[NSUserDefaults standardUserDefaults] setObject:lastMovedAt forKey:kLastMovedAt];
}

+ (BOOL)stopped {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kStopped];
}

+ (void)setStopped:(BOOL)stopped {
    [[NSUserDefaults standardUserDefaults] setBool:stopped forKey:kStopped];
}

+ (void)updateLastSentAt {
    NSDate *now = [NSDate new];
    [[NSUserDefaults standardUserDefaults] setObject:now forKey:kLastSentAt];
}

+ (NSDate *)lastSentAt {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kLastSentAt];
}

+ (BOOL)canExit {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kCanExit];
}

+ (void)setCanExit:(BOOL)canExit {
    [[NSUserDefaults standardUserDefaults] setBool:canExit forKey:kCanExit];
}

+ (CLLocation *)lastFailedStoppedLocation {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastFailedStoppedLocation];
    CLLocation *lastFailedStoppedLocation = [RadarUtils locationForDictionary:dict];

    if (!lastFailedStoppedLocation.isValid) {
        return nil;
    }

    return lastFailedStoppedLocation;
}

+ (void)setLastFailedStoppedLocation:(CLLocation *)lastFailedStoppedLocation {
    if (!lastFailedStoppedLocation.isValid) {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kLastFailedStoppedLocation];

        return;
    }

    NSDictionary *dict = [RadarUtils dictionaryForLocation:lastFailedStoppedLocation];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kLastFailedStoppedLocation];
}

+ (NSArray<NSString *> *)geofenceIds {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kGeofenceIds];
}

+ (void)setGeofenceIds:(NSArray<NSString *> *)geofenceIds {
    [[NSUserDefaults standardUserDefaults] setObject:geofenceIds forKey:kGeofenceIds];
}

+ (NSString *)placeId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kPlaceId];
}

+ (void)setPlaceId:(NSString *)placeId {
    [[NSUserDefaults standardUserDefaults] setObject:placeId forKey:kPlaceId];
}

+ (NSArray<NSString *> *)regionIds {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kRegionIds];
}

+ (void)setRegionIds:(NSArray<NSString *> *)regionIds {
    [[NSUserDefaults standardUserDefaults] setObject:regionIds forKey:kRegionIds];
}

+ (NSArray<NSString *> *)beaconIds {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kBeaconIds];
}

+ (void)setBeaconIds:(NSArray<NSString *> *)beaconIds {
    [[NSUserDefaults standardUserDefaults] setObject:beaconIds forKey:kBeaconIds];
}

+ (NSDictionary *)lastHeadingData {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastHeadingData];
}

+ (void)setLastHeadingData:(NSDictionary *_Nullable)lastHeadingData {
    [[NSUserDefaults standardUserDefaults] setObject:lastHeadingData forKey:kLastHeadingData];
}

+ (NSDictionary *)lastMotionActivityData {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastMotionActivityData];
}

+ (void)setLastMotionActivityData:(NSDictionary *)lastMotionActivityData {
    [[NSUserDefaults standardUserDefaults] setObject:lastMotionActivityData forKey:kLastMotionActivityData];
}

+ (NSDictionary *)lastAccelerometerData {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastAccelerometerData];
}

+ (void)setLastAccelerometerData:(NSDictionary *)lastAccelerometerData {
    [[NSUserDefaults standardUserDefaults] setObject:lastAccelerometerData forKey:kLastAccelerometerData];
}

+ (NSDictionary *)lastGyroData {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastGyroData];
}

+ (void)setLastGyroData:(NSDictionary *_Nullable)lastGyroData {
    [[NSUserDefaults standardUserDefaults] setObject:lastGyroData forKey:kLastGyroData];
}

+ (NSDictionary *)lastMagnetometerData {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastMagnetometerData];
}

+ (void)setLastMagnetometerData:(NSDictionary *_Nullable)lastMagnetometerData {
    [[NSUserDefaults standardUserDefaults] setObject:lastMagnetometerData forKey:kLastMagnetometerData];
}

@end
