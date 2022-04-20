//
//  RadarBeaconManager.m
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarBeaconManager.h"

#import "RadarBeacon+Internal.h"
#import "RadarDelegateHolder.h"
#import "RadarLogger.h"
#import "RadarSettings.h"

@interface RadarBeaconManager ()

@property (assign, nonatomic) BOOL started;
@property (nonnull, strong, nonatomic) NSMutableArray<RadarBeaconCompletionHandler> *completionHandlers;
@property (nonnull, strong, nonatomic) NSMutableSet<NSString *> *nearbyBeaconIdentifiers;
@property (nonnull, strong, nonatomic) NSMutableSet<NSString *> *failedBeaconIdentifiers;
@property (nonnull, strong, nonatomic) NSMutableSet<NSDictionary *> *nearbyBeacons;
@property (nonnull, strong, nonatomic) NSArray<RadarBeacon *> *beacons;
@property (nonnull, strong, nonatomic) NSArray<NSString *> *beaconUUIDs;

@end

@implementation RadarBeaconManager

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    if ([NSThread isMainThread]) {
        dispatch_once(&once, ^{
            sharedInstance = [self new];
        });
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_once(&once, ^{
                sharedInstance = [self new];
            });
        });
    }
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationManager = [CLLocationManager new];
        _locationManager.delegate = self;

        _completionHandlers = [NSMutableArray<RadarBeaconCompletionHandler> new];

        _beacons = [NSMutableArray new];
        _nearbyBeaconIdentifiers = [NSMutableSet new];
        _failedBeaconIdentifiers = [NSMutableSet new];
        _nearbyBeacons = [NSMutableSet new];

        _permissionsHelper = [RadarPermissionsHelper new];
    }
    return self;
}

- (void)callCompletionHandlersWithStatus:(RadarStatus)status nearbyBeacons:(NSArray<NSDictionary *> *_Nullable)nearbyBeacons {
    @synchronized(self) {
        if (!self.completionHandlers.count) {
            return;
        }

        [[RadarLogger sharedInstance]
            logWithLevel:RadarLogLevelDebug
                 message:[NSString stringWithFormat:@"Calling completion handlers | self.completionHandlers.count = %lu", (unsigned long)self.completionHandlers.count]];

        for (RadarBeaconCompletionHandler completionHandler in self.completionHandlers) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeoutWithCompletionHandler:) object:completionHandler];

            completionHandler(status, nearbyBeacons);
        }

        [self.completionHandlers removeAllObjects];
    }
}

- (void)addCompletionHandler:(RadarBeaconCompletionHandler)completionHandler {
    if (!completionHandler) {
        return;
    }

    @synchronized(self) {
        [self.completionHandlers addObject:completionHandler];

        [self performSelector:@selector(timeoutWithCompletionHandler:) withObject:completionHandler afterDelay:5];
    }
}

- (void)cancelTimeouts {
    @synchronized(self) {
        for (RadarLocationCompletionHandler completionHandler in self.completionHandlers) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeoutWithCompletionHandler:) object:completionHandler];
        }
    }
}

- (void)timeoutWithCompletionHandler:(RadarBeaconCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Beacon ranging timeout"];

    [self stopRanging];
}

- (void)rangeBeacons:(NSArray<RadarBeacon *> *_Nonnull)beacons completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    CLAuthorizationStatus authorizationStatus = [self.permissionsHelper locationAuthorizationStatus];
    if (!(authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
        [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorPermissions];

        if (completionHandler) {
            completionHandler(RadarStatusErrorPermissions, nil);

            return;
        }
    }

    if (!CLLocationManager.isRangingAvailable) {
        [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorBluetooth];

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Beacon ranging not available"];

        if (completionHandler) {
            completionHandler(RadarStatusErrorBluetooth, nil);
        }

        return;
    }

    [self addCompletionHandler:completionHandler];

    if (self.started) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Already ranging beacons"];

        return;
    }

    if (!beacons || !beacons.count) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"No beacons to range"];

        completionHandler(RadarStatusSuccess, @[]);

        return;
    }

    self.beacons = beacons;
    self.started = YES;

    for (RadarBeacon *beacon in beacons) {
        CLBeaconRegion *region = [self regionForBeacon:beacon];

        if (region) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Starting ranging beacon | _id = %@; uuid = %@; major = %@; minor = %@", beacon._id, beacon.uuid,
                                                                                  beacon.major, beacon.minor]];

            [self.locationManager startRangingBeaconsInRegion:region];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Error starting ranging beacon | _id = %@; uuid = %@; major = %@; minor = %@", beacon._id,
                                                                                  beacon.uuid, beacon.major, beacon.minor]];
        }
    }
}

- (void)rangeUUIDs:(NSArray<NSString *> *_Nonnull)uuids completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    CLAuthorizationStatus authorizationStatus = [self.permissionsHelper locationAuthorizationStatus];
    if (!(authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
        [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorPermissions];

        if (completionHandler) {
            completionHandler(RadarStatusErrorPermissions, nil);

            return;
        }
    }

    if (!CLLocationManager.isRangingAvailable) {
        [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorBluetooth];

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Beacon ranging not available"];

        if (completionHandler) {
            completionHandler(RadarStatusErrorBluetooth, nil);
        }

        return;
    }

    [self addCompletionHandler:completionHandler];

    if (self.started) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Already ranging beacons"];

        return;
    }

    if (!uuids || !uuids.count) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"No UUIDs to range"];

        completionHandler(RadarStatusSuccess, @[]);

        return;
    }

    self.beaconUUIDs = uuids;
    self.started = YES;

    for (NSString *uuid in uuids) {
        CLBeaconRegion *region = [self regionForUUID:uuid];

        if (region) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Starting ranging UUID | uuid = %@", uuid]];

            [self.locationManager startRangingBeaconsInRegion:region];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error starting ranging UUID | uuid = %@", uuid]];
        }
    }
}

- (void)stopRanging {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Stopping ranging"]];

    [self cancelTimeouts];

    for (RadarBeacon *beacon in self.beacons) {
        [self.locationManager stopRangingBeaconsInRegion:[self regionForBeacon:beacon]];
    }

    [self callCompletionHandlersWithStatus:RadarStatusSuccess nearbyBeacons:[self.nearbyBeacons allObjects]];

    self.beacons = [NSMutableArray new];
    self.started = NO;

    [self.nearbyBeaconIdentifiers removeAllObjects];
    [self.failedBeaconIdentifiers removeAllObjects];
    [self.nearbyBeacons removeAllObjects];
}

- (CLBeaconRegion *)regionForBeacon:(RadarBeacon *)beacon {
    return [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:beacon.uuid]
                                                   major:[beacon.major intValue]
                                                   minor:[beacon.minor intValue]
                                              identifier:beacon._id];
}

- (CLBeaconRegion *)regionForUUID:(NSString *)uuid {
    return [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:uuid] identifier:uuid];
}

- (NSDictionary *)dictionaryForRegion:(CLBeaconRegion *)region {
    return @{
        @"uuid": region.proximityUUID,
        @"major": region.major,
        @"minor": region.minor

    };
}

- (NSDictionary *)dictionaryForBeacon:(CLBeacon *)beacon {
    return @{@"uuid": beacon.proximityUUID, @"major": beacon.major, @"minor": beacon.minor, @"rssi": @(beacon.rssi), @"proximity": @(beacon.proximity)};
}

- (void)handleBeacons {
    if (self.nearbyBeaconIdentifiers.count + self.failedBeaconIdentifiers.count == self.beacons.count) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Finished ranging"]];

        [self stopRanging];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Failed to monitor beacon | region.identifier = %@", region.identifier]];

    [self.failedBeaconIdentifiers addObject:region.identifier];

    [self handleBeacons];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Failed to range beacon | region.identifier = %@", region.identifier]];

    [self.failedBeaconIdentifiers addObject:region.identifier];

    [self handleBeacons];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(nonnull NSArray<CLBeacon *> *)beacons inRegion:(nonnull CLBeaconRegion *)region {
    for (CLBeacon *beacon in beacons) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Ranged beacon | region.identifier = %@; beacon.rssi = %ld; beacon.proximity = %ld",
                                                                              region.identifier, (long)beacon.rssi, (long)beacon.proximity]];

        [self.nearbyBeaconIdentifiers addObject:region.identifier];
        [self.nearbyBeacons addObject:[self dictionaryForBeacon:beacon]];
    }

    [self handleBeacons];
}

- (void)handleBeaconEntryForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    NSString *identifier = region.identifier;
    BOOL alreadyInside = [self.nearbyBeaconIdentifiers containsObject:region.identifier];
    if (alreadyInside) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Already inside beacon region | identifier = %@", identifier]];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Entered beacon region | identifier = %@", identifier]];

        [self.nearbyBeaconIdentifiers addObject:identifier];
        [self.nearbyBeacons addObject:[self dictionaryForRegion:region]];

        completionHandler(RadarStatusSuccess, [self.nearbyBeacons allObjects]);
    }
}

- (void)handleBeaconExitForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    NSString *identifier = region.identifier;
    BOOL alreadyOutside = ![self.nearbyBeaconIdentifiers containsObject:identifier];
    if (alreadyOutside) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Already outside beacon region | identifier = %@", identifier]];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Exited beacon region | identifier = %@", identifier]];

        [self.nearbyBeaconIdentifiers removeObject:identifier];
        [self.nearbyBeacons removeObject:[self dictionaryForRegion:region]];

        completionHandler(RadarStatusSuccess, [self.nearbyBeacons allObjects]);
    }
}

- (void)handleBeaconUUIDEntryForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    NSArray<NSString *> *beaconUUIDs = [RadarSettings beaconUUIDs];
    [self rangeUUIDs:beaconUUIDs completionHandler:completionHandler];
}

- (void)handleBeaconUUIDExitForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    NSArray<NSString *> *beaconUUIDs = [RadarSettings beaconUUIDs];
    [self rangeUUIDs:beaconUUIDs completionHandler:completionHandler];
}

@end
