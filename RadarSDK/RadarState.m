//
//  RadarState.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarState.h"
#import "RadarGeofence+Internal.h"
#import "RadarBeacon+Internal.h"
#import "RadarPlace+Internal.h"
#import "CLLocation+Radar.h"
#import "RadarUtils.h"
#import "RadarLogger.h"

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
static NSString *const kLastPressureData = @"radar-lastPressureData";
static NSString *const kNotificationPermissionGranted = @"radar-notificationPermissionGranted";
static NSString *const kMotionAuthorization = @"radar-motionAuthorization";
static NSString *const kRegisteredNotifications = @"radar-registeredNotifications";
static NSString *const kNearbyGeofences = @"radar-nearbyGeofences";
static NSString *const kNearbyBeacons = @"radar-nearbyBeacons";
static NSString *const kNearbyPlaces = @"radar-nearbyPlaces";
static NSString *const kSyncedRegion = @"radar-syncedRegion";
static NSDictionary *_lastRelativeAltitudeDataInMemory = nil;
static NSDate *_lastPressureBackupTime = nil;
static NSTimeInterval const kBackupInterval = 2.0; // 2 seconds
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

+ (void) setTimeStamp:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:key];
}

+ (BOOL) isTimestampRecent:(NSString *)key {
    NSDate *lastTimeStamp = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (lastTimeStamp == nil) {
        return NO;
    }
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:lastTimeStamp];
    return timeInterval < 60;
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

+ (NSDictionary *)lastRelativeAltitudeData {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    // If we have a valid in-memory value, check its timestamp
    if (_lastRelativeAltitudeDataInMemory) {
        NSTimeInterval timestamp = [_lastRelativeAltitudeDataInMemory[@"relativeAltitudeTimestamp"] doubleValue];
        NSTimeInterval age = currentTime - timestamp;
        if (timestamp > 0 && age <= 60) {
            return _lastRelativeAltitudeDataInMemory;
        } else if (timestamp > 0) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:[NSString stringWithFormat:@"In-memory altitude data is stale (age: %.1f seconds) - will try persisted data", age]];
        }
    }
    
    // If in-memory value is invalid or too old, try to get from NSUserDefaults
    NSDictionary *savedData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastPressureData];
    if (savedData) {
        NSTimeInterval timestamp = [savedData[@"relativeAltitudeTimestamp"] doubleValue];
        NSTimeInterval age = currentTime - timestamp;
        if (timestamp > 0 && age <= 60) {
            // Update in-memory value if valid
            _lastRelativeAltitudeDataInMemory = savedData;
            return savedData;
        } else if (timestamp > 0) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:[NSString stringWithFormat:@"Persisted altitude data is also stale (age: %.1f seconds) - returning nil, altitude will be undefined", age]];
        }
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"No persisted altitude data found - altitude will be undefined"];
    }
    
    return nil;
}

+ (void)setLastRelativeAltitudeData:(NSDictionary *)lastPressureData {
    if (lastPressureData) {
        NSTimeInterval timestamp = [lastPressureData[@"relativeAltitudeTimestamp"] doubleValue];
        NSNumber *pressure = lastPressureData[@"pressure"];
        NSNumber *relativeAlt = lastPressureData[@"relativeAltitude"];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Storing new altitude data: timestamp=%.3f, pressure=%@ hPa, relative=%@ m", timestamp, pressure, relativeAlt]];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Clearing altitude data (nil passed)"];
    }
    
    // Update in-memory value
    _lastRelativeAltitudeDataInMemory = lastPressureData;
    
    // Check if we need to backup to disk
    NSDate *now = [NSDate date];
    if (!_lastPressureBackupTime || [now timeIntervalSinceDate:_lastPressureBackupTime] >= kBackupInterval) {
        [[NSUserDefaults standardUserDefaults] setObject:lastPressureData forKey:kLastPressureData];
        _lastPressureBackupTime = now;
        if (lastPressureData) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Backed up altitude data to disk"];
        }
    }
}

+ (void)setNotificationPermissionGranted:(BOOL)notificationPermissionGranted {
    [[NSUserDefaults standardUserDefaults] setBool:notificationPermissionGranted forKey:kNotificationPermissionGranted];
}

+ (BOOL)notificationPermissionGranted {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kNotificationPermissionGranted];
}

+ (void)setMotionAuthorizationString:(NSString *)status {
    [[NSUserDefaults standardUserDefaults] setObject:status forKey:kMotionAuthorization];
}

+ (NSString *)motionAuthorizationString {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kMotionAuthorization];
}

+ (NSArray<NSDictionary *> *_Nullable)registeredNotifications {
    NSArray<NSDictionary *> *registeredNotifications = [[NSUserDefaults standardUserDefaults] valueForKey:kRegisteredNotifications];
    return registeredNotifications;
}

+ (void)setRegisteredNotifications:(NSArray<NSDictionary *> *_Nullable)registeredNotifications {
    [[NSUserDefaults standardUserDefaults] setValue:registeredNotifications forKey:kRegisteredNotifications];
}


+ (void)addRegisteredNotification:(NSDictionary *)notification {
    NSMutableArray *registeredNotifications = [NSMutableArray new];
    NSArray *notifications = [RadarState registeredNotifications];
    if (notifications) {
        [registeredNotifications addObjectsFromArray:notifications];
    }
    [registeredNotifications addObject:notification];
    [RadarState setRegisteredNotifications:registeredNotifications];
}

+ (NSArray<RadarGeofence *> *_Nullable)nearbyGeofences {
    NSArray *geofenceDicts = [[NSUserDefaults standardUserDefaults] arrayForKey:kNearbyGeofences];
    if (!geofenceDicts) {
        return nil;
    }
    
    NSMutableArray<RadarGeofence *> *geofences = [NSMutableArray array];
    for (NSDictionary *dict in geofenceDicts) {
        RadarGeofence *geofence = [[RadarGeofence alloc] initWithObject:dict];
        if (geofence) {
            [geofences addObject:geofence];
        }
    }
    return geofences;
}

+ (void)setNearbyGeofences:(NSArray<RadarGeofence *> *_Nullable)nearbyGeofences {
    if (!nearbyGeofences) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kNearbyGeofences];
        return;
    }
    
    NSMutableArray<NSDictionary *> *geofenceDicts = [NSMutableArray array];
    for (RadarGeofence *geofence in nearbyGeofences) {
        [geofenceDicts addObject:[geofence dictionaryValue]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:geofenceDicts forKey:kNearbyGeofences];
}

+ (NSArray<RadarBeacon *> *_Nullable)nearbyBeacons {
    NSArray *beaconDicts = [[NSUserDefaults standardUserDefaults] arrayForKey:kNearbyBeacons];
    if(!beaconDicts) {
        return nil;
    }
    
    NSMutableArray<RadarBeacon *> *beacons = [NSMutableArray array];
    for (NSDictionary *dict in beaconDicts) {
        RadarBeacon *beacon = [[RadarBeacon alloc] initWithObject:dict];
        if (beacon) {
            [beacons addObject:beacon];
        }
    }
    return beacons;
}

+ (void)setNearbyBeacons:(NSArray<RadarBeacon *> *_Nullable)nearbyBeacons {
    if (!nearbyBeacons) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kNearbyBeacons];
        return;
    }
    NSMutableArray<NSDictionary *> *beaconDicts = [NSMutableArray array];
    for (RadarBeacon *beacon in nearbyBeacons) {
        [beaconDicts addObject:[beacon dictionaryValue]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:beaconDicts forKey:kNearbyBeacons];
}

+ (NSArray<RadarPlace *> *_Nullable)nearbyPlaces {
    NSArray *placeDicts = [[NSUserDefaults standardUserDefaults] arrayForKey:kNearbyPlaces];
    if (!placeDicts) {
        return nil;
    }
    
    NSMutableArray<RadarPlace *> *places = [NSMutableArray array];
    for (NSDictionary *dict in placeDicts) {
        RadarPlace *place = [[RadarPlace alloc] initWithObject:dict];
        if (place) {
            [places addObject:place];
        }
    }
    return places;
}

+ (void)setNearbyPlaces:(NSArray<RadarPlace *> *_Nullable)nearbyPlaces {
    if (!nearbyPlaces) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kNearbyPlaces];
        return;
    }
    
    NSMutableArray<NSDictionary *> *placesDicts = [NSMutableArray array];
    for (RadarPlace *place in nearbyPlaces) {
        [placesDicts addObject:[place dictionaryValue]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:placesDicts forKey:kNearbyPlaces];
}

+ (CLCircularRegion *_Nullable)syncedRegion {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSyncedRegion];
    if (!dict) {
        return nil;
    }
    return [RadarUtils circularRegionForDictionary:dict];
}

+ (void)setSyncedRegion:(CLCircularRegion *_Nullable)syncedRegion {
    if (!syncedRegion) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSyncedRegion];
        return;
    }
    
    NSDictionary *dict = [RadarUtils dictionaryForCircularRegion:syncedRegion];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kSyncedRegion];
}
@end
