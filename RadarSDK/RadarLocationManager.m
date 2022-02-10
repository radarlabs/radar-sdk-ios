//
//  RadarLocationManager.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RadarLocationManager.h"

#import "RadarAPIClient.h"
#import "RadarCircleGeometry.h"
#import "RadarDelegateHolder.h"
#import "RadarLogger.h"
#import "RadarPolygonGeometry.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarUtils.h"

@interface RadarLocationManager ()

@property (assign, nonatomic) BOOL started;
@property (assign, nonatomic) int startedInterval;
@property (assign, nonatomic) BOOL sending;
@property (strong, nonatomic) NSTimer *timer;
@property (nonnull, strong, nonatomic) NSMutableArray<RadarLocationCompletionHandler> *completionHandlers;
@property (nonnull, strong, nonatomic) NSMutableSet<NSString *> *nearbyBeaconIdentifers;

@end

@implementation RadarLocationManager

static NSString *const kIdentifierPrefix = @"radar_";
static NSString *const kBubbleGeofenceIdentifierPrefix = @"radar_bubble_";
static NSString *const kSyncGeofenceIdentifierPrefix = @"radar_geofence_";
static NSString *const kSyncBeaconIdentifierPrefix = @"radar_beacon_";

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
        _completionHandlers = [NSMutableArray new];

        _locationManager = [CLLocationManager new];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager.distanceFilter = kCLDistanceFilterNone;
        _locationManager.allowsBackgroundLocationUpdates = [RadarUtils locationBackgroundMode] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;

        _lowPowerLocationManager = [CLLocationManager new];
        _lowPowerLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        _lowPowerLocationManager.distanceFilter = 3000;
        _lowPowerLocationManager.allowsBackgroundLocationUpdates = [RadarUtils locationBackgroundMode];

        _permissionsHelper = [RadarPermissionsHelper new];

        _nearbyBeaconIdentifers = [NSMutableSet new];
    }
    return self;
}

- (void)callCompletionHandlersWithStatus:(RadarStatus)status location:(CLLocation *_Nullable)location {
    @synchronized(self) {
        if (!self.completionHandlers.count) {
            return;
        }

        [[RadarLogger sharedInstance]
            logWithLevel:RadarLogLevelDebug
                 message:[NSString stringWithFormat:@"Calling completion handlers | self.completionHandlers.count = %lu", (unsigned long)self.completionHandlers.count]];

        for (RadarLocationCompletionHandler completionHandler in self.completionHandlers) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeoutWithCompletionHandler:) object:completionHandler];

            completionHandler(status, location, [RadarState stopped]);
        }

        [self.completionHandlers removeAllObjects];
    }
}

- (void)addCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    if (!completionHandler) {
        return;
    }

    @synchronized(self) {
        [self.completionHandlers addObject:completionHandler];

        [self performSelector:@selector(timeoutWithCompletionHandler:) withObject:completionHandler afterDelay:20];
    }
}

- (void)cancelTimeouts {
    @synchronized(self) {
        for (RadarLocationCompletionHandler completionHandler in self.completionHandlers) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeoutWithCompletionHandler:) object:completionHandler];
        }
    }
}

- (void)timeoutWithCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    @synchronized(self) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Location timeout"];

        [self callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];
    }
}

- (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    [self getLocationWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium completionHandler:completionHandler];
}

- (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarLocationCompletionHandler)completionHandler {
    CLAuthorizationStatus authorizationStatus = [self.permissionsHelper locationAuthorizationStatus];
    if (!(authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
        [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorPermissions];

        if (completionHandler) {
            completionHandler(RadarStatusErrorPermissions, nil, NO);

            return;
        }
    }

    [self addCompletionHandler:completionHandler];

    CLLocationAccuracy accuracy;
    switch (desiredAccuracy) {
    case RadarTrackingOptionsDesiredAccuracyHigh:
        accuracy = kCLLocationAccuracyBest;
        break;
    case RadarTrackingOptionsDesiredAccuracyMedium:
        accuracy = kCLLocationAccuracyHundredMeters;
        break;
    case RadarTrackingOptionsDesiredAccuracyLow:
        accuracy = kCLLocationAccuracyKilometer;
        break;
    default:
        accuracy = kCLLocationAccuracyHundredMeters;
    }

    self.locationManager.desiredAccuracy = accuracy;
    [self requestLocation];
}

- (void)startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions {
    CLAuthorizationStatus authorizationStatus = [self.permissionsHelper locationAuthorizationStatus];
    if (!(authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
        [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorPermissions];

        return;
    }

    [RadarSettings setTracking:YES];
    [RadarSettings setTrackingOptions:trackingOptions];
    [self updateTracking];
}

- (void)stopTracking {
    [RadarSettings setTracking:NO];
    [self updateTracking];
}

- (void)startUpdates:(int)interval {
    if (!self.started || interval != self.startedInterval) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Starting timer | interval = %d", interval]];

        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shutDown) object:nil];

        if (self.timer) {
            [self.timer invalidate];
        }

        self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                     repeats:YES
                                                       block:^(NSTimer *_Nonnull timer) {
                                                           [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Timer fired"];

                                                           [self requestLocation];
                                                       }];

        [self.lowPowerLocationManager startUpdatingLocation];

        self.started = YES;
        self.startedInterval = interval;
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Already started timer"];
    }
}

- (void)stopUpdates {
    if (!self.timer) {
        return;
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Stopping timer"];

    [self.timer invalidate];

    self.started = NO;
    self.startedInterval = 0;

    if (!self.sending) {
        NSTimeInterval delay = [RadarSettings tracking] ? 10 : 0;

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Scheduling shutdown"];

        [self performSelector:@selector(shutDown) withObject:nil afterDelay:delay];
    }
}

- (void)shutDown {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Shutting down"];

    [self.lowPowerLocationManager stopUpdatingLocation];
}

- (void)requestLocation {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Requesting location"];

    [self.locationManager requestLocation];
}

- (void)updateTracking {
    [self updateTracking:nil fromInitialize:NO];
}

- (void)updateTrackingFromInitialize {
    [self updateTracking:nil fromInitialize:YES];
}

- (void)updateTracking:(CLLocation *)location {
    [self updateTracking:location fromInitialize:NO];
}

- (void)updateTracking:(CLLocation *)location
        fromInitialize:(BOOL)fromInitialize {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL tracking = [RadarSettings tracking];
        RadarTrackingOptions *options = [RadarSettings trackingOptions];

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Updating tracking | options = %@; location = %@", [options dictionaryValue], location]];

        if (!tracking && [options.startTrackingAfter timeIntervalSinceNow] < 0) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Starting time-based tracking | startTrackingAfter = %@", options.startTrackingAfter]];

            [RadarSettings setTracking:YES];
            tracking = YES;
        } else if (tracking && [options.stopTrackingAfter timeIntervalSinceNow] < 0) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Stopping time-based tracking | stopTrackingAfter = %@", options.stopTrackingAfter]];

            [RadarSettings setTracking:NO];
            tracking = NO;
        }

        if (tracking) {
            self.locationManager.allowsBackgroundLocationUpdates =
                [RadarUtils locationBackgroundMode] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
            self.locationManager.pausesLocationUpdatesAutomatically = NO;

            self.lowPowerLocationManager.allowsBackgroundLocationUpdates = [RadarUtils locationBackgroundMode];
            self.lowPowerLocationManager.pausesLocationUpdatesAutomatically = NO;

            CLLocationAccuracy desiredAccuracy;
            switch (options.desiredAccuracy) {
            case RadarTrackingOptionsDesiredAccuracyHigh:
                desiredAccuracy = kCLLocationAccuracyBest;
                break;
            case RadarTrackingOptionsDesiredAccuracyMedium:
                desiredAccuracy = kCLLocationAccuracyHundredMeters;
                break;
            case RadarTrackingOptionsDesiredAccuracyLow:
                desiredAccuracy = kCLLocationAccuracyKilometer;
                break;
            default:
                desiredAccuracy = kCLLocationAccuracyHundredMeters;
            }
            self.locationManager.desiredAccuracy = desiredAccuracy;

            if (@available(iOS 11.0, *)) {
                self.lowPowerLocationManager.showsBackgroundLocationIndicator = options.showBlueBar;
            }

            BOOL startUpdates = options.showBlueBar || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
            BOOL stopped = [RadarState stopped];
            if (stopped) {
                if (options.desiredStoppedUpdateInterval == 0) {
                    [self stopUpdates];
                } else if (startUpdates) {
                    [self startUpdates:options.desiredStoppedUpdateInterval];
                }
                if (options.useStoppedGeofence) {
                    if (location) {
                        [self replaceBubbleGeofence:location radius:options.stoppedGeofenceRadius];
                    }
                } else {
                    [self removeBubbleGeofence];
                }
            } else {
                if (options.desiredMovingUpdateInterval == 0) {
                    [self stopUpdates];
                } else if (startUpdates) {
                    [self startUpdates:options.desiredMovingUpdateInterval];
                }
                if (options.useMovingGeofence) {
                    if (location) {
                        [self replaceBubbleGeofence:location radius:options.movingGeofenceRadius];
                    }
                } else {
                    [self removeBubbleGeofence];
                }
            }
            if (!options.syncGeofences) {
                [self removeSyncedGeofences];
            }
            if (options.useVisits) {
                [self.locationManager startMonitoringVisits];
            }
            if (options.useSignificantLocationChanges) {
                [self.locationManager startMonitoringSignificantLocationChanges];
            }
            if (!options.beacons) {
                [self removeSyncedBeacons];
            }
        } else {
            [self stopUpdates];
            [self removeAllRegions];

            // If updateTracking() was called from the RadarLocationManager
            // intializer, don't tell the CLLocationManager to stop, because
            // the location manager may be in use by other location-based
            // services. Currently, only the initializer passes in YES, and all
            // subsequent calls to updateTracking() get NO.
            if (!fromInitialize) {
                [self.locationManager stopMonitoringVisits];
                [self.locationManager stopMonitoringSignificantLocationChanges];
            }
        }
    });
}

- (void)replaceBubbleGeofence:(CLLocation *)location radius:(int)radius {
    [self removeBubbleGeofence];

    BOOL tracking = [RadarSettings tracking];
    if (!tracking) {
        return;
    }

    NSString *identifier = [NSString stringWithFormat:@"%@%@", kBubbleGeofenceIdentifierPrefix, [[NSUUID UUID] UUIDString]];
    CLRegion *region = [[CLCircularRegion alloc] initWithCenter:location.coordinate radius:radius identifier:identifier];
    [self.locationManager startMonitoringForRegion:region];
}

- (void)removeBubbleGeofence {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kBubbleGeofenceIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
}

- (void)replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences {
    [self removeSyncedGeofences];

    BOOL tracking = [RadarSettings tracking];
    RadarTrackingOptions *options = [RadarSettings trackingOptions];
    if (!tracking || !options.syncGeofences || !geofences) {
        return;
    }

    NSUInteger numGeofences = MIN(geofences.count, 9);

    for (int i = 0; i < numGeofences; i++) {
        RadarGeofence *geofence = [geofences objectAtIndex:i];
        NSString *identifier = [NSString stringWithFormat:@"%@%d", kSyncGeofenceIdentifierPrefix, i];
        RadarCoordinate *center;
        double radius = 100;
        if ([geofence.geometry isKindOfClass:[RadarCircleGeometry class]]) {
            RadarCircleGeometry *geometry = (RadarCircleGeometry *)geofence.geometry;
            center = geometry.center;
            radius = geometry.radius;
        } else if ([geofence.geometry isKindOfClass:[RadarPolygonGeometry class]]) {
            RadarPolygonGeometry *geometry = (RadarPolygonGeometry *)geofence.geometry;
            center = geometry.center;
            radius = geometry.radius;
        }
        if (center) {
            CLRegion *region = [[CLCircularRegion alloc] initWithCenter:center.coordinate radius:radius identifier:identifier];
            [self.locationManager startMonitoringForRegion:region];

            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Synced geofence | latitude = %f; longitude = %f; radius = %f; identifier = %@",
                                                                                  center.coordinate.latitude, center.coordinate.longitude, radius, identifier]];
        }
    }
}

- (void)removeSyncedGeofences {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kSyncGeofenceIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
}

- (void)replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons {
    [self removeSyncedBeacons];

    BOOL tracking = [RadarSettings tracking];
    RadarTrackingOptions *options = [RadarSettings trackingOptions];
    if (!tracking || !options.beacons || !beacons) {
        return;
    }

    NSUInteger numBeacons = MIN(beacons.count, 9);

    for (int i = 0; i < numBeacons; i++) {
        RadarBeacon *beacon = [beacons objectAtIndex:i];
        NSString *identifier = [NSString stringWithFormat:@"%@%@", kSyncBeaconIdentifierPrefix, beacon._id];
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:beacon.uuid]
                                                                         major:[beacon.major intValue]
                                                                         minor:[beacon.minor intValue]
                                                                    identifier:identifier];

        if (region) {
            region.notifyEntryStateOnDisplay = YES;
            [self.locationManager startMonitoringForRegion:region];
            [self.locationManager requestStateForRegion:region];

            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Synced beacon | identifier = %@; uuid = %@; major = %@; minor = %@", identifier, beacon.uuid,
                                                                                  beacon.major, beacon.minor]];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Error syncing beacon | identifier = %@; uuid = %@; major = %@; minor = %@", identifier,
                                                                                  beacon.uuid, beacon.major, beacon.minor]];
        }
    }
}

- (void)removeSyncedBeacons {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
}

- (void)removeAllRegions {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
}

#pragma mark - handlers

- (void)handleLocation:(CLLocation *)location source:(RadarLocationSource)source {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Handling location | source = %@; location = %@", [Radar stringForLocationSource:source], location]];

    if (!location || ![RadarUtils validLocation:location]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Invalid location | source = %@; location = %@", [Radar stringForLocationSource:source], location]];

        [self callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];

        return;
    }

    RadarTrackingOptions *options = [RadarSettings trackingOptions];
    BOOL wasStopped = [RadarState stopped];
    BOOL stopped = NO;

    BOOL force = (source == RadarLocationSourceForegroundLocation || source == RadarLocationSourceManualLocation || source == RadarLocationSourceBeaconEnter ||
                  source == RadarLocationSourceBeaconExit);
    if (wasStopped && !force && location.horizontalAccuracy >= 1000 && options.desiredAccuracy != RadarTrackingOptionsDesiredAccuracyLow) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Skipping location: inaccurate | accuracy = %f", location.horizontalAccuracy]];

        [self updateTracking:location];

        return;
    }

    BOOL tracking = [RadarSettings tracking];
    if (!force && !tracking) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Skipping location: not tracking"];

        return;
    }

    [self cancelTimeouts];

    CLLocationDistance distance = CLLocationDistanceMax;
    NSTimeInterval duration = 0;
    if (options.stopDistance > 0 && options.stopDuration > 0) {
        CLLocation *lastMovedLocation = [RadarState lastMovedLocation];
        if (!lastMovedLocation) {
            lastMovedLocation = location;
            [RadarState setLastMovedLocation:lastMovedLocation];
        }
        NSDate *lastMovedAt = [RadarState lastMovedAt];
        if (!lastMovedAt) {
            lastMovedAt = location.timestamp;
            [RadarState setLastMovedAt:lastMovedAt];
        }
        if (!force && [lastMovedAt timeIntervalSinceDate:location.timestamp] > 0) {
            [[RadarLogger sharedInstance]
                logWithLevel:RadarLogLevelDebug
                     message:[NSString stringWithFormat:@"Skipping location: old | lastMovedAt = %@; location.timestamp = %@", lastMovedAt, location.timestamp]];

            return;
        }
        if (location && lastMovedLocation && lastMovedAt) {
            distance = [location distanceFromLocation:lastMovedLocation];
            duration = [location.timestamp timeIntervalSinceDate:lastMovedAt];
            if (duration == 0) {
                duration = -[location.timestamp timeIntervalSinceNow];
            }
            stopped = distance <= options.stopDistance && duration >= options.stopDuration;

            [[RadarLogger sharedInstance]
                logWithLevel:RadarLogLevelDebug
                     message:[NSString stringWithFormat:@"Calculating stopped | stopped = %d; distance = %f; duration = %f; location.timestamp = %@; lastMovedAt = %@", stopped,
                                                        distance, duration, location.timestamp, lastMovedAt]];

            if (distance > options.stopDistance) {
                [RadarState setLastMovedLocation:location];

                if (!stopped) {
                    [RadarState setLastMovedAt:location.timestamp];
                }
            }
        }
    } else {
        stopped = (force || source == RadarLocationSourceVisitArrival);
    }
    BOOL justStopped = stopped && !wasStopped;
    [RadarState setStopped:stopped];

    [RadarState setLastLocation:location];

    [[RadarDelegateHolder sharedInstance] didUpdateClientLocation:location stopped:stopped source:source];

    if (source != RadarLocationSourceManualLocation) {
        [self updateTracking:location];
    }

    [self callCompletionHandlersWithStatus:RadarStatusSuccess location:location];

    CLLocation *sendLocation = location;

    CLLocation *lastFailedStoppedLocation = [RadarState lastFailedStoppedLocation];
    BOOL replayed = NO;
    if (options.replay == RadarTrackingOptionsReplayStops && lastFailedStoppedLocation && !justStopped) {
        sendLocation = lastFailedStoppedLocation;
        stopped = YES;
        replayed = YES;
        [RadarState setLastFailedStoppedLocation:nil];

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Replaying location | location = %@; stopped = %d", sendLocation, stopped]];
    }

    NSDate *lastSentAt = [RadarState lastSentAt];
    BOOL ignoreSync =
        !lastSentAt || self.completionHandlers.count || justStopped || replayed || source == RadarLocationSourceBeaconEnter || source == RadarLocationSourceBeaconExit;
    NSDate *now = [NSDate new];
    NSTimeInterval lastSyncInterval = [now timeIntervalSinceDate:lastSentAt];
    if (!ignoreSync) {
        if (!force && stopped && wasStopped && distance <= options.stopDistance &&
            (options.desiredStoppedUpdateInterval == 0 || options.syncLocations != RadarTrackingOptionsSyncAll)) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Skipping sync: already stopped | stopped = %d; wasStopped = %d", stopped, wasStopped]];

            return;
        }

        if (lastSyncInterval < options.desiredSyncInterval) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Skipping sync: desired sync interval | desiredSyncInterval = %d; lastSyncInterval = %f",
                                                                                  options.desiredSyncInterval, lastSyncInterval]];

            return;
        }

        if (!force && !justStopped && lastSyncInterval < 1) {
            [[RadarLogger sharedInstance]
                logWithLevel:RadarLogLevelDebug
                     message:[NSString stringWithFormat:@"Skipping sync: rate limit | justStopped = %d; lastSyncInterval = %f", justStopped, lastSyncInterval]];

            return;
        }

        if (options.syncLocations == RadarTrackingOptionsSyncNone) {
            [[RadarLogger sharedInstance]
                logWithLevel:RadarLogLevelDebug
                     message:[NSString stringWithFormat:@"Skipping sync: sync mode | sync = %@", [RadarTrackingOptions stringForSyncLocations:options.syncLocations]]];

            return;
        }

        BOOL canExit = [RadarState canExit];
        if (!canExit && options.syncLocations == RadarTrackingOptionsSyncStopsAndExits) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Skipping sync: can't exit | sync = %@; canExit = %d",
                                                                                  [RadarTrackingOptions stringForSyncLocations:options.syncLocations], canExit]];

            return;
        }
    }
    [RadarState updateLastSentAt];

    if (source == RadarLocationSourceForegroundLocation) {
        return;
    }

    [self sendLocation:sendLocation stopped:stopped source:source replayed:replayed];
}

- (void)sendLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source replayed:(BOOL)replayed {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Sending location | source = %@; location = %@; stopped = %d; replayed = %d",
                                                                          [Radar stringForLocationSource:source], location, stopped, replayed]];

    self.sending = YES;

    NSArray<NSString *> *nearbyBeacons;
    RadarTrackingOptions *options = [RadarSettings trackingOptions];
    if (options.beacons) {
        nearbyBeacons = [self.nearbyBeaconIdentifers allObjects];

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Sending nearby beacons | nearbyBeacons = %@", [nearbyBeacons componentsJoinedByString:@","]]];

        if (source != RadarLocationSourceBeaconEnter && source != RadarLocationSourceBeaconExit && source != RadarLocationSourceMockLocation &&
            source != RadarLocationSourceManualLocation) {
            [[RadarAPIClient sharedInstance] searchBeaconsNear:location
                                                        radius:1000
                                                         limit:10
                                             completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons) {
                                                 if (status != RadarStatusSuccess || !beacons) {
                                                     return;
                                                 }

                                                 [self replaceSyncedBeacons:beacons];
                                             }];
        }
    }

    [[RadarAPIClient sharedInstance] trackWithLocation:location
                                               stopped:stopped
                                            foreground:[RadarUtils foreground]
                                                source:source
                                              replayed:replayed
                                         nearbyBeacons:nearbyBeacons
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                         NSArray<RadarGeofence *> *_Nullable nearbyGeofences) {
                                         if (user) {
                                             BOOL inGeofences = user.geofences && user.geofences.count;
                                             BOOL atPlace = user.place != nil;
                                             BOOL atHome = user.insights && user.insights.state && user.insights.state.home;
                                             BOOL atOffice = user.insights && user.insights.state && user.insights.state.office;
                                             BOOL canExit = inGeofences || atPlace || atHome || atOffice;
                                             [RadarState setCanExit:canExit];
                                         }

                                         self.sending = NO;

                                         [self updateTracking];
                                         [self replaceSyncedGeofences:nearbyGeofences];
                                     }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (!locations || !locations.count) {
        return;
    }

    CLLocation *location = [locations lastObject];
    if (self.completionHandlers.count) {
        [self handleLocation:location source:RadarLocationSourceForegroundLocation];
    } else {
        [self handleLocation:location source:RadarLocationSourceBackgroundLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if (![region.identifier hasPrefix:kIdentifierPrefix]) {
        return;
    }

    if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
        NSString *identifier = [region.identifier substringFromIndex:kSyncBeaconIdentifierPrefix.length];
        BOOL alreadyInside = [self.nearbyBeaconIdentifers containsObject:identifier];
        if (alreadyInside) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Already inside beacon region | identifier = %@", identifier]];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Entered beacon region | identifier = %@", identifier]];

            [self.nearbyBeaconIdentifers addObject:identifier];

            CLLocation *location;
            if ([RadarUtils validLocation:manager.location]) {
                location = manager.location;
            } else {
                location = [RadarState lastLocation];
            }
            [self handleLocation:location source:RadarLocationSourceBeaconEnter];
        }
    } else if (manager.location) {
        [self handleLocation:manager.location source:RadarLocationSourceGeofenceEnter];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if (![region.identifier hasPrefix:kIdentifierPrefix]) {
        return;
    }

    if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
        NSString *identifier = [region.identifier substringFromIndex:kSyncBeaconIdentifierPrefix.length];
        BOOL alreadyOutside = ![self.nearbyBeaconIdentifers containsObject:identifier];
        if (alreadyOutside) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Already outside beacon region | identifier = %@", identifier]];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Exited beacon region | identifier = %@", identifier]];

            [self.nearbyBeaconIdentifers removeObject:identifier];

            CLLocation *location;
            if ([RadarUtils validLocation:manager.location]) {
                location = manager.location;
            } else {
                location = [RadarState lastLocation];
            }
            [self handleLocation:location source:RadarLocationSourceBeaconExit];
        }
    } else if (manager.location) {
        [self handleLocation:manager.location source:RadarLocationSourceGeofenceExit];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (![region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
        return;
    }

    NSString *identifier = [region.identifier substringFromIndex:kSyncBeaconIdentifierPrefix.length];
    if (state == CLRegionStateInside) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Inside beacon region | identifier = %@", identifier]];

        [self.nearbyBeaconIdentifers addObject:identifier];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Outside beacon region | identifier = %@", identifier]];

        [self.nearbyBeaconIdentifers removeObject:identifier];
    }
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    if (!manager.location) {
        return;
    }

    if ([visit.departureDate isEqualToDate:[NSDate distantFuture]]) {
        [self handleLocation:manager.location source:RadarLocationSourceVisitArrival];
    } else {
        [self handleLocation:manager.location source:RadarLocationSourceVisitDeparture];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorLocation];

    [self callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];
}

@end
