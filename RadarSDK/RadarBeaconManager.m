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
@property (nonnull, strong, nonatomic) NSMutableSet<RadarBeacon *> *nearbyBeacons;
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

- (void)callCompletionHandlersWithStatus:(RadarStatus)status nearbyBeacons:(NSArray<RadarBeacon *> *_Nullable)nearbyBeacons {
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
        RadarBeaconCompletionHandler completionHandlerCopy = [completionHandler copy];
        [self.completionHandlers addObject:completionHandlerCopy];

        [self performSelector:@selector(timeoutWithCompletionHandler:) withObject:completionHandlerCopy afterDelay:5];
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

- (void)rangeBeaconUUIDs:(NSArray<NSString *> *_Nonnull)beaconUUIDs completionHandler:(RadarBeaconCompletionHandler)completionHandler {
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

    if (!beaconUUIDs || !beaconUUIDs.count) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"No UUIDs to range"];

        completionHandler(RadarStatusSuccess, @[]);

        return;
    }

    self.beaconUUIDs = beaconUUIDs;
    self.started = YES;

    for (NSString *beaconUUID in beaconUUIDs) {
        CLBeaconRegion *region = [self regionForUUID:beaconUUID];

        if (region) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Starting ranging UUID | beaconUUID = %@", beaconUUID]];

            [self.locationManager startRangingBeaconsInRegion:region];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error starting ranging UUID | beaconUUID = %@", beaconUUID]];
        }
    }
}

- (void)stopRanging {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Stopping ranging"]];

    [self cancelTimeouts];

    for (RadarBeacon *beacon in self.beacons) {
        CLBeaconRegion *region = [self regionForBeacon:beacon];
        if (region != nil) {
            [self.locationManager stopRangingBeaconsInRegion:region];
        }
    }

    for (NSString *beaconUUID in self.beaconUUIDs) {
        CLBeaconRegion *region = [self regionForUUID:beaconUUID];
        if (region != nil) {
            [self.locationManager stopRangingBeaconsInRegion:region];
        }
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

- (void)handleBeacons {
    if ((self.beaconUUIDs.count == 0 || [RadarSettings useRadarModifiedBeacon]) && 
        self.nearbyBeaconIdentifiers.count + self.failedBeaconIdentifiers.count == self.beacons.count) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Finished ranging"]];

        [self stopRanging];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    if ([RadarSettings useRadarModifiedBeacon]) {
        return;
    }
    
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
        [self.nearbyBeaconIdentifiers addObject:region.identifier];

        // first, check if this beacon was already in nearbybeacons
        // if so, and we have a non 0 rssi, update the rssi
        [self.nearbyBeacons enumerateObjectsUsingBlock:^(RadarBeacon * _Nonnull radarBeacon, BOOL * _Nonnull stop) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"radarBeacon uuid: %@", [radarBeacon uuid]]];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"radarBeacon major: %@", [radarBeacon major]]];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"radarBeacon minor: %@", [radarBeacon minor]]];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"radarBeacon.rssi: %ld", (long)radarBeacon.rssi]];

            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"[beacon.proximityUUID UUIDString]: %@", [beacon.proximityUUID UUIDString]]];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"beacon.major: %@", beacon.major]];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"beacon.minor: %@", beacon.minor]];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"beacon.rssi: %ld", (long)beacon.rssi]];

            
            if ([radarBeacon.uuid isEqualToString:[beacon.proximityUUID UUIDString]] && [radarBeacon.major isEqualToString:[NSString stringWithFormat:@"%@", beacon.major]] && [radarBeacon.minor isEqualToString:[NSString stringWithFormat:@"%@", beacon.minor]]) {
                // log "same beacon"
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"same beacon!"];
                if (beacon.rssi != 0 && beacon.rssi != radarBeacon.rssi) {
                    // OVERWRITING STALE RSSI!!!!
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Overwriting stale RSSI: %ld", (long)radarBeacon.rssi]];
                    [radarBeacon setRssi:beacon.rssi];
                }
                *stop = YES;
            }
        }];


        [self.nearbyBeacons addObject:[RadarBeacon fromCLBeacon:beacon]];

        // log nearbyBeacons 
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"self.nearbyBeacons: %@", [RadarBeacon arrayForBeacons:[self.nearbyBeacons allObjects]]]];

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Ranged beacon with RSSI %ld | nearbyBeacons.count = %lu; region.identifier = %@; beacon.uuid = %@; beacon.major "
                                                                              @"= %@; beacon.minor = %@; beacon.rssi = %ld; beacon.proximity = %ld",
                                                                              (unsigned long)beacon.rssi,
                                                                              (unsigned long)self.nearbyBeacons.count, region.identifier, [beacon.proximityUUID UUIDString],
                                                                              beacon.major, beacon.minor, (unsigned long)beacon.rssi, (unsigned long)beacon.proximity]];
    }

    [self handleBeacons];
}

- (void)handleBeaconEntryForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    if ([RadarSettings useRadarModifiedBeacon]) {
        return;
    }
    
    NSString *identifier = region.identifier;
    BOOL alreadyInside = [self.nearbyBeaconIdentifiers containsObject:identifier];
    if (alreadyInside) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Already inside beacon region | identifier = %@", identifier]];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Entered beacon region | identifier = %@", identifier]];

        [self.nearbyBeaconIdentifiers addObject:identifier];
        [self.nearbyBeacons addObject:[RadarBeacon fromCLBeaconRegion:region]];

        completionHandler(RadarStatusSuccess, [self.nearbyBeacons allObjects]);
    }
}

- (void)handleBeaconExitForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    if ([RadarSettings useRadarModifiedBeacon]) {
        return;
    }
    
    NSString *identifier = region.identifier;
    BOOL alreadyOutside = ![self.nearbyBeaconIdentifiers containsObject:identifier];
    if (alreadyOutside) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Already outside beacon region | identifier = %@", identifier]];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Exited beacon region | identifier = %@", identifier]];

        [self.nearbyBeaconIdentifiers removeObject:identifier];
        [self.nearbyBeacons removeObject:[RadarBeacon fromCLBeaconRegion:region]];

        completionHandler(RadarStatusSuccess, [self.nearbyBeacons allObjects]);
    }
}

- (void)handleBeaconUUIDEntryForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    if ([RadarSettings useRadarModifiedBeacon]) {
        return;
    }
    
    NSArray<NSString *> *beaconUUIDs = [RadarSettings beaconUUIDs];
    [self rangeBeaconUUIDs:beaconUUIDs completionHandler:completionHandler];
}

- (void)handleBeaconUUIDExitForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    if ([RadarSettings useRadarModifiedBeacon]) {
        return;
    }
    
    NSArray<NSString *> *beaconUUIDs = [RadarSettings beaconUUIDs];
    [self rangeBeaconUUIDs:beaconUUIDs completionHandler:completionHandler];
}

@end
