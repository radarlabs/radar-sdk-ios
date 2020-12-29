//
//  RadarLocationManager.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RadarLocationManager.h"

#import "RadarAPIClient.h"
#import "RadarBackgroundTaskManager.h"
#import "RadarCircleGeometry.h"
#import "RadarLogger.h"
#import "RadarPolygonGeometry.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarUtils.h"

@interface RadarLocationManager ()

@property (assign, nonatomic) BOOL started;
@property (assign, nonatomic) int startedInterval;
@property (assign, nonatomic) BOOL sending;
@property (assign, nonatomic) BOOL scheduled;
@property (strong, nonatomic) NSTimer *timer;
@property (nonnull, strong, nonatomic) NSMutableArray<RadarLocationCompletionHandler> *completionHandlers;

@end

@implementation RadarLocationManager

static NSString *const kRegionIdentifer = @"radar";
static NSString *const kRegionSyncIdentifer = @"radar_sync";

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
    }
    return self;
}

- (void)callCompletionHandlersWithStatus:(RadarStatus)status location:(CLLocation *_Nullable)location {
    @synchronized(self) {
        if (!self.completionHandlers.count) {
            return;
        }

        [[RadarLogger sharedInstance]
            logWithLevel:RadarLogLevelInfo
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
        [self callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];
    }
}

- (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    [self getLocationWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium completionHandler:completionHandler];
}

- (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarLocationCompletionHandler)completionHandler {
    CLAuthorizationStatus authorizationStatus = [self.permissionsHelper locationAuthorizationStatus];
    if (!(authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
        if (self.delegate) {
            [self.delegate didFailWithStatus:RadarStatusErrorPermissions];
        }

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
        if (self.delegate) {
            [self.delegate didFailWithStatus:RadarStatusErrorPermissions];
        }

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

                                                           [[RadarBackgroundTaskManager sharedInstance] startBackgroundTask];

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

    if (!self.sending && !self.scheduled) {
        NSTimeInterval delay = [RadarSettings tracking] ? 10 : 0;

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Scheduling shutdown"];

        [self performSelector:@selector(shutDown) withObject:nil afterDelay:delay];
    }
}

- (void)shutDown {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Shutting down"];

    [[RadarBackgroundTaskManager sharedInstance] endBackgroundTasks];

    [self.lowPowerLocationManager stopUpdatingLocation];
}

- (void)requestLocation {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Requesting location"];

    [self.locationManager requestLocation];
}

- (void)updateTracking {
    [self updateTracking:nil];
}

- (void)updateTracking:(CLLocation *)location {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL tracking = [RadarSettings tracking];
        RadarTrackingOptions *options = [RadarSettings trackingOptions];

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Updating tracking | options = %@; location = %@", [options dictionaryValue], location]];

        if (!tracking && [options.startTrackingAfter timeIntervalSinceNow] < 0) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
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
            if (options.useVisits) {
                [self.locationManager startMonitoringVisits];
            }
            if (options.useSignificantLocationChanges) {
                [self.locationManager startMonitoringSignificantLocationChanges];
            }
        } else {
            [self stopUpdates];
            [self removeAllGeofences];
            [self.locationManager stopMonitoringVisits];
            [self.locationManager stopMonitoringSignificantLocationChanges];
        }
    });
}

- (void)replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences {
    [self removeSyncedGeofences];

    RadarTrackingOptions *options = [RadarSettings trackingOptions];
    if (!options.syncGeofences || !geofences) {
        return;
    }

    for (int i = 0; i < geofences.count; i++) {
        RadarGeofence *geofence = [geofences objectAtIndex:i];
        NSString *identifier = [NSString stringWithFormat:@"%@_%d", kRegionSyncIdentifer, i];
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

    [RadarState setLastGeofences:geofences];
}

- (void)replaceBubbleGeofence:(CLLocation *)location radius:(int)radius {
    [self removeBubbleGeofence];

    NSString *identifier = [NSString stringWithFormat:@"%@_%@", kRegionIdentifer, [[NSUUID UUID] UUIDString]];
    CLRegion *region = [[CLCircularRegion alloc] initWithCenter:location.coordinate radius:radius identifier:identifier];
    [self.locationManager startMonitoringForRegion:region];
    [RadarState setLastBubble:region];
}

- (void)removeSyncedGeofences {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kRegionSyncIdentifer]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
    [RadarState setLastGeofences:nil];
}

- (void)removeBubbleGeofence {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kRegionIdentifer] && ![region.identifier hasPrefix:kRegionSyncIdentifer]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
    [RadarState setLastBubble:nil];
}

- (void)removeAllGeofences {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kRegionIdentifer]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
}

#pragma mark - handlers

- (void)handleLocation:(CLLocation *)location source:(RadarLocationSource)source {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Handling location | source = %@; location = %@", [Radar stringForSource:source], location]];

    if (!location || ![RadarUtils validLocation:location]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Invalid location | source = %@; location = %@", [Radar stringForSource:source], location]];

        [self callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];

        return;
    }

    RadarTrackingOptions *options = [RadarSettings trackingOptions];
    BOOL wasStopped = [RadarState stopped];
    BOOL stopped = NO;

    BOOL force = (source == RadarLocationSourceForegroundLocation || source == RadarLocationSourceManualLocation);
    if (wasStopped && !force && location.horizontalAccuracy >= 1000 && options.desiredAccuracy != RadarTrackingOptionsDesiredAccuracyLow) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Skipping location: inaccurate | accuracy = %f", location.horizontalAccuracy]];

        [self updateTracking:location];

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
            stopped = (distance <= options.stopDistance && duration >= options.stopDuration) || source == RadarLocationSourceVisitArrival;

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

    if (self.delegate) {
        [self.delegate didUpdateClientLocation:location stopped:stopped source:source];
    }

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
    BOOL ignoreSync = !lastSentAt || self.completionHandlers.count || justStopped || replayed;
    NSDate *now = [NSDate new];
    NSTimeInterval lastSyncInterval = [now timeIntervalSinceDate:lastSentAt];
    if (!ignoreSync) {
        if (!force && stopped && wasStopped && distance <= options.stopDistance && (options.desiredStoppedUpdateInterval == 0 || options.sync != RadarTrackingOptionsSyncAll)) {
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
                logWithLevel:RadarLogLevelInfo
                     message:[NSString stringWithFormat:@"Skipping sync: rate limit | justStopped = %d; lastSyncInterval = %f", justStopped, lastSyncInterval]];

            return;
        }

        if (options.sync == RadarTrackingOptionsSyncNone) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                               message:[NSString stringWithFormat:@"Skipping sync: sync mode | sync = %@", [RadarTrackingOptions stringForSync:options.sync]]];

            return;
        }

        BOOL canExit = [RadarState canExit];
        if (!canExit && options.sync == RadarTrackingOptionsSyncStopsAndExits) {
            [[RadarLogger sharedInstance]
                logWithLevel:RadarLogLevelInfo
                     message:[NSString stringWithFormat:@"Skipping sync: can't exit | sync = %@; canExit = %d", [RadarTrackingOptions stringForSync:options.sync], canExit]];

            return;
        }
    }
    [RadarState updateLastSentAt];

    if (source == RadarLocationSourceForegroundLocation) {
        return;
    }

    if (lastSyncInterval < 1) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Scheduling location send"];

        self.scheduled = YES;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self sendLocation:sendLocation stopped:stopped source:source replayed:replayed];

            self.scheduled = NO;
        });
    } else {
        [self sendLocation:sendLocation stopped:stopped source:source replayed:replayed];
    }
}

- (void)sendLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source replayed:(BOOL)replayed {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Sending location | source = %@; location = %@; stopped = %d; replayed = %d",
                                                                          [Radar stringForSource:source], location, stopped, replayed]];

    self.sending = YES;

    [[RadarAPIClient sharedInstance] trackWithLocation:location
                                               stopped:stopped
                                            foreground:[RadarUtils foreground]
                                                source:source
                                              replayed:replayed
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
                                     }
     ];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (locations && locations.count) {
        CLLocation *location = [locations lastObject];
        RadarLocationSource source = self.completionHandlers.count ? RadarLocationSourceForegroundLocation : RadarLocationSourceBackgroundLocation;
        [self handleLocation:location source:source];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if (manager && manager.location) {
        [self handleLocation:manager.location source:RadarLocationSourceGeofenceEnter];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if (manager && manager.location) {
        [self handleLocation:manager.location source:RadarLocationSourceGeofenceExit];
    }
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    if (visit && manager && manager.location) {
        RadarLocationSource source = [visit.departureDate isEqualToDate:[NSDate distantFuture]] ? RadarLocationSourceVisitArrival : RadarLocationSourceVisitDeparture;
        [self handleLocation:manager.location source:source];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (self.delegate) {
        [self.delegate didFailWithStatus:RadarStatusErrorLocation];
    }

    [self callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];
}

@end
