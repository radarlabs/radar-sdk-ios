//
//  RadarState.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarState.h"
#import "CLLocation+Radar.h"
#import "RadarUtils.h"
#import "RadarGeofence+Internal.h"
#import "RadarBeacon+Internal.h"
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
static NSString *const KNearbyGeofences = @"radar-nearbyGeofences";
static NSString *const kNearbyBeacons = @"radar-nearbyBeacons";
static NSString *const kRegisteredNotifications = @"radar-registeredNotifications";
static NSString *const kRadarUser = @"radar-radarUser";
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
    // If we have a valid in-memory value, check its timestamp
    if (_lastRelativeAltitudeDataInMemory) {
        NSTimeInterval timestamp = [_lastRelativeAltitudeDataInMemory[@"relativeAltitudeTimestamp"] doubleValue];
        if (timestamp > 0 && [[NSDate date] timeIntervalSince1970] - timestamp <= 60) {
            return _lastRelativeAltitudeDataInMemory;
        }
    }

    // If in-memory value is invalid or too old, try to get from NSUserDefaults
    NSDictionary *savedData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLastPressureData];
    if (savedData) {
        NSTimeInterval timestamp = [savedData[@"relativeAltitudeTimestamp"] doubleValue];
        if (timestamp > 0 && [[NSDate date] timeIntervalSince1970] - timestamp <= 60) {
            // Update in-memory value if valid
            _lastRelativeAltitudeDataInMemory = savedData;
            return savedData;
        }
    }

    return nil;
}

+ (void)setLastRelativeAltitudeData:(NSDictionary *)lastPressureData {
    // Update in-memory value
    _lastRelativeAltitudeDataInMemory = lastPressureData;

    // Check if we need to backup to disk
    NSDate *now = [NSDate date];
    if (!_lastPressureBackupTime || [now timeIntervalSinceDate:_lastPressureBackupTime] >= kBackupInterval) {
        [[NSUserDefaults standardUserDefaults] setObject:lastPressureData forKey:kLastPressureData];
        _lastPressureBackupTime = now;
    }
}

+ (void)setNotificationPermissionGranted:(BOOL)notificationPermissionGranted {
    [[NSUserDefaults standardUserDefaults] setBool:notificationPermissionGranted forKey:kNotificationPermissionGranted];
}

+ (BOOL)notificationPermissionGranted {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kNotificationPermissionGranted];
}

+ (void)setNearbyGeofences:(NSArray<RadarGeofence *> *_Nullable)nearbyGeofences {
    NSMutableArray *nearbyGeofencesArray = [NSMutableArray new];
    NSMutableArray *nearbyGeofencesArrayIds = [NSMutableArray new];
    for (RadarGeofence *geofence in nearbyGeofences) {
        [nearbyGeofencesArray addObject:[geofence dictionaryValue]];
        [nearbyGeofencesArrayIds addObject:geofence._id];
    }
    [[NSUserDefaults standardUserDefaults] setObject:nearbyGeofencesArray forKey:KNearbyGeofences];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"nearbyGeofencesArray in RadarState:%@", nearbyGeofencesArray]];

}

+ (NSArray<RadarGeofence *> *_Nullable)nearbyGeofences {
    NSArray *nearbyGeofencesArray = [[NSUserDefaults standardUserDefaults] objectForKey:KNearbyGeofences];
    if (!nearbyGeofencesArray) {
        return nil;
    }
    NSMutableArray *nearbyGeofences = [NSMutableArray new];
    for (NSDictionary *geofenceDict in nearbyGeofencesArray) {
        RadarGeofence *geofence = [[RadarGeofence alloc] initWithObject:geofenceDict];
        if (geofence) {
            [nearbyGeofences addObject:geofence];
        }
    }
    return nearbyGeofences;
}

+ (void)setNearbyBeacons:(NSArray<RadarBeacon *> *_Nullable)nearbyBeacons {
    NSMutableArray *nearbyBeaconsArray = [NSMutableArray new];
    NSMutableArray *nearbyBeaconsArrayIds = [NSMutableArray new];
    for (RadarBeacon *beacon in nearbyBeacons) {
        [nearbyBeaconsArray addObject:[beacon dictionaryValue]];
        [nearbyBeaconsArrayIds addObject:beacon._id];
    }
    [[NSUserDefaults standardUserDefaults] setObject:nearbyBeaconsArray forKey:kNearbyBeacons];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"nearbyBeaconsArray in RadarState:%@", nearbyBeaconsArray]];
}

+ (NSArray<RadarBeacon *> *_Nullable)nearbyBeacons {
    NSArray *nearbyBeaconsArray = [[NSUserDefaults standardUserDefaults] objectForKey:kNearbyBeacons];
    if (!nearbyBeaconsArray) {
        return nil;
    }
    NSMutableArray *nearbyBeacons = [NSMutableArray new];
    for (NSDictionary *beaconDict in nearbyBeaconsArray) {
        RadarBeacon *beacon = [[RadarBeacon alloc] initWithObject:beaconDict];
        if (beacon) {
            [nearbyBeacons addObject:beacon];
        }
    }
    return nearbyBeacons;
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

+ (CLRegion *)syncedRegion {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSyncedRegion];
    CLRegion *syncedRegion = [RadarUtils regionForDictionary:dict];

    return syncedRegion;
}

+ (void)setSyncedRegion:(CLRegion *)syncedRegion {
    NSDictionary *dict = [RadarUtils dictionaryForRegion:syncedRegion];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kSyncedRegion];
}

+ (void)setRadarUser:(RadarUser *_Nullable)radarUser {
    NSDictionary *radarUserDict = [radarUser dictionaryValue];
    [[NSUserDefaults standardUserDefaults] setObject:radarUserDict forKey:kRadarUser];
}

+ (RadarUser *_Nullable)radarUser {
    NSDictionary *radarUserDict = [[NSUserDefaults standardUserDefaults] objectForKey:kRadarUser];
    return [[RadarUser alloc] initWithObject:radarUserDict];
}


@end
