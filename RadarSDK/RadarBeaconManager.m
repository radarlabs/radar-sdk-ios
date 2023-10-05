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
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSTimer *> *exitDebounceTimers;


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

        _exitDebounceTimers = [NSMutableDictionary new]; // Initialize the dictionary here

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
    
    self.started = YES;

    // Use a set for faster lookup
    NSMutableSet *currentBeaconIDs = [NSMutableSet set];
    for (RadarBeacon *currentBeacon in self.beacons) {
        [currentBeaconIDs addObject:currentBeacon._id];
    }

    // create an empty array for hich beacons that aren't current beacons
    NSMutableArray *newBeacons = [NSMutableArray new];
    for (RadarBeacon *beacon in beacons) {
        if ([currentBeaconIDs containsObject:beacon._id]) {
            // Already ranging this beacon, skip
            continue;
        }
        CLBeaconRegion *region = [self regionForBeacon:beacon];

        if (region) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Starting ranging beacon | _id = %@; uuid = %@; major = %@; minor = %@", beacon._id, beacon.uuid,
                                                                                  beacon.major, beacon.minor]];

            [self.locationManager startRangingBeaconsInRegion:region];
            [self.locationManager startMonitoringForRegion:region];
            [newBeacons addObject:beacon];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Error starting ranging beacon | _id = %@; uuid = %@; major = %@; minor = %@", beacon._id,
                                                                                  beacon.uuid, beacon.major, beacon.minor]];
        }
    }
    self.beacons = [self.beacons arrayByAddingObjectsFromArray:newBeacons];
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

    self.started = YES;
    NSMutableSet *currentBeaconUUIDsSet = [NSMutableSet setWithArray:self.beaconUUIDs];


    for (NSString *beaconUUID in beaconUUIDs) {
            if ([currentBeaconUUIDsSet containsObject:beaconUUID]) {
            // Already ranging this UUID, skip
            continue;
        }
        CLBeaconRegion *region = [self regionForUUID:beaconUUID];

        if (region) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Starting ranging UUID | beaconUUID = %@", beaconUUID]];

            [self.locationManager startRangingBeaconsInRegion:region];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error starting ranging UUID | beaconUUID = %@", beaconUUID]];
        }
    }
    
    self.beaconUUIDs = [self.beaconUUIDs arrayByAddingObjectsFromArray:beaconUUIDs];
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
    // [self.nearbyBeacons removeAllObjects];
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
    if (self.beaconUUIDs.count == 0 && self.nearbyBeaconIdentifiers.count + self.failedBeaconIdentifiers.count == self.beacons.count) {
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
        [self.nearbyBeaconIdentifiers addObject:region.identifier];
        [self.nearbyBeacons addObject:[RadarBeacon fromCLBeacon:beacon]];

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Ranged beacon | nearbyBeacons.count = %lu; region.identifier = %@; beacon.uuid = %@; beacon.major "
                                                                              @"= %@; beacon.minor = %@; beacon.rssi = %ld; beacon.proximity = %ld",
                                                                              (unsigned long)self.nearbyBeacons.count, region.identifier, [beacon.proximityUUID UUIDString],
                                                                              beacon.major, beacon.minor, (unsigned long)beacon.rssi, (unsigned long)beacon.proximity]];
    }

    [self handleBeacons];
}

- (void)handleBeaconEntryForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    NSString *identifier = region.identifier;
    NSTimer *debounceTimer = self.exitDebounceTimers[identifier];
    if (debounceTimer) {
        // Log that we're cancelling the debounce timer
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Cancelling beacon exit timer | identifier = %@", identifier]];
        [debounceTimer invalidate];
        [self.exitDebounceTimers removeObjectForKey:identifier];
    }

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
    // Log that we got the beacon exit and start a timer to debounce it
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Got beacon exit, starting timer | identifier = %@", region.identifier]];
    NSString *identifier = region.identifier;
    NSTimer *debounceTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                            target:self
                                                          selector:@selector(processDebouncedBeaconExit:)
                                                          userInfo:@{@"region": region, @"completionHandler": [completionHandler copy]}
                                                           repeats:NO];
    
    self.exitDebounceTimers[identifier] = debounceTimer;

    // range the beacons to see if we're still in range
    // first remove the beacon from beacons
    NSMutableArray *mutableBeacons = [NSMutableArray arrayWithArray:self.beacons];
    for (RadarBeacon *beacon in self.beacons) {
        if ([beacon._id isEqualToString:identifier]) {
            [mutableBeacons removeObject:beacon];
        }
    }
    self.beacons = [NSArray arrayWithArray:mutableBeacons];
    // then range the beacons to try
    [self rangeBeacons: mutableBeacons completionHandler:nil];

}

- (void)processDebouncedBeaconExit:(NSTimer *)timer {
    CLBeaconRegion *region = timer.userInfo[@"region"];
    RadarBeaconCompletionHandler completionHandler = timer.userInfo[@"completionHandler"];
    // Log that we're processing the beacon exit
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Processing beacon exit | identifier = %@", region.identifier]];
    
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
    
    [self.exitDebounceTimers removeObjectForKey:identifier];
}

- (void)handleBeaconUUIDEntryForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    // log handlingBeaconUUIDEntry
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

    // old version here
    // NSArray<NSString *> *beaconUUIDs = [RadarSettings beaconUUIDs];
    // [self rangeBeaconUUIDs:beaconUUIDs completionHandler:completionHandler];
}

- (void)handleBeaconUUIDExitForRegion:(CLBeaconRegion *)region completionHandler:(RadarBeaconCompletionHandler)completionHandler {
    // log handlingBeaconUUIDExit
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
    // NSArray<NSString *> *beaconUUIDs = [RadarSettings beaconUUIDs];
    // [self rangeBeaconUUIDs:beaconUUIDs completionHandler:completionHandler];
}

@end
