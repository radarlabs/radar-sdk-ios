//
//  RadarLocationManager.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

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
#import "RadarActivityManager.h"
#import "RadarNotificationHelper.h"
#import "RadarIndoorsProtocol.h"

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

@property (nonatomic) BOOL firstPermissionCheck;

@end

@implementation RadarLocationManager

static NSString *const kIdentifierPrefix = @"radar_";
static NSString *const kBubbleGeofenceIdentifierPrefix = @"radar_bubble_";
static NSString *const kSyncGeofenceIdentifierPrefix = @"radar_geofence_";
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

        _firstPermissionCheck = YES;

        _firstPermissionCheck = NO;
    }
    return self;
}

- (void)callCompletionHandlersWithStatus:(RadarStatus)status location:(CLLocation *_Nullable)location {
    @synchronized(self) {
        if (!self.completionHandlers.count){
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

    [self updateTracking];
}

- (void)startUpdates:(int)interval blueBar:(BOOL)blueBar {
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

- (void)stopUpdates {
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

        [self performSelector:@selector(shutDown) withObject:nil afterDelay:delay];
    }
}

- (void)shutDown {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Shutting down"];

    [self.locationManager stopUpdatingLocation];
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

- (void)updateTracking:(CLLocation *)location fromInitialize:(BOOL)fromInitialize {
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
                        
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Activity detected, initiating trackOnce"];
                        [Radar trackOnceWithCompletionHandler: nil];
                        
                    }
                }];
                
            }
            if (options.usePressure) {
                self.activityManager = [RadarActivityManager sharedInstance];
                
                [self.activityManager startRelativeAltitudeWithHandler: ^(CMAltitudeData * _Nullable altitudeData) {
                    NSMutableDictionary *currentState = [[RadarState lastRelativeAltitudeData] mutableCopy] ?: [NSMutableDictionary new];
                    currentState[@"pressure"] = @(altitudeData.pressure.doubleValue *10); // convert to hPa
                    currentState[@"relativeAltitude"] = @(altitudeData.relativeAltitude.doubleValue);
                    currentState[@"relativeAltitudeTimestamp"] = @([[NSDate date] timeIntervalSince1970]);
                    [RadarState setLastRelativeAltitudeData:currentState];
                }];

                if (@available(iOS 15.0, *)) {
                    [self.activityManager startAbsoluteAltitudeWithHandler: ^(CMAbsoluteAltitudeData * _Nullable altitudeData) {
                        NSMutableDictionary *currentState = [[RadarState lastRelativeAltitudeData] mutableCopy] ?: [NSMutableDictionary new];
                        currentState[@"altitude"] = @(altitudeData.altitude);
                        currentState[@"accuracy"] = @(altitudeData.accuracy);
                        currentState[@"precision"] = @(altitudeData.precision);
                        currentState[@"absoluteAltitudeTimestamp"] = @([[NSDate date] timeIntervalSince1970]);
                        [RadarState setLastRelativeAltitudeData:currentState];
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
                    [self stopUpdates];
                } else if (startUpdates) {
                    [self startUpdates:options.desiredStoppedUpdateInterval blueBar:options.showBlueBar];
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
                    [self startUpdates:options.desiredMovingUpdateInterval blueBar:options.showBlueBar];
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
            } else {
                [self.locationManager stopMonitoringVisits];
            }
            if (options.useSignificantLocationChanges) {
                [self.locationManager startMonitoringSignificantLocationChanges];
            } else {
                [self.locationManager stopMonitoringSignificantLocationChanges];
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

+ (BOOL)region:(CLRegion*) a isEqual:(CLRegion*) b {
    if (a == nil && b == nil) {
        return YES;
    }
    if (a == nil || b == nil) {
        return NO;
    }
    if (![a.identifier isEqual:b.identifier]) {
        return NO;
    }
    // make sure both geofences are circular, other types we don't compare and default to assume not equal
    if (![a isKindOfClass:[CLCircularRegion class]]) {
        return NO;
    }
    if (![b isKindOfClass:[CLCircularRegion class]]) {
        return NO;
    }
    CLCircularRegion* circleA = (CLCircularRegion*) a;
    CLCircularRegion* circleB = (CLCircularRegion*) b;
    if (circleA.center.latitude != circleB.center.latitude ||
        circleA.center.longitude != circleB.center.longitude ||
        circleA.radius != circleB.radius) {
        return NO;
    }
    return YES;
}

- (CLCircularRegion*)circularRegionFromGeofence:(RadarGeofence*) geofence {
    if (geofence == nil) {
        return nil;
    }
    NSString *identifier = [NSString stringWithFormat:@"%@%@", kSyncGeofenceIdentifierPrefix, geofence._id];
    if ([geofence.geometry isKindOfClass:[RadarCircleGeometry class]]) {
        RadarCircleGeometry *geometry = (RadarCircleGeometry *)geofence.geometry;
        return [[CLCircularRegion alloc] initWithCenter:geometry.center.coordinate
                                                 radius:geometry.radius
                                             identifier:identifier];
    } else if ([geofence.geometry isKindOfClass:[RadarPolygonGeometry class]]) {
        RadarPolygonGeometry *geometry = (RadarPolygonGeometry *)geofence.geometry;
        
        return [[CLCircularRegion alloc] initWithCenter:geometry.center.coordinate
                                                 radius:geometry.radius
                                             identifier:identifier];
    } else { // Radar geofence has no geometry
        return nil;
    }
}


- (void)replaceSyncedGeofences:(NSArray<RadarGeofence *> *)geofences {
    if (!geofences) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Skipping replacing synced geofences"];
        
        return;
    }
    
    NSMutableDictionary<NSString*, CLCircularRegion*>* geofenceRegionsByIdentifier = [[NSMutableDictionary alloc] init];
    NSMutableDictionary<NSString*, UNNotificationRequest*>* notificationsByIdentifier = [[NSMutableDictionary alloc] init];
    
    RadarTrackingOptions *options = [Radar getTrackingOptions];
    NSUInteger maxClientGeofence = MIN(geofences.count, options.beacons ? 9 : 19);
    
    if (maxClientGeofence < geofences.count) {
        NSString* message = [NSString stringWithFormat:@"Syncing %lu/%lu nearby geofences",
                         (unsigned long)maxClientGeofence, (unsigned long)geofences.count];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:message];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Syncing %lu nearby geofences", geofences.count]];
    }
    
    
    for (int i = 0; i < maxClientGeofence; ++i) {
        RadarGeofence* geofence = geofences[i];
        NSString *identifier = [NSString stringWithFormat:@"%@%@", kSyncGeofenceIdentifierPrefix, geofence._id];
        
        // new geofences
        CLCircularRegion* region = [self circularRegionFromGeofence:geofence];
        [geofenceRegionsByIdentifier setObject:[region copy] forKey:identifier];
        
        // new notifications
        if (geofence.metadata != nil) {
            UNMutableNotificationContent *content = [RadarNotificationHelper extractContentFromMetadata:geofence.metadata identifier:identifier];
            if (content) {
//                
//                CLCircularRegion* region = [self circularRegionFromGeofence:geofence];
//                [geofenceRegionsByIdentifier setObject:[region copy] forKey:identifier];
                
                region.notifyOnEntry = YES;
                region.notifyOnExit = NO;
                NSString *notificationRepeats = [geofence.metadata objectForKey:@"radar:notificationRepeats"];
                BOOL repeats = notificationRepeats != nil && [notificationRepeats boolValue];
                
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                   message:[NSString stringWithFormat:@"Notification for campaign %@ %@", geofence.metadata[@"radar:campaignId"],
                                                            (geofence.metadata[@"radar:notificationRepeats"] ? @"repeat" : @"does not repeat")]];

                UNLocationNotificationTrigger *trigger = [UNLocationNotificationTrigger triggerWithRegion:region repeats:repeats];
                
                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                [notificationsByIdentifier setObject:request forKey:identifier];
            }
        }
    }
    // For debug logging
    NSInteger numSyncedGeofences = geofenceRegionsByIdentifier.count;
    NSInteger numKeptGeofences = 0;
    NSInteger numRemovedGeofences = 0;
    // Replace synced geofence
    // Removing geofences that are no longer in the nearby list
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kSyncGeofenceIdentifierPrefix]) {
            CLCircularRegion* geofenceRegion = geofenceRegionsByIdentifier[region.identifier];
            if ([RadarLocationManager region:geofenceRegion isEqual:region]) {
                // same region is still in nearbyGeofences, we keep the region
                [geofenceRegionsByIdentifier removeObjectForKey:region.identifier];
                numKeptGeofences += 1;
            } else {
                // the geofence changed, or no longer monitored, remove the existing monitored region
                [self.locationManager stopMonitoringForRegion:region];
                numRemovedGeofences += 1;
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                message:[NSString stringWithFormat:@"removed region %@", region]];
            }
        }
    }
    
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                    message:[NSString stringWithFormat:@"Synced %lu geofences: removed %lu, kept %lu, added %lu",
                                             numSyncedGeofences, numRemovedGeofences, numKeptGeofences,  geofenceRegionsByIdentifier.count]];
    // Adding new geofences from nearby list that wasn't tracked before
    for (CLCircularRegion* region in geofenceRegionsByIdentifier.allValues) {
        [self.locationManager startMonitoringForRegion:region];
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                        message:[NSString stringWithFormat:@"Synced geofence | latitude = %f; longitude = %f; radius = %f; identifier = %@",
                                                                            region.center.latitude, region.center.longitude, region.radius, region.identifier]];
    }
    
    [RadarNotificationHelper updateClientSideCampaignsWithPrefix:kSyncGeofenceIdentifierPrefix notificationRequests:notificationsByIdentifier];
}

- (void)removeSyncedGeofences {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region.identifier hasPrefix:kSyncGeofenceIdentifierPrefix]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Removed synced geofences"];
}

- (void)replaceSyncedBeacons:(NSArray<RadarBeacon *> *)beacons {
    if ([RadarSettings useRadarModifiedBeacon]) {
        return;
    }
    
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
    if ([RadarSettings useRadarModifiedBeacon]) {
        return;
    }
    
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
    [RadarState updateLastSentAt];

    if (source == RadarLocationSourceForegroundLocation) {
        return;
    }

    [self sendLocation:sendLocation stopped:stopped source:source replayed:replayed beacons:beacons];
}

- (void)performIndoorScanIfConfigured:(CLLocation *)location 
                               beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                     completionHandler:(void (^)(NSArray<RadarBeacon *> *_Nullable, NSString *_Nullable))completionHandler {
    RadarTrackingOptions *options = [Radar getTrackingOptions];
    Class RadarSDKIndoors = NSClassFromString(@"RadarSDKIndoors");
    
    if (options.useIndoorScan && ![RadarSettings isInSurveyMode] && RadarSDKIndoors && [RadarUtils foreground]) {
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
        if (options.useIndoorScan && ![RadarSettings isInSurveyMode] && !RadarSDKIndoors) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"RadarSDKIndoors not available, skipping indoor scan"];
        } else if (options.useIndoorScan && ![RadarSettings isInSurveyMode] && RadarSDKIndoors && ![RadarUtils foreground]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"App in background, skipping indoor scan (Bluetooth not available)"];
        }
        completionHandler(beacons, nil);
    }
}

- (void)sendLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source replayed:(BOOL)replayed beacons:(NSArray<RadarBeacon *> *_Nullable)beacons {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                       message:[NSString stringWithFormat:@"Sending location | source = %@; location = %@; stopped = %d; replayed = %d; beacons = %@",
                                                                          [Radar stringForLocationSource:source], location, stopped, replayed, beacons]];

    self.sending = YES;

    RadarTrackingOptions *options = [Radar getTrackingOptions];
    
    if ([RadarSettings useRadarModifiedBeacon]) {
        void (^callTrackAPI)(NSArray<RadarBeacon *> *_Nullable) = ^(NSArray<RadarBeacon *> *_Nullable beacons) {
            [self performIndoorScanIfConfigured:location 
                                        beacons:beacons 
                              completionHandler:^(NSArray<RadarBeacon *> *_Nullable beacons, NSString *_Nullable indoorScan) {
                [[RadarAPIClient sharedInstance] trackWithLocation:location
                                                           stopped:stopped
                                                        foreground:[RadarUtils foreground]
                                                            source:source
                                                          replayed:replayed
                                                           beacons:beacons
                                                      indoorScan:indoorScan
                                                 completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                                     NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
                    self.sending = NO;
                    
                    [self updateTrackingFromMeta:config.meta];
                    [self replaceSyncedGeofences:nearbyGeofences];
                }];
            }];
        };
        
        if (options.beacons &&
            source != RadarLocationSourceBeaconEnter &&
            source != RadarLocationSourceBeaconExit &&
            source != RadarLocationSourceMockLocation &&
            source != RadarLocationSourceManualLocation) {
            
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Searching for nearby beacons"];
            
            [[RadarAPIClient sharedInstance]
             searchBeaconsNear:location
             radius:1000
             limit:10
             completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons, NSArray<NSString *> *_Nullable beaconUUIDs) {
                if (beaconUUIDs && beaconUUIDs.count) {
                    [self replaceSyncedBeaconUUIDs:beaconUUIDs];
                    [RadarUtils runOnMainThread:^{
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
                    [self replaceSyncedBeacons:beacons];
                    [RadarUtils runOnMainThread:^{
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
        } else {
            callTrackAPI(nil);
        }
    } else {
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

        [self performIndoorScanIfConfigured:location 
                                    beacons:beacons 
                          completionHandler:^(NSArray<RadarBeacon *> *_Nullable beacons, NSString *_Nullable indoorScan) {
            [[RadarAPIClient sharedInstance] trackWithLocation:location
                                                       stopped:stopped
                                                    foreground:[RadarUtils foreground]
                                                        source:source
                                                      replayed:replayed
                                                       beacons:beacons
                                                  indoorScan:indoorScan
                                             completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                                 NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
                                                 self.sending = NO;
                                                 if (status != RadarStatusSuccess || !config) {
                                                     return;
                                                 }

                                                 [self updateTrackingFromMeta:config.meta];
                                                 [self replaceSyncedGeofences:nearbyGeofences];
                                             }];
        }];
    }
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

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                   message:[NSString stringWithFormat:@"Visit detected | arrival = %@; departure = %@; horizontalAccuracy = %f; visit.coordinate = (%f, %f); manager.location = %@",
                                                                      visit.arrivalDate, visit.departureDate, visit.horizontalAccuracy, visit.coordinate.latitude, visit.coordinate.longitude, manager.location]];

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
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"CLLocation manager error | error = %@", error]];
    [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorLocation];

    [self callCompletionHandlersWithStatus:RadarStatusErrorLocation location:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
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
    if (self.firstPermissionCheck) {
        self.firstPermissionCheck = NO;
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
