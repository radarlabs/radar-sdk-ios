//
//  RadarLocationManager.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>

#import "CLLocation+Radar.h"
#import "RadarAPIClient.h"
#import "Radar+Internal.h"
#import "RadarBeaconManager.h"
#import "RadarCircleGeometry.h"
#import "RadarDelegateHolder.h"
#import "RadarLocationManager.h"
#import "RadarLocationManager+Internal.h"
#import "RadarLogger.h"
#import "RadarMeta.h"
#import "RadarPolygonGeometry.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarUtils.h"
#import "RadarReplayBuffer.h"
#import "RadarActivityManager.h"
#import "RadarNotificationHelper.h"
#import "RadarIndoorsProtocol.h"
#import "RadarPlace+Internal.h"
#import "RadarBeacon+Internal.h"

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

typedef NS_OPTIONS(NSUInteger, RadarLocationManagerCapability) {
    RadarLocationManagerCapabilityOneShotLocation = 1 << 0,
    RadarLocationManagerCapabilityTrackingLifecycle = 1 << 1,
    RadarLocationManagerCapabilitySyncedGeofences = 1 << 2,
    RadarLocationManagerCapabilityBeaconSync = 1 << 3,
    RadarLocationManagerCapabilitySendPipeline = 1 << 4,
    RadarLocationManagerCapabilityDelegateForegroundLocation = 1 << 5,
    RadarLocationManagerCapabilityDelegateFailure = 1 << 6,
};

@interface RadarLocationManager ()

/**
 `YES` if `startUpdates()` has started the `timer` for location updates.
 */
@property (assign, nonatomic) BOOL started;

/**
 The number of seconds between the `timer`'s location updates.
 */
@property (assign, nonatomic) int startedInterval;

/**
 `YES` if `RadarAPIClient.trackWithLocation() has been called, but the
 response hasn't been received yet.
 */
@property (assign, nonatomic) BOOL sending;

/**
 The timer for checking the location at regular intervals, such as in
 continuous tracking mode.
 */
@property (strong, nonatomic) NSTimer *timer;

/**
 Callbacks for sending events.
 */
@property (nonnull, strong, nonatomic) NSMutableArray<RadarLocationCompletionHandler> *completionHandlers;
@property (nonnull, strong, nonatomic) id<RadarLocationManagerRouting> legacyImplementation;
@property (nonnull, strong, nonatomic) id<RadarLocationManagerRouting> implementation;

- (void)legacy_callCompletionHandlersWithStatus:(RadarStatus)status location:(CLLocation *_Nullable)location;
- (void)legacy_getLocationWithCompletionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
- (void)legacy_getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy
                            completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler;
- (void)legacy_startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions;
- (void)legacy_stopTracking;
- (void)legacy_replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences;
- (void)legacy_replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons;
- (void)legacy_replaceSyncedBeaconUUIDs:(NSArray<NSString *> *)uuids;
- (void)legacy_updateTracking;
- (void)legacy_updateTrackingFromMeta:(RadarMeta *_Nullable)meta;
- (void)legacy_updateTrackingFromInitialize;
- (void)legacy_performIndoorScanIfConfigured:(CLLocation *)location
                                     beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                           completionHandler:(void (^)(NSArray<RadarBeacon *> *_Nullable, NSString *_Nullable))completionHandler;
- (void)legacy_restartPreviousTrackingOptions;
- (void)legacy_locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations;
- (void)legacy_locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region;
- (void)legacy_locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region;
- (void)legacy_locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region;
- (void)legacy_locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit;
- (void)legacy_locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
- (void)legacy_locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading;
- (void)legacy_locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;

@end

@interface RadarLocationManagerLegacyAdapter : NSObject <RadarLocationManagerRouting>

@property (nullable, nonatomic, weak) RadarLocationManager *owner;

@end

@implementation RadarLocationManagerLegacyAdapter

- (void)didUpdateInjectedDependencies {
}

- (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler {
    [self.owner legacy_getLocationWithCompletionHandler:completionHandler];
}

- (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy
                     completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler {
    [self.owner legacy_getLocationWithDesiredAccuracy:desiredAccuracy completionHandler:completionHandler];
}

- (void)startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions {
    [self.owner legacy_startTrackingWithOptions:trackingOptions];
}

- (void)stopTracking {
    [self.owner legacy_stopTracking];
}

- (void)replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences {
    [self.owner legacy_replaceSyncedGeofences:geofences];
}

- (void)replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons {
    [self.owner legacy_replaceSyncedBeacons:beacons];
}

- (void)replaceSyncedBeaconUUIDs:(NSArray<NSString *> *)uuids {
    [self.owner legacy_replaceSyncedBeaconUUIDs:uuids];
}

- (void)updateTracking {
    [self.owner legacy_updateTracking];
}

- (void)updateTrackingFromMeta:(RadarMeta *_Nullable)meta {
    [self.owner legacy_updateTrackingFromMeta:meta];
}

- (void)updateTrackingFromInitialize {
    [self.owner legacy_updateTrackingFromInitialize];
}

- (void)performIndoorScanIfConfigured:(CLLocation *)location
                              beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                    completionHandler:(void (^)(NSArray<RadarBeacon *> *_Nullable, NSString *_Nullable))completionHandler {
    [self.owner legacy_performIndoorScanIfConfigured:location beacons:beacons completionHandler:completionHandler];
}

- (void)restartPreviousTrackingOptions {
    [self.owner legacy_restartPreviousTrackingOptions];
}

- (void)callCompletionHandlersWithStatus:(RadarStatus)status location:(CLLocation *_Nullable)location {
    [self.owner legacy_callCompletionHandlersWithStatus:status location:location];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self.owner legacy_locationManager:manager didUpdateLocations:locations];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self.owner legacy_locationManager:manager didEnterRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self.owner legacy_locationManager:manager didExitRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    [self.owner legacy_locationManager:manager didDetermineState:state forRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    [self.owner legacy_locationManager:manager didVisit:visit];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.owner legacy_locationManager:manager didFailWithError:error];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    [self.owner legacy_locationManager:manager didUpdateHeading:newHeading];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self.owner legacy_locationManager:manager didChangeAuthorizationStatus:status];
}

@end

@interface RadarLocationManagerAdapter : NSObject <RadarLocationManagerRouting>

@property (nullable, nonatomic, weak) RadarLocationManager *owner;
@property (nonnull, nonatomic, strong) RadarLocationManagerImplementation *implementation;

@end

@implementation RadarLocationManagerAdapter

- (instancetype)init {
    self = [super init];
    if (self) {
        _implementation = [RadarLocationManagerImplementation new];
    }
    return self;
}

- (void)didUpdateInjectedDependencies {
    [self.implementation didUpdateInjectedDependencies];
}

- (void)failFastForSelector:(SEL)selector {
    [self.implementation failFastWithMethod:NSStringFromSelector(selector)];
}

- (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler {
    [self failFastForSelector:_cmd];
}

- (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy
                     completionHandler:(RadarLocationCompletionHandler _Nullable)completionHandler {
    [self failFastForSelector:_cmd];
}

- (void)startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions {
    [self failFastForSelector:_cmd];
}

- (void)stopTracking {
    [self failFastForSelector:_cmd];
}

- (void)replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences {
    [self failFastForSelector:_cmd];
}

- (void)replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons {
    [self failFastForSelector:_cmd];
}

- (void)replaceSyncedBeaconUUIDs:(NSArray<NSString *> *)uuids {
    [self failFastForSelector:_cmd];
}

- (void)updateTracking {
    [self failFastForSelector:_cmd];
}

- (void)updateTrackingFromMeta:(RadarMeta *_Nullable)meta {
    [self failFastForSelector:_cmd];
}

- (void)updateTrackingFromInitialize {
    [self failFastForSelector:_cmd];
}

- (void)performIndoorScanIfConfigured:(CLLocation *)location
                              beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                    completionHandler:(void (^)(NSArray<RadarBeacon *> *_Nullable, NSString *_Nullable))completionHandler {
    [self failFastForSelector:_cmd];
}

- (void)restartPreviousTrackingOptions {
    [self failFastForSelector:_cmd];
}

- (void)callCompletionHandlersWithStatus:(RadarStatus)status location:(CLLocation *_Nullable)location {
    [self failFastForSelector:_cmd];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self failFastForSelector:_cmd];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self failFastForSelector:_cmd];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self failFastForSelector:_cmd];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    [self failFastForSelector:_cmd];
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    [self failFastForSelector:_cmd];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self failFastForSelector:_cmd];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    [self failFastForSelector:_cmd];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self failFastForSelector:_cmd];
}

@end

@implementation RadarLocationManager

static NSString *const kIdentifierPrefix = @"radar_";
static NSString *const kBubbleGeofenceIdentifierPrefix = @"radar_bubble_";
static NSString *const kSyncGeofenceIdentifierPrefix = @"radar_geofence_";
static NSString *const kSyncBeaconIdentifierPrefix = @"radar_beacon_";
static NSString *const kSyncBeaconUUIDIdentifierPrefix = @"radar_uuid_";
static const RadarLocationManagerCapability kRadarLocationManagerImplementedCapabilities = 0;

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
        _legacyImplementation = [RadarLocationManagerLegacyAdapter new];
        _legacyImplementation.owner = self;
        _implementation = [RadarLocationManagerAdapter new];
        _implementation.owner = self;

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
        [self didUpdateInjectedDependencies];
    }
    return self;
}

- (BOOL)usesImplementationForCapability:(RadarLocationManagerCapability)capability {
    return RadarSettings.locationManagerSwiftMigrationEnabled &&
           (kRadarLocationManagerImplementedCapabilities & capability) == capability;
}

- (id<RadarLocationManagerRouting>)implementationForCapability:(RadarLocationManagerCapability)capability {
    return [self usesImplementationForCapability:capability] ? self.implementation : self.legacyImplementation;
}

- (void)didUpdateInjectedDependencies {
    self.locationManager.delegate = self;
    [self.legacyImplementation didUpdateInjectedDependencies];
    [self.implementation didUpdateInjectedDependencies];
}

- (void)setLocationManager:(CLLocationManager *)locationManager {
    _locationManager = locationManager;
    [self didUpdateInjectedDependencies];
}

- (void)setLowPowerLocationManager:(CLLocationManager *)lowPowerLocationManager {
    _lowPowerLocationManager = lowPowerLocationManager;
    [self didUpdateInjectedDependencies];
}

- (void)setPermissionsHelper:(RadarPermissionsHelper *)permissionsHelper {
    _permissionsHelper = permissionsHelper;
    [self didUpdateInjectedDependencies];
}

- (void)setActivityManager:(RadarActivityManager *)activityManager {
    _activityManager = activityManager;
    [self didUpdateInjectedDependencies];
}

- (void)callCompletionHandlersWithStatus:(RadarStatus)status location:(CLLocation *_Nullable)location {
    [[self implementationForCapability:RadarLocationManagerCapabilityOneShotLocation] callCompletionHandlersWithStatus:status location:location];
}

- (void)legacy_callCompletionHandlersWithStatus:(RadarStatus)status location:(CLLocation *_Nullable)location {
    @synchronized(self) {
        if (!self.completionHandlers.count){
            return;
        }

        [[RadarLogger sharedInstance]
            logWithLevel:RadarLogLevelDebug
                 message:[NSString stringWithFormat:@"Calling completion handlers | self.completionHandlers.count = %lu", (unsigned long)self.completionHandlers.count]];

        for (RadarLocationCompletionHandler completionHandler in self.completionHandlers) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(legacy_timeoutWithCompletionHandler:) object:completionHandler];

            completionHandler(status, location, [RadarState stopped]);
        }

        [self.completionHandlers removeAllObjects];
    }
}

- (void)legacy_addCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    if (!completionHandler) {
        return;
    }

    @synchronized(self) {
        RadarLocationCompletionHandler completionHandlerCopy = [completionHandler copy];
        [self.completionHandlers addObject:completionHandlerCopy];

        [self performSelector:@selector(legacy_timeoutWithCompletionHandler:) withObject:completionHandlerCopy afterDelay:20];
    }
}

- (void)legacy_cancelTimeouts {
    @synchronized(self) {
        for (RadarLocationCompletionHandler completionHandler in self.completionHandlers) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(legacy_timeoutWithCompletionHandler:) object:completionHandler];
        }
    }
}

- (void)legacy_timeoutWithCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    @synchronized(self) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Location timeout"];

        [self legacy_callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];
    }
}

- (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    [[self implementationForCapability:RadarLocationManagerCapabilityOneShotLocation] getLocationWithCompletionHandler:completionHandler];
}

- (void)legacy_getLocationWithCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    [self legacy_getLocationWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium completionHandler:completionHandler];
}

- (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarLocationCompletionHandler)completionHandler {
    [[self implementationForCapability:RadarLocationManagerCapabilityOneShotLocation] getLocationWithDesiredAccuracy:desiredAccuracy completionHandler:completionHandler];
}

- (void)legacy_getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarLocationCompletionHandler)completionHandler {
    CLAuthorizationStatus authorizationStatus = [self.permissionsHelper locationAuthorizationStatus];
    if (!(authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
        [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorPermissions];

        if (completionHandler) {
            completionHandler(RadarStatusErrorPermissions, nil, NO);
        }
        return;
    }

    [self legacy_addCompletionHandler:completionHandler];

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
    [self legacy_requestLocation];
}

- (void)startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions {
    [[self implementationForCapability:RadarLocationManagerCapabilityTrackingLifecycle] startTrackingWithOptions:trackingOptions];
}

- (void)legacy_startTrackingWithOptions:(RadarTrackingOptions *)trackingOptions {
    CLAuthorizationStatus authorizationStatus = [self.permissionsHelper locationAuthorizationStatus];
    if (!(authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
        [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorPermissions];
        return;
    }

    [RadarSettings setTracking:YES];
    [RadarSettings setTrackingOptions:trackingOptions];
    [self legacy_updateTracking];
}

- (void)stopTracking {
    [[self implementationForCapability:RadarLocationManagerCapabilityTrackingLifecycle] stopTracking];
}

- (void)legacy_stopTracking {
    [RadarSettings setTracking:NO];

    RadarSdkConfiguration *sdkConfiguration = [RadarSettings sdkConfiguration];
    if (sdkConfiguration.extendFlushReplays) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"Flushing replays from stopTracking()"];
        [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
    }

    RadarTrackingOptions *trackingOptions = [RadarSettings trackingOptions];
    if (trackingOptions.useMotion || trackingOptions.usePressure) {
        [self.locationManager stopUpdatingHeading];
        if (self.activityManager) {
            if (trackingOptions.usePressure) {
                [self.activityManager stopRelativeAltitudeUpdates];
                [self.activityManager stopAbsoluteAltitudeUpdates];
            }
            if (trackingOptions.useMotion) {
                [self.activityManager stopActivityUpdates];
            }
       }
    }

    // null out startTrackingAfter and stopTrackingAfter in local tracking options
    // so that subsequent trackOnce calls don't restart tracking
    trackingOptions.startTrackingAfter = nil;
    trackingOptions.stopTrackingAfter = nil;
    [RadarSettings setTrackingOptions:trackingOptions];

    [self legacy_updateTracking];
}

- (void)legacy_startUpdates:(int)interval blueBar:(BOOL)blueBar {
    if (!self.started || interval != self.startedInterval) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Starting timer | interval = %d", interval]];

        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(legacy_shutDown) object:nil];

        if (self.timer) {
            [self.timer invalidate];
        }

        self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                     repeats:YES
                                                       block:^(NSTimer *_Nonnull timer) {
                                                           [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Timer fired"];

                                                           [self legacy_requestLocation];
                                                       }];

        [self.lowPowerLocationManager startUpdatingLocation];
        if (blueBar && interval <= 5) {
            [self.locationManager startUpdatingLocation];
        } else {
            [self.locationManager stopUpdatingLocation];
        }

        self.started = YES;
        self.startedInterval = interval;
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Already started timer"];
    }
}

- (void)legacy_stopUpdates {
    if (!self.timer) {
        return;
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Stopping timer"];

    [self.timer invalidate];

    [self.locationManager stopUpdatingLocation];
    
    self.started = NO;
    self.startedInterval = 0;

    if (!self.sending) {
        NSTimeInterval delay = [RadarSettings tracking] ? 10 : 0;

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Scheduling shutdown"];

        [self performSelector:@selector(legacy_shutDown) withObject:nil afterDelay:delay];
    }
}

- (void)legacy_shutDown {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Shutting down"];

    [self.locationManager stopUpdatingLocation];
    [self.lowPowerLocationManager stopUpdatingLocation];
}

- (void)legacy_requestLocation {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Requesting location"];

    [self.locationManager requestLocation];
}

- (void)updateTracking {
    [[self implementationForCapability:RadarLocationManagerCapabilityTrackingLifecycle] updateTracking];
}

- (void)legacy_updateTracking {
    [self legacy_updateTracking:nil fromInitialize:NO];
}

- (void)updateTrackingFromInitialize {
    [[self implementationForCapability:RadarLocationManagerCapabilityTrackingLifecycle] updateTrackingFromInitialize];
}

- (void)legacy_updateTrackingFromInitialize {
    [self legacy_updateTracking:nil fromInitialize:YES];
}

- (void)legacy_updateTracking:(CLLocation *)location {
    [self legacy_updateTracking:location fromInitialize:NO];
}

- (void)legacy_updateTracking:(CLLocation *)location fromInitialize:(BOOL)fromInitialize {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL tracking = [RadarSettings tracking];
        RadarTrackingOptions *options = [Radar getTrackingOptions];
        RadarTrackingOptions *localOptions = [RadarSettings trackingOptions];

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Updating tracking | options = %@; location = %@", [options dictionaryValue], location]];

        if (!tracking && [localOptions.startTrackingAfter timeIntervalSinceNow] < 0) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Starting time-based tracking | startTrackingAfter = %@", options.startTrackingAfter]];

            [RadarSettings setTracking:YES];
            tracking = YES;
        } else if (tracking && [localOptions.stopTrackingAfter timeIntervalSinceNow] < 0) {
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

                

            if (options.useMotion) {
                self.activityManager = [RadarActivityManager sharedInstance];
                self.locationManager.headingFilter = 5;
                [self.locationManager startUpdatingHeading];
                [self.activityManager startActivityUpdatesWithHandler:^(CMMotionActivity *activity) {
                    if (activity) {
                        RadarActivityType activityType = RadarActivityTypeUnknown;
                        if (activity.stationary) {
                        activityType = RadarActivityTypeStationary; 
                        } else if (activity.walking) {
                            activityType = RadarActivityTypeFoot;
                        } else if (activity.running) {
                            activityType = RadarActivityTypeFoot;
                        } else if (activity.automotive) {
                            activityType = RadarActivityTypeCar;
                        } else if (activity.cycling) {
                            activityType = RadarActivityTypeBike;
                        }
                        
                        if (activityType == RadarActivityTypeUnknown) {
                            return;
                        }
                        
                        NSString *previousActivityType = [RadarState lastMotionActivityData][@"type"];
                        if (previousActivityType != nil && [previousActivityType isEqualToString:[Radar stringForActivityType:activityType]]) {
                            return;
                        }

                        [RadarState setLastMotionActivityData:@{
                            @"type" : [Radar stringForActivityType:activityType],
                            @"timestamp" : @([activity.startDate timeIntervalSince1970]),
                            @"confidence" : @(activity.confidence)
                        }];
                        
                        if (options.syncLocations != RadarTrackingOptionsSyncEvents) {
                            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Activity detected, initiating trackOnce"];
                            [Radar trackOnceWithCompletionHandler: nil];
                        }
                    }
                }];
            }
            if (options.usePressure) {
                self.activityManager = [RadarActivityManager sharedInstance];
                [RadarState setMotionAuthorizationString:[Radar stringForMotionAuthorizationStatus]];
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"usePressure enabled: starting relative altitude updates, auth status: %@", [Radar stringForMotionAuthorizationStatus]]];
                [self.activityManager startRelativeAltitudeWithHandler: ^(CMAltitudeData * _Nullable altitudeData) {
                    if (!altitudeData) {
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"Relative altitude callback received nil data"];
                        return;
                    }
                    NSMutableDictionary *currentState = [[RadarState lastRelativeAltitudeData] mutableCopy] ?: [NSMutableDictionary new];
                    currentState[@"pressure"] = @(altitudeData.pressure.doubleValue *10); // convert to hPa
                    currentState[@"relativeAltitude"] = @(altitudeData.relativeAltitude.doubleValue);
                    currentState[@"relativeAltitudeTimestamp"] = @([[NSDate date] timeIntervalSince1970]);
                    [RadarState setLastRelativeAltitudeData:currentState];
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Stored relative altitude: pressure=%.1f hPa, relative=%.3f m", altitudeData.pressure.doubleValue * 10.0, altitudeData.relativeAltitude.doubleValue]];
                }];

                if (@available(iOS 15.0, *)) {
                    [RadarState setMotionAuthorizationString:[Radar stringForMotionAuthorizationStatus]];
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"usePressure enabled: starting absolute altitude updates (iOS 15+), auth status: %@", [Radar stringForMotionAuthorizationStatus]]];
                    [self.activityManager startAbsoluteAltitudeWithHandler: ^(CMAbsoluteAltitudeData * _Nullable altitudeData) {
                        if (!altitudeData) {
                            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelWarning message:@"Absolute altitude callback received nil data"];
                            return;
                        }
                        NSMutableDictionary *currentState = [[RadarState lastRelativeAltitudeData] mutableCopy] ?: [NSMutableDictionary new];
                        currentState[@"altitude"] = @(altitudeData.altitude);
                        currentState[@"accuracy"] = @(altitudeData.accuracy);
                        currentState[@"precision"] = @(altitudeData.precision);
                        currentState[@"absoluteAltitudeTimestamp"] = @([[NSDate date] timeIntervalSince1970]);
                        [RadarState setLastRelativeAltitudeData:currentState];
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Stored absolute altitude: altitude=%.3f m, accuracy=%.3f m, precision=%.3f m", altitudeData.altitude, altitudeData.accuracy, altitudeData.precision]];
                    }];
                }
            }
        
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

            self.lowPowerLocationManager.showsBackgroundLocationIndicator = options.showBlueBar;

            BOOL startUpdates = options.showBlueBar || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
            BOOL stopped = [RadarState stopped];
            if (stopped) {
                if (options.desiredStoppedUpdateInterval == 0) {
                    [self legacy_stopUpdates];
                } else if (startUpdates) {
                    [self legacy_startUpdates:options.desiredStoppedUpdateInterval blueBar:options.showBlueBar];
                }
                if (options.useStoppedGeofence) {
                    if (location) {
                        [self legacy_replaceBubbleGeofence:location radius:options.stoppedGeofenceRadius];
                    }
                } else {
                    [self legacy_removeBubbleGeofence];
                }
            } else {
                if (options.desiredMovingUpdateInterval == 0) {
                    [self legacy_stopUpdates];
                } else if (startUpdates) {
                    [self legacy_startUpdates:options.desiredMovingUpdateInterval blueBar:options.showBlueBar];
                }
                if (options.useMovingGeofence) {
                    if (location) {
                        [self legacy_replaceBubbleGeofence:location radius:options.movingGeofenceRadius];
                    }
                } else {
                    [self legacy_removeBubbleGeofence];
                }
            }
            if (!options.syncGeofences) {
                [self legacy_removeSyncedGeofences];
            }
            if (options.useVisits) {
                [self.locationManager startMonitoringVisits];
            } else {
                [self.locationManager stopMonitoringVisits];
            }
            if (options.useSignificantLocationChanges) {
                [self.locationManager startMonitoringSignificantLocationChanges];
            } else {
                [self.locationManager stopMonitoringSignificantLocationChanges];
            }
            if (!options.beacons) {
                [self legacy_removeSyncedBeacons];
            }
        } else {
            [self legacy_stopUpdates];
            [self legacy_removeAllRegions];

            // If updateTracking() was called from the RadarLocationManager
            // initializer, don't tell the CLLocationManager to stop, because
            // the location manager may be in use by other location-based
            // services. Currently, only the initializer passes in YES, and all
            // subsequent calls to updateTracking() get NO.
            if (!fromInitialize) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Stopping monitoring visits and SLCs"]];

                [self.locationManager stopMonitoringVisits];
                [self.locationManager stopMonitoringSignificantLocationChanges];
            }
        }
    });
}

- (void)updateTrackingFromMeta:(RadarMeta *_Nullable)meta {
    [[self implementationForCapability:RadarLocationManagerCapabilityTrackingLifecycle] updateTrackingFromMeta:meta];
}

- (void)legacy_updateTrackingFromMeta:(RadarMeta *_Nullable)meta {
    if (meta) {
        if ([meta trackingOptions]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Setting remote tracking options | trackingOptions = %@", meta.trackingOptions]];
            [RadarSettings setRemoteTrackingOptions:[meta trackingOptions]];
        } else {
            [RadarSettings setRemoteTrackingOptions:nil];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Removed remote tracking options | trackingOptions = %@", Radar.getTrackingOptions]];
        }
    }
    [self legacy_updateTrackingFromInitialize];

}

- (void)restartPreviousTrackingOptions {
    [[self implementationForCapability:RadarLocationManagerCapabilityTrackingLifecycle] restartPreviousTrackingOptions];
}

- (void)legacy_restartPreviousTrackingOptions {
    RadarTrackingOptions *previousTrackingOptions = [RadarSettings previousTrackingOptions];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Restarting previous tracking options"];

    if (previousTrackingOptions) {
        [Radar startTrackingWithOptions:previousTrackingOptions];
    } else {
        [Radar stopTracking];
    }

    [RadarSettings setPreviousTrackingOptions:nil];
}

- (void)legacy_replaceBubbleGeofence:(CLLocation *)location radius:(int)radius {
    [self legacy_removeBubbleGeofence];

    BOOL tracking = [RadarSettings tracking];
    if (!tracking) {
        return;
    }

    NSString *identifier = [NSString stringWithFormat:@"%@%@", kBubbleGeofenceIdentifierPrefix, [[NSUUID UUID] UUIDString]];
    CLRegion *region = [[CLCircularRegion alloc] initWithCenter:location.coordinate radius:radius identifier:identifier];
    [self.locationManager startMonitoringForRegion:region];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Successfully added bubble geofence | latitude = %f; longitude = %f; radius = %d; identifier = %@",
                                                                          location.coordinate.latitude, location.coordinate.longitude, radius, identifier]];
}

- (void)legacy_removeBubbleGeofence {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kBubbleGeofenceIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Removed bubble geofences"];
}

- (void)replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences {
    [[self implementationForCapability:RadarLocationManagerCapabilitySyncedGeofences] replaceSyncedGeofences:geofences];
}

- (void)legacy_replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences {
    if (@available(iOS 13.0, *)) {
        if ([RadarSettings sdkConfiguration].useNotificationDiffV2) {
            [[RadarNotificationHelper_Swift shared]
             registerGeofenceNotificationsWithGeofences:[RadarGeofence arrayForGeofences:geofences]
             completionHandler:^() {}
            ];
        }
    }
    
    if (!geofences) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Skipping replacing synced geofences"];

        return;
    }
    
    [self legacy_removeSyncedGeofences];

    RadarTrackingOptions *options = [Radar getTrackingOptions];
    NSUInteger numGeofences = MIN(geofences.count, options.beacons ? 9 : 19);
    NSMutableArray *requests = [NSMutableArray array]; 

    for (int i = 0; i < numGeofences; i++) {
        RadarGeofence *geofence = [geofences objectAtIndex:i];
        NSString *geofenceId = geofence._id;
        NSString *identifier = [NSString stringWithFormat:@"%@%@", kSyncGeofenceIdentifierPrefix, geofenceId];
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

            NSDictionary *metadata = geofence.metadata;
            if (metadata) {
                UNMutableNotificationContent *content = [RadarNotificationHelper extractContentFromMetadata:metadata identifier:identifier];
                if (content) {

                    region.notifyOnEntry = YES;
                    region.notifyOnExit = NO;
                    BOOL repeats = NO;
                    NSString *notificationRepeats = [geofence.metadata objectForKey:@"radar:notificationRepeats"];
                    if (notificationRepeats) {
                        repeats = [notificationRepeats boolValue];
                    }
                    if (repeats) {
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Notification repeats"];
                    } else {
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Notification does not repeat"];
                    }

                    UNLocationNotificationTrigger *trigger = [UNLocationNotificationTrigger triggerWithRegion:region repeats:repeats];

                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                    [requests addObject:request];
                } else {
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"No notification text for geofence | geofenceId = %@", geofenceId]];
                }
            }
        }
    }
    
    
    if (@available(iOS 13.0, *)) {
        if ([RadarSettings sdkConfiguration].useNotificationDiffV2) {
            // we've already registered notifications before the geofences
            return;
        }
    }
    [RadarNotificationHelper updateClientSideCampaignsWithPrefix:kSyncGeofenceIdentifierPrefix notificationRequests:requests];
}

- (void)legacy_removeSyncedGeofences {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kSyncGeofenceIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Removed synced geofences"];
}

- (NSArray<NSString *> *)legacy_matchBeaconIds:(NSArray<RadarBeacon *> *)rangedBeacons syncedBeacons:(NSArray<RadarBeacon *> *)syncedBeacons {
    NSMutableDictionary<NSString *, NSString *> *syncedMap = [NSMutableDictionary dictionary];
    for (RadarBeacon *sb in syncedBeacons) {
        NSString *key = [NSString stringWithFormat:@"%@|%@|%@", [sb.uuid lowercaseString] ?: @"", sb.major ?: @"", sb.minor ?: @""];
        if (sb._id && [sb._id isKindOfClass:[NSString class]]) {
            syncedMap[key] = sb._id;
        }
    }
    NSMutableArray<NSString *> *matched = [NSMutableArray array];
    for (RadarBeacon *b in rangedBeacons) {
        NSString *key = [NSString stringWithFormat:@"%@|%@|%@", [b.uuid lowercaseString] ?: @"", b.major ?: @"", b.minor ?: @""];
        NSString *matchedId = syncedMap[key];
        if (matchedId) {
            [matched addObject:matchedId];
        }
    }
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"Beacon ID matching | synced=%lu, ranged=%lu, matchedIds=%@", (unsigned long)syncedMap.count, (unsigned long)rangedBeacons.count, matched]];
    return [matched copy];
}

- (void)replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons {
    [[self implementationForCapability:RadarLocationManagerCapabilityBeaconSync] replaceSyncedBeacons:beacons];
}

- (void)legacy_replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons {
    if ([RadarSettings useRadarModifiedBeacon]) {
        return;
    }
    
    [self legacy_removeSyncedBeacons];

    BOOL tracking = [RadarSettings tracking];
    RadarTrackingOptions *options = [Radar getTrackingOptions];
    if (!tracking || !options.beacons || !beacons) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Skipping replacing synced beacons"];

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

- (void)replaceSyncedBeaconUUIDs:(NSArray<NSString *> *)uuids {
    [[self implementationForCapability:RadarLocationManagerCapabilityBeaconSync] replaceSyncedBeaconUUIDs:uuids];
}

- (void)legacy_replaceSyncedBeaconUUIDs:(NSArray<NSString *> *)uuids {
    if ([RadarSettings useRadarModifiedBeacon]) {
        return;
    }
    
    [self legacy_removeSyncedBeacons];

    BOOL tracking = [RadarSettings tracking];
    RadarTrackingOptions *options = [Radar getTrackingOptions];
    if (!tracking || !options.beacons || !uuids) {
        return;
    }

    NSUInteger numUUIDs = MIN(uuids.count, 9);

    for (int i = 0; i < numUUIDs; i++) {
        NSString *uuid = uuids[i];
        NSString *identifier = [NSString stringWithFormat:@"%@%@", kSyncBeaconUUIDIdentifierPrefix, uuid];
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:uuid] identifier:identifier];

        if (region) {
            region.notifyEntryStateOnDisplay = YES;
            [self.locationManager startMonitoringForRegion:region];
            [self.locationManager requestStateForRegion:region];

            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Synced UUID | identifier = %@; uuid = %@", identifier, uuid]];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error syncing UUID | identifier = %@; uuid = %@", identifier, uuid]];
        }
    }
}

- (void)legacy_removeSyncedBeacons {
    if ([RadarSettings useRadarModifiedBeacon]) {
        return;
    }
    
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kSyncBeaconUUIDIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        } else if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
}

- (void)legacy_removeAllRegions {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
}

#pragma mark - handlers

- (void)legacy_handleLocation:(CLLocation *)location source:(RadarLocationSource)source {
    [self legacy_handleLocation:location source:source beacons:nil];
}

- (void)legacy_handleLocation:(CLLocation *)location source:(RadarLocationSource)source beacons:(NSArray<RadarBeacon *> *)beacons {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Handling location | source = %@; location = %@", [Radar stringForLocationSource:source], location]];

    [self legacy_cancelTimeouts];

    if (!location.isValid) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Invalid location | source = %@; location = %@", [Radar stringForLocationSource:source], location]];

        [self legacy_callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];

        return;
    }

    RadarTrackingOptions *options = [Radar getTrackingOptions];
    BOOL wasStopped = [RadarState stopped];
    BOOL stopped = NO;

    BOOL force = (source == RadarLocationSourceForegroundLocation || source == RadarLocationSourceManualLocation) || (options.syncLocations != RadarTrackingOptionsSyncEvents && (source == RadarLocationSourceBeaconEnter ||
                  source == RadarLocationSourceBeaconExit || source == RadarLocationSourceVisitArrival));
    if (wasStopped && !force && location.horizontalAccuracy >= 1000 && options.desiredAccuracy != RadarTrackingOptionsDesiredAccuracyLow) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Skipping location: inaccurate | accuracy = %f", location.horizontalAccuracy]];

        [self legacy_updateTracking:location];

        return;
    }

    BOOL tracking = [RadarSettings tracking];
    if (!force && !tracking) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Skipping location: not tracking"];

        return;
    }

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
            BOOL arrival = source == RadarLocationSourceVisitArrival;
            stopped = (distance <= options.stopDistance && duration >= options.stopDuration) || arrival;

            [[RadarLogger sharedInstance]
                logWithLevel:RadarLogLevelDebug
                     message:[NSString stringWithFormat:@"Calculating stopped | stopped = %d; arrival = %d; distance = %f; duration = %f; location.timestamp = %@; lastMovedAt = %@", stopped,
                              arrival, distance, duration, location.timestamp, lastMovedAt]];

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
        [self legacy_updateTracking:location];
    }

    [self legacy_callCompletionHandlersWithStatus:RadarStatusSuccess location:location];
    
    if ([RadarSettings sdkConfiguration].useSyncRegion) {
        if (![RadarSyncManager hasSyncedRegion]) {
            [RadarSyncManager fetchSyncRegion];
        } else if ([RadarSettings sdkConfiguration].offlineEventGenerationEnabled
                   && ([RadarSyncManager isOutsideSyncedRegionWithLocation:location] ||
                       [RadarSyncManager isNearSyncedRegionBoundaryWithLocation:location])) {
            [RadarSyncManager fetchSyncRegion];
        }
    }

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
            (options.desiredStoppedUpdateInterval == 0 || (options.syncLocations != RadarTrackingOptionsSyncAll && options.syncLocations != RadarTrackingOptionsSyncEvents))) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Skipping sync: already stopped | stopped = %d; wasStopped = %d", stopped, wasStopped]];

            return;
        }

        // add a 0.1 second buffer to account for the fact that the timer may fire slightly before the desired interval
        NSTimeInterval lastSyncIntervalWithBuffer = lastSyncInterval + 0.1;
        if (lastSyncIntervalWithBuffer < options.desiredSyncInterval) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Skipping sync: desired sync interval | desiredSyncInterval = %d; lastSyncInterval = %f",
                                                                                  options.desiredSyncInterval, lastSyncIntervalWithBuffer]];

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
    
    if (source != RadarLocationSourceForegroundLocation && source != RadarLocationSourceManualLocation &&
        [RadarSettings sdkConfiguration].useSyncRegion && options.syncLocations == RadarTrackingOptionsSyncEvents) {
        
        if (location.horizontalAccuracy >= 1000 && options.desiredAccuracy != RadarTrackingOptionsDesiredAccuracyLow) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                               message:[NSString stringWithFormat:@"Skipping sync region eval: inaccurate | accuracy = %f", location.horizontalAccuracy]];
            return;
        }
        
        BOOL geofenceOrPlaceChanged = [RadarSyncManager shouldTrackWithLocation:location options:options];
        
        if (geofenceOrPlaceChanged) {
            [RadarState updateLastSentAt];
            [self legacy_sendLocation:sendLocation stopped:stopped source:source replayed:replayed beacons:beacons forceTrack:YES];
            return;
        }
        
        if (options.beacons) {
            [self legacy_sendLocation:sendLocation stopped:stopped source:source replayed:replayed beacons:beacons forceTrack:NO];
            return;
        }
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                           message:[NSString stringWithFormat:@"Skipping track: useSyncRegion - no state change detected | source = %@", [Radar stringForLocationSource:source]]];
        return;
    }
    
    [RadarState updateLastSentAt];

    if (source == RadarLocationSourceForegroundLocation) {
        return;
    }

    [self legacy_sendLocation:sendLocation stopped:stopped source:source replayed:replayed beacons:beacons forceTrack:YES];
}

- (void)performIndoorScanIfConfigured:(CLLocation *)location
                               beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                     completionHandler:(void (^)(NSArray<RadarBeacon *> *_Nullable, NSString *_Nullable))completionHandler {
    [[self implementationForCapability:RadarLocationManagerCapabilitySendPipeline] performIndoorScanIfConfigured:location
                                                                                                  beacons:beacons
                                                                                        completionHandler:completionHandler];
}

- (void)legacy_performIndoorScanIfConfigured:(CLLocation *)location
                                     beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                           completionHandler:(void (^)(NSArray<RadarBeacon *> *_Nullable, NSString *_Nullable))completionHandler {
    RadarTrackingOptions *options = [Radar getTrackingOptions];
    Class RadarSDKIndoors = NSClassFromString(@"RadarSDKIndoors");
    
    if (options.useIndoorScan && ![RadarSettings inSurveyMode] && RadarSDKIndoors && [RadarUtilsDeprecated foreground]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Starting indoor scan"];
        
        [RadarSDKIndoors startIndoorScan:@""
                                forLength:5
                        withKnownLocation:location
                        completionHandler:^(NSString *_Nullable indoorScanResult, CLLocation *_Nullable locationAtStartOfScan) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                               message:[NSString stringWithFormat:@"Indoor scan completed: %lu chars", (unsigned long)(indoorScanResult ? indoorScanResult.length : 0)]];
            completionHandler(beacons, indoorScanResult);
        }];
    } else {
        if (options.useIndoorScan && ![RadarSettings inSurveyMode] && !RadarSDKIndoors) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"RadarSDKIndoors not available, skipping indoor scan"];
        } else if (options.useIndoorScan && ![RadarSettings inSurveyMode] && RadarSDKIndoors && ![RadarUtilsDeprecated foreground]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"App in background, skipping indoor scan (Bluetooth not available)"];
        }
        completionHandler(beacons, nil);
    }
}

- (void)legacy_sendLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source replayed:(BOOL)replayed beacons:(NSArray<RadarBeacon *> *_Nullable)beacons forceTrack:(BOOL)forceTrack {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Sending location | source = %@; location = %@; stopped = %d; replayed = %d; beacons = %@; forceTrack = %d",
                                                                          [Radar stringForLocationSource:source], location, stopped, replayed, beacons, forceTrack]];

    self.sending = YES;

    RadarTrackingOptions *options = [Radar getTrackingOptions];
    
    if ([RadarSettings useRadarModifiedBeacon]) {
        void (^callTrackAPI)(NSArray<RadarBeacon *> *_Nullable) = ^(NSArray<RadarBeacon *> *_Nullable beacons) {
            [self legacy_performIndoorScanIfConfigured:location
                                               beacons:beacons
                                     completionHandler:^(NSArray<RadarBeacon *> *_Nullable beacons, NSString *_Nullable indoorScan) {
                [[RadarAPIClient sharedInstance] trackWithLocation:location
                                                           stopped:stopped
                                                        foreground:[RadarUtilsDeprecated foreground]
                                                            source:source
                                                          replayed:replayed
                                                           beacons:beacons
                                                      indoorScan:indoorScan
                                                 completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                                     NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
                    self.sending = NO;
                    
                    if ([RadarSettings sdkConfiguration].useSyncRegion) {
                        if (status == RadarStatusSuccess && user) {
                            [RadarSyncManager reconcileSyncStateWithUser:user];
                            
                            for (RadarEvent *event in events) {
                                if (event.type == RadarEventTypeUserDwelledInGeofence && event.geofence && event.geofence._id) {
                                    [RadarSyncManager markDwellFired: event.geofence._id];
                                }
                            }
                        } else {
                            [RadarSyncManager rollbackSyncState];
                        }
                    }
                    
                    [self legacy_updateTrackingFromMeta:config.meta];
                    [self legacy_replaceSyncedGeofences:nearbyGeofences];
                }];
            }];
        };
        
        if (options.beacons &&
            source != RadarLocationSourceBeaconEnter &&
            source != RadarLocationSourceBeaconExit &&
            source != RadarLocationSourceMockLocation &&
            source != RadarLocationSourceManualLocation) {
            
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Searching for nearby beacons"];
            
            if ([RadarSettings sdkConfiguration].useSyncRegion
                && [RadarSyncManager hasSyncedRegion]
                && ![RadarSyncManager isOutsideSyncedRegionWithLocation:location]) {
                
                NSArray<RadarBeacon *> *syncedBeacons = [RadarSyncManager getObjCBeaconsFor:location];
                if (syncedBeacons.count > 0) {
                    [self legacy_replaceSyncedBeacons:syncedBeacons];
                    [RadarUtilsDeprecated runOnMainThread:^{
                        [[RadarBeaconManager sharedInstance] rangeBeacons:syncedBeacons
                                                        completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable beacons) {
                            if (status != RadarStatusSuccess || !beacons) {
                                if (forceTrack) {
                                    callTrackAPI(nil);
                                } else {
                                    self.sending = NO;
                                }
                                return;
                            }
                            NSArray<NSString *> *matchedIds = [self legacy_matchBeaconIds:beacons syncedBeacons:syncedBeacons];
                            if (forceTrack) {
                                [RadarSyncManager saveBeaconStateWithBeaconIds:matchedIds];
                                callTrackAPI(beacons);
                            } else {
                                NSSet<NSString *> *rangedIds = [NSSet setWithArray:matchedIds];
                                if ([RadarSyncManager hasBeaconStateChangedWithRangedBeaconIds:rangedIds]) {
                                    [RadarState updateLastSentAt];
                                    [RadarSyncManager saveBeaconStateWithBeaconIds:rangedIds.allObjects];
                                    callTrackAPI(beacons);
                                } else {
                                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"Skipping track: beacon state unchanged after BLE ranging"];
                                    self.sending = NO;
                                }
                            }
                        }];
                    }];
                } else {
                    if (forceTrack) {
                        callTrackAPI(@[]);
                    } else {
                        self.sending = NO;
                    }
                }
            } else {
                [[RadarAPIClient sharedInstance]
                 searchBeaconsNear:location
                 radius:1000
                 limit:10
                 completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons, NSArray<NSString *> *_Nullable beaconUUIDs) {
                    if (beaconUUIDs && beaconUUIDs.count) {
                        [self legacy_replaceSyncedBeaconUUIDs:beaconUUIDs];
                        [RadarUtilsDeprecated runOnMainThread:^{
                            [[RadarBeaconManager sharedInstance] rangeBeaconUUIDs:beaconUUIDs
                                                                completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable beacons) {
                                if (status != RadarStatusSuccess || !beacons) {
                                    callTrackAPI(nil);
                                    return;
                                }
                                
                                callTrackAPI(beacons);
                            }];
                        }];
                    } else if (beacons && beacons.count) {
                        [self legacy_replaceSyncedBeacons:beacons];
                        [RadarUtilsDeprecated runOnMainThread:^{
                            [[RadarBeaconManager sharedInstance] rangeBeacons:beacons
                                                            completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable beacons) {
                                if (status != RadarStatusSuccess || !beacons) {
                                    callTrackAPI(nil);
                                    
                                    return;
                                }
                                
                                callTrackAPI(beacons);
                            }];
                        }];
                    } else {
                        callTrackAPI(@[]);
                    }
                }];
            }
        } else {
            callTrackAPI(nil);
        }
    } else {
        if (options.beacons) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Searching for nearby beacons"];

            if (source != RadarLocationSourceBeaconEnter && source != RadarLocationSourceBeaconExit && source != RadarLocationSourceMockLocation &&
                source != RadarLocationSourceManualLocation) {
                if ([RadarSettings sdkConfiguration].useSyncRegion
                    && [RadarSyncManager hasSyncedRegion]
                    && ![RadarSyncManager isOutsideSyncedRegionWithLocation:location]) {
                    
                    NSArray<RadarBeacon *> *syncedBeacons = [RadarSyncManager getObjCBeaconsFor:location];
                    if (syncedBeacons.count > 0) {
                        [self legacy_replaceSyncedBeacons:syncedBeacons];
                        
                        if (!forceTrack) {
                            [RadarUtilsDeprecated runOnMainThread:^{
                                [[RadarBeaconManager sharedInstance] rangeBeacons:syncedBeacons
                                                                completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable rangedBeacons) {
                                    if (status != RadarStatusSuccess || !rangedBeacons) {
                                        self.sending = NO;
                                        return;
                                    }
                                    NSArray<NSString *> *matchedIds2 = [self legacy_matchBeaconIds:rangedBeacons syncedBeacons:syncedBeacons];
                                    NSSet<NSString *> *rangedIds = [NSSet setWithArray:matchedIds2];
                                    if ([RadarSyncManager hasBeaconStateChangedWithRangedBeaconIds:rangedIds]) {
                                        [RadarState updateLastSentAt];
                                        [RadarSyncManager saveBeaconStateWithBeaconIds:matchedIds2];
                                        [self legacy_performIndoorScanIfConfigured:location
                                                                           beacons:rangedBeacons
                                                                 completionHandler:^(NSArray<RadarBeacon *> *_Nullable beacons, NSString *_Nullable indoorScan) {
                                            [[RadarAPIClient sharedInstance] trackWithLocation:location
                                                                                       stopped:stopped
                                                                                    foreground:[RadarUtilsDeprecated foreground]
                                                                                        source:source
                                                                                      replayed:replayed
                                                                                       beacons:beacons
                                                                                    indoorScan:indoorScan
                                                                             completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                                                                 NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
                                                self.sending = NO;
                                                if ([RadarSettings sdkConfiguration].useSyncRegion) {
                                                    if (status == RadarStatusSuccess && user) {
                                                        [RadarSyncManager reconcileSyncStateWithUser:user];
                                                        
                                                        for (RadarEvent *event in events) {
                                                            if (event.type == RadarEventTypeUserDwelledInGeofence && event.geofence && event.geofence._id) {
                                                                [RadarSyncManager markDwellFired: event.geofence._id];
                                                            }
                                                        }
                                                    } else {
                                                        [RadarSyncManager rollbackSyncState];
                                                    }
                                                }
                                                if (status != RadarStatusSuccess || !config) { return; }
                                                [self legacy_updateTrackingFromMeta:config.meta];
                                                [self legacy_replaceSyncedGeofences:nearbyGeofences];
                                            }];
                                        }];
                                    } else {
                                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"Skipping track: beacon state unchanged after BLE ranging"];
                                        self.sending = NO;
                                    }
                                }];
                            }];
                            return;
                        }
                    }
                } else {
                    [[RadarAPIClient sharedInstance]
                        searchBeaconsNear:location
                                   radius:1000
                                    limit:10
                        completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons, NSArray<NSString *> *_Nullable beaconUUIDs) {
                            if (beaconUUIDs && beaconUUIDs.count) {
                                [self legacy_replaceSyncedBeaconUUIDs:beaconUUIDs];
                            } else if (beacons && beacons.count) {
                                [self legacy_replaceSyncedBeacons:beacons];
                            }
                        }];
                }
            }
        }

        [self legacy_performIndoorScanIfConfigured:location
                                           beacons:beacons
                                 completionHandler:^(NSArray<RadarBeacon *> *_Nullable beacons, NSString *_Nullable indoorScan) {
            [[RadarAPIClient sharedInstance] trackWithLocation:location
                                                       stopped:stopped
                                                    foreground:[RadarUtilsDeprecated foreground]
                                                        source:source
                                                      replayed:replayed
                                                       beacons:beacons
                                                    indoorScan:indoorScan
                                             completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                                 NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
                self.sending = NO;
              
                if ([RadarSettings sdkConfiguration].useSyncRegion) {
                    if (status == RadarStatusSuccess && user) {
                        [RadarSyncManager reconcileSyncStateWithUser:user];
                        
                        for (RadarEvent *event in events) {
                            if (event.type == RadarEventTypeUserDwelledInGeofence && event.geofence && event.geofence._id) {
                                [RadarSyncManager markDwellFired: event.geofence._id];
                            }
                        }
                    } else {
                        [RadarSyncManager rollbackSyncState];
                    }
                }
                
                if (status != RadarStatusSuccess || !config) {
                    return;
                }

                [self legacy_updateTrackingFromMeta:config.meta];
                [self legacy_replaceSyncedGeofences:nearbyGeofences];
            }];
        }];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    RadarSdkConfiguration *sdkConfiguration = [RadarSettings sdkConfiguration];
    BOOL shouldRouteForegroundOneShot =
        self.completionHandlers.count && (sdkConfiguration.skipForegroundCheck || [RadarUtilsDeprecated foreground]);
    id<RadarLocationManagerRouting> implementation = shouldRouteForegroundOneShot
        ? [self implementationForCapability:RadarLocationManagerCapabilityDelegateForegroundLocation]
        : self.legacyImplementation;
    [implementation locationManager:manager didUpdateLocations:locations];
}

- (void)legacy_locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (!locations || !locations.count) {
        return;
    }

    CLLocation *location = [locations lastObject];
    RadarSdkConfiguration *sdkConfiguration = [RadarSettings sdkConfiguration];
    if (self.completionHandlers.count && (sdkConfiguration.skipForegroundCheck || [RadarUtilsDeprecated foreground])) {
        [self legacy_handleLocation:location source:RadarLocationSourceForegroundLocation];
    } else {
        BOOL tracking = [RadarSettings tracking];
        if (!tracking) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ignoring location: not tracking"];

            return;
        }

        [self legacy_handleLocation:location source:RadarLocationSourceBackgroundLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self.legacyImplementation locationManager:manager didEnterRegion:region];
}

- (void)legacy_locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if (![region.identifier hasPrefix:kIdentifierPrefix]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ignoring region entry: wrong prefix"];

        return;
    }

    BOOL tracking = [RadarSettings tracking];
    if (!tracking) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ignoring region entry: not tracking"];

        return;
    }

    CLLocation *location;
    if (manager.location.isValid) {
        location = manager.location;
    } else {
        location = [RadarState lastLocation];
    }

    if ([region.identifier hasPrefix:kSyncBeaconUUIDIdentifierPrefix]) {
        [[RadarBeaconManager sharedInstance] handleBeaconUUIDEntryForRegion:(CLBeaconRegion *)region
                                                          completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                              [self legacy_handleLocation:location source:RadarLocationSourceBeaconEnter beacons:nearbyBeacons];
                                                          }];
    } else if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
        [[RadarBeaconManager sharedInstance] handleBeaconEntryForRegion:(CLBeaconRegion *)region
                                                      completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                          [self legacy_handleLocation:location source:RadarLocationSourceBeaconEnter beacons:nearbyBeacons];
                                                      }];
    } else if (manager.location) {
        [self legacy_handleLocation:manager.location source:RadarLocationSourceGeofenceEnter];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self.legacyImplementation locationManager:manager didExitRegion:region];
}

- (void)legacy_locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if (![region.identifier hasPrefix:kIdentifierPrefix]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ignoring region exit: wrong prefix"];

        return;
    }

    BOOL tracking = [RadarSettings tracking];
    if (!tracking) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ignoring region exit: not tracking"];

        return;
    }

    CLLocation *location;
    if (manager.location.isValid) {
        location = manager.location;
    } else {
        location = [RadarState lastLocation];
    }

    if ([region.identifier hasPrefix:kSyncBeaconUUIDIdentifierPrefix]) {
        [[RadarBeaconManager sharedInstance] handleBeaconUUIDExitForRegion:(CLBeaconRegion *)region
                                                         completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                             [self legacy_handleLocation:location source:RadarLocationSourceBeaconExit beacons:nearbyBeacons];
                                                         }];
    } else if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
        [[RadarBeaconManager sharedInstance] handleBeaconExitForRegion:(CLBeaconRegion *)region
                                                     completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                         [self legacy_handleLocation:location source:RadarLocationSourceBeaconExit beacons:nearbyBeacons];
                                                     }];
    } else if (manager.location) {
        [self legacy_handleLocation:manager.location source:RadarLocationSourceGeofenceExit];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    [[self implementationForCapability:RadarLocationManagerCapabilityBeaconSync] locationManager:manager didDetermineState:state forRegion:region];
}

- (void)legacy_locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (!([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix] || [region.identifier hasPrefix:kSyncBeaconUUIDIdentifierPrefix])) {
        return;
    }

    CLLocation *location;
    if (manager.location.isValid) {
        location = manager.location;
    } else {
        location = [RadarState lastLocation];
    }

    if (state == CLRegionStateInside) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Inside beacon region | identifier = %@", region.identifier]];

        if ([region.identifier hasPrefix:kSyncBeaconUUIDIdentifierPrefix]) {
            [[RadarBeaconManager sharedInstance] handleBeaconUUIDEntryForRegion:(CLBeaconRegion *)region
                                                              completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                                  [self legacy_handleLocation:location source:RadarLocationSourceBeaconEnter beacons:nearbyBeacons];
                                                              }];
        } else if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
            [[RadarBeaconManager sharedInstance] handleBeaconEntryForRegion:(CLBeaconRegion *)region
                                                          completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                              [self legacy_handleLocation:location source:RadarLocationSourceBeaconEnter beacons:nearbyBeacons];
                                                          }];
        }
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Outside beacon region | identifier = %@", region.identifier]];

        if ([region.identifier hasPrefix:kSyncBeaconUUIDIdentifierPrefix]) {
            [[RadarBeaconManager sharedInstance] handleBeaconUUIDExitForRegion:(CLBeaconRegion *)region
                                                             completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                                 [self legacy_handleLocation:location source:RadarLocationSourceBeaconExit beacons:nearbyBeacons];
                                                             }];
        } else if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
            [[RadarBeaconManager sharedInstance] handleBeaconExitForRegion:(CLBeaconRegion *)region
                                                         completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                             [self legacy_handleLocation:location source:RadarLocationSourceBeaconExit beacons:nearbyBeacons];
                                                         }];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    [self.legacyImplementation locationManager:manager didVisit:visit];
}

- (void)legacy_locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    if (!manager.location) {
        return;
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                   message:[NSString stringWithFormat:@"Visit detected | arrival = %@; departure = %@; horizontalAccuracy = %f; visit.coordinate = (%f, %f); manager.location = %@",
                                                                      visit.arrivalDate, visit.departureDate, visit.horizontalAccuracy, visit.coordinate.latitude, visit.coordinate.longitude, manager.location]];

    BOOL tracking = [RadarSettings tracking];
    if (!tracking) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ignoring visit: not tracking"];

        return;
    }

    if ([visit.departureDate isEqualToDate:[NSDate distantFuture]]) {
        [self legacy_handleLocation:manager.location source:RadarLocationSourceVisitArrival];
    } else {
        [self legacy_handleLocation:manager.location source:RadarLocationSourceVisitDeparture];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [[self implementationForCapability:RadarLocationManagerCapabilityDelegateFailure] locationManager:manager didFailWithError:error];
}

- (void)legacy_locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"CLLocation manager error | error = %@", error]];
    [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorLocation];

    [self legacy_callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    [self.legacyImplementation locationManager:manager didUpdateHeading:newHeading];
}

- (void)legacy_locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    [RadarState setLastHeadingData:@{
        @"magneticHeading" : @(newHeading.magneticHeading),
        @"trueHeading" : @(newHeading.trueHeading),
        @"headingAccuracy" : @(newHeading.headingAccuracy),
        @"x" : @(newHeading.x),
        @"y" : @(newHeading.y),
        @"z" : @(newHeading.z),
        @"timestamp" : @([newHeading.timestamp timeIntervalSince1970]),
    }];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self.legacyImplementation locationManager:manager didChangeAuthorizationStatus:status];
}

- (void)legacy_locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    CLAuthorizationStatus previousStatus = [RadarState locationAuthorizationStatus];
    [RadarState setLocationAuthorizationStatus:status];

    if (status == previousStatus) {
        return;
    }

    if ((status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) && ([RadarSettings sdkConfiguration].trackOnceOnAppOpen || [RadarSettings sdkConfiguration].startTrackingOnInitialize)) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"Location services authorized"];
        [Radar trackOnceWithCompletionHandler:nil];
        if ([RadarSettings sdkConfiguration].startTrackingOnInitialize && ![RadarSettings tracking]) {
            [Radar startTrackingWithOptions:[RadarSettings trackingOptions]];
        }
    }
}


@end
