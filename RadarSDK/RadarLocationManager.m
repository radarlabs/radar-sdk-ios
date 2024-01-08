//
//  RadarLocationManager.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

#import "CLLocation+Radar.h"
#import "RadarAPIClient.h"
#import "RadarBeaconManager.h"
#import "RadarCircleGeometry.h"
#import "RadarDelegateHolder.h"
#import "RadarLocationManager.h"
#import "RadarLogger.h"
#import "RadarMeta.h"
#import "RadarPolygonGeometry.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarUtils.h"
#import "RadarReplayBuffer.h"
#import "RadarTrackingOptions.h"
#import "RadarTripOptions.h"


@interface StateChange : NSObject
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, assign) BOOL rampedUp;
@end

@implementation StateChange
@end


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

/**
 State changes for ramping up and down.
 */
@property (nonnull, strong, nonatomic) NSMutableArray<StateChange *> *stateChanges;

@end


@implementation RadarLocationManager

static NSString *const kIdentifierPrefix = @"radar_";
static NSString *const kBubbleGeofenceIdentifierPrefix = @"radar_bubble_";
static NSString *const kSyncGeofenceIdentifierPrefix = @"radar_geofence_";
static NSString *const kRampUpGeofenceIdentifierPrefix = @"radar_ramp_up_";
static NSString *const kSyncBeaconIdentifierPrefix = @"radar_beacon_";
static NSString *const kSyncBeaconUUIDIdentifierPrefix = @"radar_uuid_";

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

        // If not testing, set _notificationCenter to the currentNotificationCenter
        if (![[NSProcessInfo processInfo] environment][@"XCTestConfigurationFilePath"]) {
            _notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
        }
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
        RadarLocationCompletionHandler completionHandlerCopy = [completionHandler copy];
        [self.completionHandlers addObject:completionHandlerCopy];

        [self performSelector:@selector(timeoutWithCompletionHandler:) withObject:completionHandlerCopy afterDelay:20];
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
    RadarFeatureSettings *featureSettings = [RadarSettings featureSettings];
    if (featureSettings.extendFlushReplays) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"flushReplays() from stopTracking"];
        [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
    }

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
    [self updateTracking:nil fromInitialize:NO ramping:RampingOptionNoChange];
}

- (void)updateTrackingFromInitialize {
    [self updateTracking:nil fromInitialize:YES ramping:RampingOptionNoChange];
}

- (void)updateTracking:(CLLocation *)location {
    [self updateTracking:location fromInitialize:NO ramping:RampingOptionNoChange];
}

- (void)updateTracking:(CLLocation *)location fromInitialize:(BOOL)fromInitialize ramping:(RampingOption)ramping {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL tracking = [RadarSettings tracking];
        RadarTrackingOptions *options = [Radar getTrackingOptions];

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
            if (ramping == RampingOptionRampUp && ![RadarSettings rampedUp]) {
                // if not on trip, set prev options to current tracking options
                // and regardless, set current tracking options to ramp up options
                if (![RadarSettings tripOptions]) {
                    [RadarSettings setPreviousTrackingOptions:[Radar getTrackingOptions]];
                }
                // save the ramp up radius to a local int
                int rampUpRadius = options.rampUpRadius;
                options = RadarTrackingOptions.rampedUpOptions;

                options.rampUpRadius = rampUpRadius;

                [RadarSettings setTrackingOptions:options];
                // log the ramp up options
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Ramped up with options: %@", [options dictionaryValue]]];
                [RadarSettings setRampedUp:YES];

                [self changeTrackingState:YES];

                
            } else if (ramping == RampingOptionRampDown && [RadarSettings rampedUp]) {
                // if not on trip, set prev options to current tracking options
                // and regardless, set current tracking options to ramp up options
                if ([RadarSettings tripOptions]) {
                    // set to the continuous preset
                    options = RadarTrackingOptions.presetContinuous;
                } else {
                    options = [RadarSettings previousTrackingOptions];
                    [RadarSettings removePreviousTrackingOptions];

                }
                [RadarSettings setTrackingOptions:options];
                [RadarSettings setRampedUp:NO];

                [self changeTrackingState:NO];
            }

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
    if (meta) {
        if ([meta trackingOptions]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Setting remote tracking options | trackingOptions = %@", meta.trackingOptions]];
            [RadarSettings setRemoteTrackingOptions:[meta trackingOptions]];
        } else {
            [RadarSettings removeRemoteTrackingOptions];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"Removed remote tracking options | trackingOptions = %@", Radar.getTrackingOptions]];
        }
    }
    [self updateTrackingFromInitialize];

}


// Call this method when the tracking state changes
- (void)changeTrackingState:(BOOL)rampedUp {
    StateChange *change = [[StateChange alloc] init];
    change.timestamp = [NSDate date]; // Current timestamp
    change.rampedUp = rampedUp;
    [self.stateChanges addObject:change];
}

- (NSDictionary *)calculateRampedUpTimesAndCleanup {
    NSDate *now = [NSDate date];
    NSDate *oneHourAgo = [now dateByAddingTimeInterval:-3600]; // 1 hour ago
    NSDate *twelveHoursAgo = [now dateByAddingTimeInterval:-43200]; // 12 hours ago
    
    NSTimeInterval totalRampedUpTimeOneHour = 0;
    NSTimeInterval totalRampedUpTimeTwelveHours = 0;
    NSDate *lastRampedUpStartOneHour = nil;
    NSDate *lastRampedUpStartTwelveHours = nil;
    NSMutableArray *validChanges = [NSMutableArray array]; // Array to store valid entries

    for (StateChange *change in self.stateChanges) {
        if ([change.timestamp compare:twelveHoursAgo] == NSOrderedAscending) {
            continue; // Skip and effectively remove changes older than twelve hours
        }

        // Adding valid entries to the new array
        [validChanges addObject:change];

        // Calculation for the past 12 hours
        if (change.rampedUp) {
            lastRampedUpStartTwelveHours = change.timestamp;
        } else if (lastRampedUpStartTwelveHours) {
            totalRampedUpTimeTwelveHours += [change.timestamp timeIntervalSinceDate:lastRampedUpStartTwelveHours];
            lastRampedUpStartTwelveHours = nil;
        }

        // Additional check for the past hour
        if ([change.timestamp compare:oneHourAgo] != NSOrderedAscending) {
            if (change.rampedUp) {
                lastRampedUpStartOneHour = change.timestamp;
            } else if (lastRampedUpStartOneHour) {
                totalRampedUpTimeOneHour += [change.timestamp timeIntervalSinceDate:lastRampedUpStartOneHour];
                lastRampedUpStartOneHour = nil;
            }
        }
    }

    // Final adjustments if the last state was ramped up and hasn't changed since
    if (lastRampedUpStartTwelveHours) {
        totalRampedUpTimeTwelveHours += [now timeIntervalSinceDate:lastRampedUpStartTwelveHours];
    }
    if (lastRampedUpStartOneHour) {
        totalRampedUpTimeOneHour += [now timeIntervalSinceDate:lastRampedUpStartOneHour];
    }

    // Update the stateChanges array with the valid changes
    self.stateChanges = validChanges;

    return @{@"OneHour": @(totalRampedUpTimeOneHour), @"TwelveHours": @(totalRampedUpTimeTwelveHours)};
}


- (void)restartPreviousTrackingOptions {
    RadarTrackingOptions *previousTrackingOptions = [RadarSettings previousTrackingOptions];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Restarting previous tracking options"];

    if (previousTrackingOptions) {
        [Radar startTrackingWithOptions:previousTrackingOptions];
    } else {
        [Radar stopTracking];
    }

    [RadarSettings removePreviousTrackingOptions];
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
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Successfully added bubble geofence | latitude = %f; longitude = %f; radius = %d; identifier = %@",
                                                                          location.coordinate.latitude, location.coordinate.longitude, radius, identifier]];
}

- (void)removeBubbleGeofence {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kBubbleGeofenceIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Removed bubble geofences"];
}

- (void)replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences {
    [self removeSyncedGeofences];

    if (!geofences) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Skipping replacing synced geofences"];

        return;
    }

    NSUInteger numGeofences = MIN(geofences.count, 9);
    NSMutableArray *requests = [NSMutableArray array]; 

    // bool for whether or not we're within the ramp up radius of a geofence
    BOOL withinRampUpRadius = NO;
    RadarTrackingOptions *trackingOptions = [Radar getTrackingOptions];


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
            double rampUpRadius = 0;

            // the most general way of specifying a ramp up radius is in the tracking options 
            if (trackingOptions.rampUpRadius && trackingOptions.rampUpRadius > 0) {
                rampUpRadius = trackingOptions.rampUpRadius;

            }

            // the next way of specifying a ramp up radius is in the geofence metadata 
            NSDictionary *metadata = geofence.metadata;
            if (metadata) {
                // if metadata has notification has radar:rampUpRadius, set radius to rampUpRadius
                NSString *rampUpRadiusString = [geofence.metadata objectForKey:@"radar:rampUpRadius"];
                if (rampUpRadiusString && [rampUpRadiusString doubleValue] > 0) {
                    rampUpRadius = [rampUpRadiusString doubleValue];
                }
            }

            // the most specific way of specifying a ramp up radius is in the trip options
            RadarTripOptions *tripOptions = [RadarSettings tripOptions];
            // log the trip options dictionary
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"trip options dictionary: %@", [tripOptions dictionaryValue]]];
            if (tripOptions && tripOptions.destinationGeofenceTag == geofence.tag && tripOptions.destinationGeofenceExternalId == geofence.externalId && tripOptions.rampUpRadius && tripOptions.rampUpRadius > 0) {
                // log that we're setting rampUpRadius to tripOptions.rampUpRadius
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"trip options rampUpRadius: %d", tripOptions.rampUpRadius]];
                rampUpRadius = tripOptions.rampUpRadius;
            }


            if (rampUpRadius > 0) {
                CLLocation *geofenceCenterLocation = [[CLLocation alloc] initWithLatitude:center.coordinate.latitude longitude:center.coordinate.longitude];
                CLLocationDistance distance = [geofenceCenterLocation distanceFromLocation:self.locationManager.location];
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"distance from geofence center to current location: %f", distance]];

                if (distance <= rampUpRadius) { 
                    // Log that we're setting withinRampUpRadius YES
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"distance from geofence center to current location is less than rampUpRadius, setting withinRampUpRadius to YES"]];
                    withinRampUpRadius = YES;
                } else {
                    radius = rampUpRadius;
                    identifier = [NSString stringWithFormat:@"%@%@", kRampUpGeofenceIdentifierPrefix, geofenceId];
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"radius is rampUpRadius: %f", radius]];
                }
            }

            CLRegion *region = [[CLCircularRegion alloc] initWithCenter:center.coordinate radius:radius identifier:identifier];
            [self.locationManager startMonitoringForRegion:region];

            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                            message:[NSString stringWithFormat:@"Synced geofence | latitude = %f; longitude = %f; radius = %f; identifier = %@",
                                                                                center.coordinate.latitude, center.coordinate.longitude, radius, identifier]];

          
            if (metadata) {
                // if metadata has notification has radar:rampUp radius
                NSString *notificationText = [geofence.metadata objectForKey:@"radar:notificationText"];
                NSString *notificationTitle = [geofence.metadata objectForKey:@"radar:notificationTitle"];
                NSString *notificationSubtitle = [geofence.metadata objectForKey:@"radar:notificationSubtitle"];
                if (notificationText) {
                    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                    if (notificationTitle) {
                        content.title = [NSString localizedUserNotificationStringForKey:notificationTitle arguments:nil];
                    }
                    if (notificationSubtitle) {
                        content.subtitle = [NSString localizedUserNotificationStringForKey:notificationSubtitle arguments:nil];
                    }
                    content.body = [NSString localizedUserNotificationStringForKey:notificationText arguments:nil];
                    content.userInfo = geofence.metadata;

                    region.notifyOnEntry = YES;
                    region.notifyOnExit = NO;
                    BOOL repeats = NO;
                    NSString *notificationRepeats = [geofence.metadata objectForKey:@"radar:notificationRepeats"];
                    if (notificationRepeats) {
                        repeats = [notificationRepeats boolValue];
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"repeats is bool vaue: %d", repeats]];
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

    // call calculateRampedUpTimesAndCleanup to get the total ramped up time in the past hour and 12 hours
    NSDictionary *rampedUpTimes = [self calculateRampedUpTimesAndCleanup];
    NSTimeInterval totalRampedUpTimeOneHour = [[rampedUpTimes objectForKey:@"OneHour"] doubleValue];
    NSTimeInterval totalRampedUpTimeTwelveHours = [[rampedUpTimes objectForKey:@"TwelveHours"] doubleValue];

    // bool for whether or not we've exceeded the ramp up time limit (20 minutes for 1 hour or 120 mintues for 12 hours)
    BOOL exceededRampUpTimeLimit = NO;
    if (totalRampedUpTimeOneHour > 12000 || totalRampedUpTimeTwelveHours > 72000) {
        exceededRampUpTimeLimit = YES;
    }

    if (withinRampUpRadius && ![RadarSettings rampedUp] && !exceededRampUpTimeLimit) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Ramping up"]];
        [self updateTracking:self.locationManager.location fromInitialize:NO ramping:RampingOptionRampUp];  
    } else if (withinRampUpRadius && ![RadarSettings rampedUp] && exceededRampUpTimeLimit) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Exceeded ramp up time limit, not ramping up"]];
    } else if (withinRampUpRadius && [RadarSettings rampedUp] && !exceededRampUpTimeLimit) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Already ramped up"]];
    } else if (withinRampUpRadius && [RadarSettings rampedUp] && exceededRampUpTimeLimit) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Exceeded ramp up time limit, ramping down"]];
        [self updateTracking:self.locationManager.location fromInitialize:NO ramping:RampingOptionRampDown];
    } else if (!withinRampUpRadius && [RadarSettings rampedUp]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Ramping down"]];
        [self updateTracking:self.locationManager.location fromInitialize:NO ramping:RampingOptionRampDown];
    } else if (!withinRampUpRadius && ![RadarSettings rampedUp]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Already ramped down"]];
    }

    [self removePendingNotificationsWithCompletionHandler: ^{
        for (UNNotificationRequest *request in requests) {
            [self.notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
                if (error) {
                    [[RadarLogger sharedInstance]
                        logWithLevel:RadarLogLevelDebug
                            message:[NSString stringWithFormat:@"Error adding local notification | identifier = %@; error = %@", request.identifier, error]];
                } else {
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                        message:[NSString stringWithFormat:@"Added local notification | identifier = %@", request.identifier]];
                }
            }];
        }
    }];
}

- (void)removeSyncedGeofences {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kSyncGeofenceIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Removed synced geofences"];
}

- (void)removePendingNotificationsWithCompletionHandler:(void (^)(void))completionHandler {
    [self.notificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *_Nonnull requests) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Found %lu pending notifications", (unsigned long)requests.count]];
        NSMutableArray *identifiers = [NSMutableArray new];
        for (UNNotificationRequest *request in requests) {
            if ([request.identifier hasPrefix:kSyncGeofenceIdentifierPrefix]) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Found pending notification | identifier = %@", request.identifier]];
                [identifiers addObject:request.identifier];
            }
        }

        if (identifiers.count > 0) {
            [self.notificationCenter removePendingNotificationRequestsWithIdentifiers:identifiers];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Removed pending notifications"];
        }

        completionHandler();
    }];
}

- (void)replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons {
    [self removeSyncedBeacons];

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
    [self removeSyncedBeacons];

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

- (void)removeSyncedBeacons {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kSyncBeaconUUIDIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        } else if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
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
    [self handleLocation:location source:source beacons:nil];
}

- (void)handleLocation:(CLLocation *)location source:(RadarLocationSource)source beacons:(NSArray<RadarBeacon *> *)beacons {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Handling location | source = %@; location = %@", [Radar stringForLocationSource:source], location]];

    [self cancelTimeouts];

    if (!location.isValid) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Invalid location | source = %@; location = %@", [Radar stringForLocationSource:source], location]];

        [self callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];

        return;
    }

    RadarTrackingOptions *options = [Radar getTrackingOptions];
    BOOL wasStopped = [RadarState stopped];
    BOOL stopped = NO;

    BOOL force = (source == RadarLocationSourceForegroundLocation || source == RadarLocationSourceManualLocation || source == RadarLocationSourceBeaconEnter ||
                  source == RadarLocationSourceBeaconExit || source == RadarLocationSourceVisitArrival);
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

    [self sendLocation:sendLocation stopped:stopped source:source replayed:replayed beacons:beacons];
}

- (void)sendLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source replayed:(BOOL)replayed beacons:(NSArray<RadarBeacon *> *_Nullable)beacons {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Sending location | source = %@; location = %@; stopped = %d; replayed = %d; beacons = %@",
                                                                          [Radar stringForLocationSource:source], location, stopped, replayed, beacons]];

    self.sending = YES;

    RadarTrackingOptions *options = [Radar getTrackingOptions];
    if (options.beacons) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Searching for nearby beacons"];

        if (source != RadarLocationSourceBeaconEnter && source != RadarLocationSourceBeaconExit && source != RadarLocationSourceMockLocation &&
            source != RadarLocationSourceManualLocation) {
            [[RadarAPIClient sharedInstance]
                searchBeaconsNear:location
                           radius:1000
                            limit:10
                completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons, NSArray<NSString *> *_Nullable beaconUUIDs) {
                    if (beaconUUIDs && beaconUUIDs.count) {
                        [self replaceSyncedBeaconUUIDs:beaconUUIDs];
                    } else if (beacons && beacons.count) {
                        [self replaceSyncedBeacons:beacons];
                    }
                }];
        }
    }

    [[RadarAPIClient sharedInstance] trackWithLocation:location
                                               stopped:stopped
                                            foreground:[RadarUtils foreground]
                                                source:source
                                              replayed:replayed
                                               beacons:beacons
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                         NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, NSString *_Nullable token) {
                                         self.sending = NO;

                                         [self updateTrackingFromMeta:config.meta];
                                         [RadarSettings setFeatureSettings:config.meta.featureSettings];
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
        BOOL tracking = [RadarSettings tracking];
        if (!tracking) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ignoring location: not tracking"];

            return;
        }

        [self handleLocation:location source:RadarLocationSourceBackgroundLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if (![region.identifier hasPrefix:kIdentifierPrefix]) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ignoring region entry: wrong prefix"];

        return;
    }

    if ([region.identifier hasPrefix:kRampUpGeofenceIdentifierPrefix]) {

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
                                                              [self handleLocation:location source:RadarLocationSourceBeaconEnter beacons:nearbyBeacons];
                                                          }];
    } else if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
        [[RadarBeaconManager sharedInstance] handleBeaconEntryForRegion:(CLBeaconRegion *)region
                                                      completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                          [self handleLocation:location source:RadarLocationSourceBeaconEnter beacons:nearbyBeacons];
                                                      }];
    } else if ([region.identifier hasPrefix:kRampUpGeofenceIdentifierPrefix] && manager.location) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Entered ramp up geofence"];

        [self handleLocation:manager.location source:RadarLocationSourceGeofenceEnter];
    } else if (manager.location) {
        [self handleLocation:manager.location source:RadarLocationSourceGeofenceEnter];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
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
                                                             [self handleLocation:location source:RadarLocationSourceBeaconExit beacons:nearbyBeacons];
                                                         }];
    } else if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
        [[RadarBeaconManager sharedInstance] handleBeaconExitForRegion:(CLBeaconRegion *)region
                                                     completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                         [self handleLocation:location source:RadarLocationSourceBeaconExit beacons:nearbyBeacons];
                                                     }];
    } else if (manager.location) {
        [self handleLocation:manager.location source:RadarLocationSourceGeofenceExit];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
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
                                                                  [self handleLocation:location source:RadarLocationSourceBeaconEnter beacons:nearbyBeacons];
                                                              }];
        } else if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
            [[RadarBeaconManager sharedInstance] handleBeaconEntryForRegion:(CLBeaconRegion *)region
                                                          completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                              [self handleLocation:location source:RadarLocationSourceBeaconEnter beacons:nearbyBeacons];
                                                          }];
        }
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Outside beacon region | identifier = %@", region.identifier]];

        if ([region.identifier hasPrefix:kSyncBeaconUUIDIdentifierPrefix]) {
            [[RadarBeaconManager sharedInstance] handleBeaconUUIDExitForRegion:(CLBeaconRegion *)region
                                                             completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                                 [self handleLocation:location source:RadarLocationSourceBeaconExit beacons:nearbyBeacons];
                                                             }];
        } else if ([region.identifier hasPrefix:kSyncBeaconIdentifierPrefix]) {
            [[RadarBeaconManager sharedInstance] handleBeaconExitForRegion:(CLBeaconRegion *)region
                                                         completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable nearbyBeacons) {
                                                             [self handleLocation:location source:RadarLocationSourceBeaconExit beacons:nearbyBeacons];
                                                         }];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    if (!manager.location) {
        return;
    }

    BOOL tracking = [RadarSettings tracking];
    if (!tracking) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Ignoring visit: not tracking"];

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
