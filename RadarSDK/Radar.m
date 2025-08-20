//
//  Radar.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"
#include "RadarSdkConfiguration.h"

#import "RadarAPIClient.h"
#import "RadarBeaconManager.h"
#import "RadarConfig.h"
#import "RadarCoordinate+Internal.h"
#import "RadarDelegateHolder.h"
#import "RadarLocationManager.h"
#import "RadarLogBuffer.h"
#import "RadarLogger.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarUtils.h"
#import "RadarVerificationManager.h"
#import "RadarReplayBuffer.h"
#import "RadarNotificationHelper.h"
#import "RadarTripOptions.h"
#import "RadarInAppMessageDelegate.h"
#import "Radar-Swift.h"

@interface Radar ()

@property (nullable, weak, nonatomic) id<RadarDelegate> delegate;

@end

@implementation Radar

#pragma mark - Initialization

+ (id)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

+ (void)nativeSetup:(RadarInitializeOptions *)options {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RadarSettings setInitializeOptions:options];
        [RadarNotificationHelper swizzleNotificationCenterDelegate];
    });
}

+ (void)initializeWithPublishableKey:(NSString *)publishableKey options:(RadarInitializeOptions *)options {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"initialize()"];

    Class RadarSDKMotion = NSClassFromString(@"RadarSDKMotion");
    if (RadarSDKMotion) {
        id radarSDKMotion = [[RadarSDKMotion alloc] init];
        [RadarActivityManager sharedInstance].radarSDKMotion = radarSDKMotion;
    }

    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance]
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    [RadarSettings setPublishableKey:publishableKey];

    RadarSdkConfiguration *sdkConfiguration = [RadarSettings sdkConfiguration];
    // For most users not using these features, options be null and skipped,
    //  For X-platform users initializing Radar in the crossplatform layer, the options will also be null as nativeSetup would had been called ealier
    if (options) {
        [RadarSettings setInitializeOptions:options];
        if (NSClassFromString(@"XCTestCase") == nil) {
            if (options.autoLogNotificationConversions || options.autoHandleNotificationDeepLinks) {
                [Radar nativeSetup: options];
            }
        }
    }

    if (sdkConfiguration.usePersistence) {
        [[RadarReplayBuffer sharedInstance] loadReplaysFromPersistentStore];
    }

    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
        [RadarSettings updateSessionId];
    }

    [[RadarLocationManager sharedInstance] updateTrackingFromInitialize];

    [RadarNotificationHelper checkNotificationPermissionsWithCompletionHandler:^(BOOL granted) {
        [[RadarAPIClient sharedInstance] getConfigForUsage:@"initialize"
                                                  verified:NO
                                         completionHandler:^(RadarStatus status, RadarConfig *config) {
                                            if (status == RadarStatusSuccess && config) {
                                                [[RadarLocationManager sharedInstance] updateTrackingFromConfig:config];
                                                [RadarSettings setSdkConfiguration:config.meta.sdkConfiguration];
                                            }

                                            RadarSdkConfiguration *sdkConfiguration = [RadarSettings sdkConfiguration];
                                            if (sdkConfiguration.startTrackingOnInitialize && ![RadarSettings tracking]) {
                                                [Radar startTrackingWithOptions:[RadarSettings trackingOptions]];
                                            }
                                            if (sdkConfiguration.trackOnceOnAppOpen) {
                                                [Radar trackOnceWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium beacons:[Radar getTrackingOptions].beacons completionHandler:nil];
                                            }

                                            [self flushLogs];
                                        }];
    }];

}

+ (void)initializeWithPublishableKey:(NSString *)publishableKey {
    [self initializeWithPublishableKey:publishableKey options:nil];
}

#pragma mark - Properties

+ (NSString *)sdkVersion {
    return [RadarUtils sdkVersion];
}

+ (NSString *_Nullable)getPublishableKey {
    return [RadarSettings publishableKey];
}

+ (void)setUserId:(NSString *)userId {
    [RadarSettings setUserId:userId];
    if ([RadarSettings sdkConfiguration].syncAfterSetUser) {
        [Radar trackOnceWithCompletionHandler:nil];
    }
}

+ (NSString *_Nullable)getUserId {
    return [RadarSettings userId];
}

+ (void)setDescription:(NSString *)description {
    [RadarSettings setDescription:description];
}

+ (NSString *_Nullable)getDescription {
    return [RadarSettings __description];
}

+ (void)setMetadata:(NSDictionary *)metadata {
    [RadarSettings setMetadata:metadata];
    if ([RadarSettings sdkConfiguration].syncAfterSetUser) {
        [Radar trackOnceWithCompletionHandler:nil];
    }
}

+ (NSDictionary *_Nullable)getMetadata {
    return [RadarSettings metadata];
}

+ (NSArray<NSString *> *_Nullable)getTags {
    return [RadarSettings tags];
}

+ (void)setTags:(NSArray<NSString *> *_Nullable)tags {
    [RadarSettings setTags:tags];
}

+ (void)addTags:(NSArray<NSString *> *_Nonnull)tags {
    [RadarSettings addTags:tags];
}

+ (void)removeTags:(NSArray<NSString *> *_Nonnull)tags {
    [RadarSettings removeTags:tags];
}

+ (void)setProduct:(NSString *)product {
    [RadarSettings setProduct:product];
}

+ (NSString *_Nullable)getProduct {
    return [RadarSettings product];
}

+ (void)setAnonymousTrackingEnabled:(BOOL)enabled {
    [RadarSettings setAnonymousTrackingEnabled:enabled];
}

#pragma mark - Location

+ (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"getLocation()"];
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        [RadarUtils runOnMainThread:^{
            completionHandler(status, location, stopped);
        }];
    }];
}

+ (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarLocationCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"getLocation()"];
    [[RadarLocationManager sharedInstance] getLocationWithDesiredAccuracy:desiredAccuracy
                                                        completionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
                                                            [RadarUtils runOnMainThread:^{
                                                                completionHandler(status, location, stopped);
                                                            }];
                                                        }];
}

#pragma mark - Tracking

+ (void)trackOnceWithCompletionHandler:(RadarTrackCompletionHandler)completionHandler {
    [self trackOnceWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium beacons:NO completionHandler:completionHandler];
}

+ (void)trackOnceWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy beacons:(BOOL)beacons completionHandler:(RadarTrackCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"trackOnce()"];
    [[RadarLocationManager sharedInstance]
        getLocationWithDesiredAccuracy:desiredAccuracy
                     completionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
                         if (status != RadarStatusSuccess) {
                             if (completionHandler) {
                                 [RadarUtils runOnMainThread:^{
                                     completionHandler(status, nil, nil, nil);
                                 }];
                             }

                             return;
                         }

                         void (^callTrackAPI)(NSArray<RadarBeacon *> *_Nullable) = ^(NSArray<RadarBeacon *> *_Nullable beacons) {
                             [[RadarAPIClient sharedInstance]
                                 trackWithLocation:location
                                           stopped:stopped
                                        foreground:YES
                                            source:RadarLocationSourceForegroundLocation
                                          replayed:NO
                                           beacons:beacons
                                 completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                     NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
                                    [[RadarLocationManager sharedInstance] updateTrackingFromConfig:config];
                                    if (status == RadarStatusSuccess) {
                                        [[RadarLocationManager sharedInstance] replaceSyncedGeofences:nearbyGeofences];
                                    }

                                    if (completionHandler) {
                                        [RadarUtils runOnMainThread:^{
                                            completionHandler(status, location, events, user);
                                        }];
                                    }
                                }];
                         };

                         if (beacons) {
                             [[RadarAPIClient sharedInstance]
                                 searchBeaconsNear:location
                                            radius:1000
                                             limit:10
                                 completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons,
                                                     NSArray<NSString *> *_Nullable beaconUUIDs) {
                                     if (beaconUUIDs && beaconUUIDs.count) {
                                         [[RadarLocationManager sharedInstance] replaceSyncedBeaconUUIDs:beaconUUIDs];

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
                                         [[RadarLocationManager sharedInstance] replaceSyncedBeacons:beacons];

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
                     }];
}

+ (void)trackOnceWithLocation:(CLLocation *)location completionHandler:(RadarTrackCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"trackOnce()"];
    [[RadarAPIClient sharedInstance] trackWithLocation:location
                                               stopped:NO
                                            foreground:YES
                                                source:RadarLocationSourceManualLocation
                                              replayed:NO
                                               beacons:nil
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                         NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
                                        [[RadarLocationManager sharedInstance] updateTrackingFromConfig:config];
                                        if (completionHandler) {
                                            [RadarUtils runOnMainThread:^{
                                                completionHandler(status, location, events, user);
                                            }];
                                        }
                                    }];
}

+ (void)trackVerifiedWithCompletionHandler:(RadarTrackVerifiedCompletionHandler)completionHandler {
    [self trackVerifiedWithBeacons:NO desiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium completionHandler:completionHandler];
}

+ (void)trackVerifiedWithBeacons:(BOOL)beacons desiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarTrackVerifiedCompletionHandler)completionHandler {
    [self trackVerifiedWithBeacons:NO desiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium reason:nil transactionId:nil completionHandler:completionHandler];
}

+ (void)trackVerifiedWithBeacons:(BOOL)beacons desiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy reason:(NSString *)reason transactionId:(NSString *)transactionId completionHandler:(RadarTrackVerifiedCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"trackVerified()"];
    [[RadarVerificationManager sharedInstance] trackVerifiedWithBeacons:beacons desiredAccuracy:desiredAccuracy reason:reason transactionId:transactionId completionHandler:completionHandler];
}

+ (void)startTrackingVerifiedWithInterval:(NSTimeInterval)interval beacons:(BOOL)beacons {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"startTrackingVerified()"];
    [[RadarVerificationManager sharedInstance] startTrackingVerifiedWithInterval:interval beacons:beacons];
}

+ (void)stopTrackingVerified {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"stopTrackingVerified()"];
    [[RadarVerificationManager sharedInstance] stopTrackingVerified];
}

+ (BOOL)isTrackingVerified {
    return [RadarVerificationManager sharedInstance].started;
}

+ (void)getVerifiedLocationToken:(RadarTrackVerifiedCompletionHandler)completionHandler {
    [self getVerifiedLocationTokenWithBeacons:NO desiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium completionHandler:completionHandler];
}

+ (void)getVerifiedLocationTokenWithBeacons:(BOOL)beacons desiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarTrackVerifiedCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"getVerifiedLocationToken()"];
    [[RadarVerificationManager sharedInstance]
     getVerifiedLocationTokenWithBeacons:beacons desiredAccuracy:desiredAccuracy completionHandler:completionHandler];
}

+ (void)clearVerifiedLocationToken {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"clearVerifiedLocationToken()"];
    [[RadarVerificationManager sharedInstance] clearVerifiedLocationToken];
}

+ (void)setExpectedJurisdictionWithCountryCode:(NSString *)countryCode stateCode:(NSString *)stateCode {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"setExpectedJurisdiction()"];
    [[RadarVerificationManager sharedInstance]
     setExpectedJurisdictionWithCountryCode:countryCode stateCode:stateCode];
}

+ (void)startTrackingWithOptions:(RadarTrackingOptions *)options {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"startTracking()"];

    [[RadarLocationManager sharedInstance] startTrackingWithOptions:options];
}

+ (void)mockTrackingWithOrigin:(CLLocation *)origin
                   destination:(CLLocation *)destination
                          mode:(RadarRouteMode)mode
                         steps:(int)steps
                      interval:(NSTimeInterval)interval
             completionHandler:(RadarTrackCompletionHandler _Nullable)completionHandler {
    [[RadarAPIClient sharedInstance]
        getDistanceFromOrigin:origin
                  destination:destination
                        modes:mode
                        units:RadarRouteUnitsMetric
               geometryPoints:steps
            completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarRoutes *_Nullable routes) {
                NSArray<RadarCoordinate *> *coordinates;
                if (routes) {
                    if (mode == RadarRouteModeFoot && routes.foot && routes.foot.geometry) {
                        coordinates = routes.foot.geometry.coordinates;
                    } else if (mode == RadarRouteModeBike && routes.bike && routes.bike.geometry) {
                        coordinates = routes.bike.geometry.coordinates;
                    } else if (mode == RadarRouteModeCar && routes.car && routes.car.geometry) {
                        coordinates = routes.car.geometry.coordinates;
                    } else if (mode == RadarRouteModeTruck && routes.truck && routes.truck.geometry) {
                        coordinates = routes.truck.geometry.coordinates;
                    } else if (mode == RadarRouteModeMotorbike && routes.motorbike && routes.motorbike.geometry) {
                        coordinates = routes.motorbike.geometry.coordinates;
                    }
                }

                if (!coordinates) {
                    if (completionHandler) {
                        [RadarUtils runOnMainThread:^{
                            completionHandler(status, nil, nil, nil);
                        }];
                    }

                    return;
                }

                NSTimeInterval intervalLimit = interval;
                if (intervalLimit < 1) {
                    intervalLimit = 1;
                } else if (intervalLimit > 60) {
                    intervalLimit = 60;
                }

                __block int i = 0;
                __block void (^track)(void);
                __block __weak void (^weakTrack)(void);
                track = ^{
                    weakTrack = track;
                    RadarCoordinate *coordinate = coordinates[i];
                    CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate.coordinate
                                                                         altitude:-1
                                                               horizontalAccuracy:5
                                                                 verticalAccuracy:-1
                                                                        timestamp:[NSDate new]];
                    BOOL stopped = (i == 0) || (i == coordinates.count - 1);

                    [[RadarAPIClient sharedInstance]
                        trackWithLocation:location
                                  stopped:stopped
                               foreground:NO
                                   source:RadarLocationSourceMockLocation
                                 replayed:NO
                                  beacons:nil
                        completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                            NSArray<RadarGeofence *> *_Nullable nearbyGeofences, RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
                            if (completionHandler) {
                                [RadarUtils runOnMainThread:^{
                                    completionHandler(status, location, events, user);
                                }];
                            }

                            if (i < coordinates.count - 1) {
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(intervalLimit * NSEC_PER_SEC)), dispatch_get_main_queue(), weakTrack);
                            }

                            i++;
                        }];
                };

                track();
            }];
}

+ (void)stopTracking {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"stopTracking()"];
    [[RadarLocationManager sharedInstance] stopTracking];
}

+ (BOOL)isTracking {
    return [RadarSettings tracking];
}

+ (RadarTrackingOptions *)getTrackingOptions {
    RadarTrackingOptions *remoteTrackingOptions = [RadarSettings remoteTrackingOptions];
    return remoteTrackingOptions ? remoteTrackingOptions : [RadarSettings trackingOptions];
}

+ (BOOL)isUsingRemoteTrackingOptions {
    return [RadarSettings remoteTrackingOptions] != nil;
}

#pragma mark - Delegate

+ (void)setDelegate:(id<RadarDelegate>)delegate {
    [RadarDelegateHolder sharedInstance].delegate = delegate;
    [RadarLogger_Swift setDelegate:delegate];
}

+ (void)setVerifiedDelegate:(id<RadarVerifiedDelegate>)verifiedDelegate {
    [RadarDelegateHolder sharedInstance].verifiedDelegate = verifiedDelegate;
}

#pragma mark - Events

+ (void)acceptEventId:(NSString *)eventId verifiedPlaceId:(NSString *)verifiedPlaceId {
    [[RadarAPIClient sharedInstance] verifyEventId:eventId verification:RadarEventVerificationAccept verifiedPlaceId:verifiedPlaceId];
}

+ (void)rejectEventId:(NSString *)eventId {
    [[RadarAPIClient sharedInstance] verifyEventId:eventId verification:RadarEventVerificationReject verifiedPlaceId:nil];
}

+ (void)sendLogConversionRequestWithName:(NSString * _Nonnull) name
                                metadata:(NSDictionary * _Nullable) metadata
                       completionHandler:(RadarLogConversionCompletionHandler) completionHandler {
    [[RadarAPIClient sharedInstance] sendEvent:name withMetadata:metadata completionHandler:^(RadarStatus status, NSDictionary * _Nullable res, RadarEvent * _Nullable event) {
        if (status != RadarStatusSuccess) {
            if (completionHandler) {
                [RadarUtils runOnMainThread:^{
                    completionHandler(status, nil);
                }];
            }

            return;
        }

        if (completionHandler) {
            [RadarUtils runOnMainThread:^{
                completionHandler(status, event);
            }];
        }
    }];
}

+ (void)logOpenedAppConversion {
    if (![RadarSettings useOpenedAppConversion]) {
        return;
    }

    // Perform a non-blocking sleep for 1 second before starting, this is to address the fact that swizzled notification method may be called at a different relative live as compared to this method depending on framework.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // if opened_app has been logged within the last second, don't log it again
        NSTimeInterval lastAppOpenTimeInterval = [[NSDate date] timeIntervalSinceDate:[RadarSettings lastAppOpenTime]];

        if (lastAppOpenTimeInterval > 2) {
            [RadarSettings updateLastAppOpenTime];
            // metadata not needed as app is not opened by notification.
            [self sendLogConversionRequestWithName:@"opened_app" metadata:nil completionHandler:^(RadarStatus status, RadarEvent * _Nullable event) {
                NSString *message = [NSString stringWithFormat:@"Conversion name = %@: status = %@; event = %@", event.conversionName, [Radar stringForStatus:status], event];
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:message];
            }];
        }
    });
}

+ (void)logOpenedAppConversionWithNotification:(UNNotificationRequest *)request
                              conversionSource:(NSString *_Nullable)conversionSource {
    [self logConversionWithNotification:request eventName:@"opened_app" conversionSource:conversionSource deliveredAfter:nil];
}

+ (void)logConversionWithName:(NSString *)name
                     metadata:(NSDictionary *_Nullable)metadata
            completionHandler:(RadarLogConversionCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"logConversion()"];
    NSTimeInterval lastTrackedTimeInterval = [[NSDate date] timeIntervalSinceDate:[RadarSettings lastTrackedTime]];
    BOOL isLastTrackRecent = lastTrackedTimeInterval < 60;

    CLAuthorizationStatus authorizationStatus = [[RadarLocationManager sharedInstance].permissionsHelper locationAuthorizationStatus];
    if (!(authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways) || isLastTrackRecent) {
        [self sendLogConversionRequestWithName:name metadata:metadata completionHandler:completionHandler];

        return;
    }

    [self trackOnceWithCompletionHandler:^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarEvent *> * _Nullable events, RadarUser * _Nullable user) {
        [self sendLogConversionRequestWithName:name metadata:metadata completionHandler:completionHandler];
    }];
}

+ (void)logConversionWithName:(NSString *)name
                      revenue:(NSNumber *)revenue
                     metadata:(NSDictionary * _Nullable)metadata
            completionHandler:(RadarLogConversionCompletionHandler)completionHandler {
    NSMutableDictionary *mutableMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];

    [mutableMetadata setValue:revenue forKey:@"revenue"];

    [self logConversionWithName:name metadata:mutableMetadata completionHandler:completionHandler];
}


+ (void)logConversionWithNotification:(UNNotificationRequest *)request {
    [self logConversionWithNotification:request eventName: @"opened_app" conversionSource:@"notification" deliveredAfter: nil];
}

+ (void)logConversionWithNotification:(UNNotificationRequest *)request
                            eventName:(NSString *)eventName
                     conversionSource:(NSString *)conversionSource
                       deliveredAfter:(NSDate *)deliveredAfter {

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:request.content.userInfo];

    if (conversionSource) {
        [metadata setValue:conversionSource forKey:@"conversionSource"];
    }

    [self sendLogConversionRequestWithName:eventName metadata:metadata completionHandler:^(RadarStatus status, RadarEvent * _Nullable event) {
        NSString *message = [NSString stringWithFormat:@"Conversion name = %@: status = %@; event = %@", event.conversionName, [Radar stringForStatus:status], event];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:message];
    }];
}

+ (void)logConversionWithNotificationResponse:(UNNotificationResponse *)response {
    [RadarNotificationHelper logConversionWithNotificationResponse:response];
}

#pragma mark - Trips

+ (RadarTripOptions *)getTripOptions {
    return [RadarSettings tripOptions];
}

+ (void)startTripWithOptions:(RadarTripOptions *)options {
    [self startTripWithOptions:options completionHandler:nil];
}

+ (void)startTripWithOptions:(RadarTripOptions *)options completionHandler:(RadarTripCompletionHandler)completionHandler {
    [self startTripWithOptions:options trackingOptions:nil completionHandler:completionHandler];
}

+ (void)startTripWithOptions:(RadarTripOptions *)tripOptions
             trackingOptions:(RadarTrackingOptions *)trackingOptions
           completionHandler:(RadarTripCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"startTrip()"];
    [[RadarAPIClient sharedInstance] createTripWithOptions:tripOptions
                                         completionHandler:^(RadarStatus status, RadarTrip *trip, NSArray<RadarEvent *> *events) {
                                             if (status == RadarStatusSuccess) {
                                                 [RadarSettings setTripOptions:tripOptions];

                                                 if (Radar.isTracking) {
                                                     [RadarSettings setPreviousTrackingOptions:[RadarSettings trackingOptions]];
                                                 } else {
                                                     [RadarSettings removePreviousTrackingOptions];
                                                 }

                                                 if (trackingOptions && trackingOptions.startTrackingAfter == nil) {
                                                     [self startTrackingWithOptions:trackingOptions];
                                                 } else if (trackingOptions) {
                                                     [RadarSettings setTrackingOptions:trackingOptions];
                                                 } else if (!Radar.isTracking && tripOptions && tripOptions.startTracking) {
                                                     [self startTrackingWithOptions:[RadarSettings remoteTrackingOptions] ?: [RadarSettings trackingOptions]];
                                                 }

                                                 // flush location update to generate events
                                                 [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:nil];
                                             }

                                             if (completionHandler) {
                                                 [RadarUtils runOnMainThread:^{
                                                     completionHandler(status, trip, events);
                                                 }];
                                             }
                                         }];
}

+ (void)updateTripWithOptions:(RadarTripOptions *)options status:(RadarTripStatus)status completionHandler:(RadarTripCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"updateTrip()"];
    [[RadarAPIClient sharedInstance] updateTripWithOptions:options
                                                    status:status
                                         completionHandler:^(RadarStatus status, RadarTrip *trip, NSArray<RadarEvent *> *events) {
                                             if (status == RadarStatusSuccess) {
                                                 [RadarSettings setTripOptions:options];

                                                 // flush location update to generate events
                                                 [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:nil];
                                             }

                                             if (completionHandler) {
                                                 [RadarUtils runOnMainThread:^{
                                                     completionHandler(status, trip, events);
                                                 }];
                                             }
                                         }];
}

+ (void)completeTrip {
    [self completeTripWithCompletionHandler:nil];
}

+ (void)completeTripWithCompletionHandler:(RadarTripCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"completeTrip()"];
    RadarTripOptions *options = [RadarSettings tripOptions];
    [[RadarAPIClient sharedInstance] updateTripWithOptions:options
                                                    status:RadarTripStatusCompleted
                                         completionHandler:^(RadarStatus status, RadarTrip *trip, NSArray<RadarEvent *> *events) {
                                             if (status == RadarStatusSuccess || status == RadarStatusErrorNotFound) {
                                                 [RadarSettings setTripOptions:nil];

                                                 // return to previous tracking options after trip
                                                 [[RadarLocationManager sharedInstance] restartPreviousTrackingOptions];

                                                 // flush location update to generate events
                                                 [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:nil];
                                             }

                                             if (completionHandler) {
                                                 [RadarUtils runOnMainThread:^{
                                                     completionHandler(status, trip, events);
                                                 }];
                                             }
                                         }];
}

+ (void)cancelTrip {
    [self cancelTripWithCompletionHandler:nil];
}

+ (void)cancelTripWithCompletionHandler:(RadarTripCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"cancelTrip()"];
    RadarTripOptions *options = [RadarSettings tripOptions];
    [[RadarAPIClient sharedInstance] updateTripWithOptions:options
                                                    status:RadarTripStatusCanceled
                                         completionHandler:^(RadarStatus status, RadarTrip *trip, NSArray<RadarEvent *> *events) {
                                             if (status == RadarStatusSuccess || status == RadarStatusErrorNotFound) {
                                                 [RadarSettings setTripOptions:nil];

                                                 // return to previous tracking options after trip
                                                 [[RadarLocationManager sharedInstance] restartPreviousTrackingOptions];

                                                 // flush location update to generate events
                                                 [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:nil];
                                             }

                                             if (completionHandler) {
                                                 [RadarUtils runOnMainThread:^{
                                                     completionHandler(status, trip, events);
                                                 }];
                                             }
                                         }];
}

#pragma mark - Context

+ (void)getContextWithCompletionHandler:(RadarContextCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"getContext()"];
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            if (completionHandler) {
                [RadarUtils runOnMainThread:^{
                    completionHandler(status, nil, nil);
                }];
            }

            return;
        }

        [[RadarAPIClient sharedInstance] getContextForLocation:location
                                             completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarContext *_Nullable context) {
                                                 if (completionHandler) {
                                                     [RadarUtils runOnMainThread:^{
                                                         completionHandler(status, location, context);
                                                     }];
                                                 }
                                             }];
    }];
}

+ (void)getContextForLocation:(CLLocation *)location completionHandler:(RadarContextCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"getContext()"];
    [[RadarAPIClient sharedInstance] getContextForLocation:location
                                         completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarContext *_Nullable context) {
                                             if (completionHandler) {
                                                 [RadarUtils runOnMainThread:^{
                                                     completionHandler(status, location, context);
                                                 }];
                                             }
                                         }];
}

#pragma mark - Search

+ (void)searchPlacesWithRadius:(int)radius
                        chains:(NSArray *_Nullable)chains
                    categories:(NSArray *_Nullable)categories
                        groups:(NSArray *_Nullable)groups
                  countryCodes:(NSArray *_Nullable)countryCodes
                         limit:(int)limit
             completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler {
    [Radar searchPlacesWithRadius:radius chains:chains chainMetadata:nil categories:categories groups:groups  countryCodes:countryCodes limit:limit completionHandler:completionHandler];
}

+ (void)searchPlacesWithRadius:(int)radius
                        chains:(NSArray *_Nullable)chains
                 chainMetadata:(NSDictionary<NSString *, NSString *> *_Nullable)chainMetadata
                    categories:(NSArray *_Nullable)categories
                        groups:(NSArray *_Nullable)groups
                  countryCodes:(NSArray *_Nullable)countryCodes
                         limit:(int)limit
             completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"searchPlaces()"];
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            if (completionHandler) {
                [RadarUtils runOnMainThread:^{
                    completionHandler(status, nil, nil);
                }];
            }

            return;
        }

        [[RadarAPIClient sharedInstance] searchPlacesNear:location
                                                   radius:radius
                                                   chains:chains
                                            chainMetadata:chainMetadata
                                               categories:categories
                                                   groups:groups
                                             countryCodes:countryCodes
                                                    limit:limit
                                        completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarPlace *> *_Nullable places) {
                                            if (completionHandler) {
                                                [RadarUtils runOnMainThread:^{
                                                    completionHandler(status, location, places);
                                                }];
                                            }
                                        }];
    }];
}

+ (void)searchPlacesNear:(CLLocation *_Nonnull)near
                  radius:(int)radius
                  chains:(NSArray *_Nullable)chains
              categories:(NSArray *_Nullable)categories
                  groups:(NSArray *_Nullable)groups
            countryCodes:(NSArray *_Nullable)countryCodes
                   limit:(int)limit
       completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler {
    [Radar searchPlacesNear:near radius:radius chains:chains chainMetadata:nil categories:categories groups:groups countryCodes:countryCodes limit:limit completionHandler:completionHandler];
}

+ (void)searchPlacesNear:(CLLocation *_Nonnull)near
                  radius:(int)radius
                  chains:(NSArray *_Nullable)chains
           chainMetadata:(NSDictionary<NSString *, NSString *> *_Nullable)chainMetadata
              categories:(NSArray *_Nullable)categories
                  groups:(NSArray *_Nullable)groups
            countryCodes:(NSArray *_Nullable)countryCodes
                   limit:(int)limit
       completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"searchPlaces()"];
    [[RadarAPIClient sharedInstance] searchPlacesNear:near
                                               radius:radius
                                               chains:chains
                                        chainMetadata:chainMetadata
                                           categories:categories
                                               groups:groups
                                         countryCodes:countryCodes
                                                limit:limit
                                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarPlace *> *_Nullable places) {
                                        [RadarUtils runOnMainThread:^{
                                            completionHandler(status, near, places);
                                        }];
                                    }];
}

+ (void)searchGeofences:(RadarSearchGeofencesCompletionHandler)completionHandler {
    [Radar searchGeofencesNear: nil radius:-1 tags:nil metadata:nil limit:100 includeGeometry:false completionHandler:completionHandler];
}

+ (void)searchGeofencesNear:(CLLocation *_Nullable)near
                     radius:(int)radius
                       tags:(NSArray<NSString *> *_Nullable)tags
                   metadata:(NSDictionary *_Nullable)metadata
                      limit:(int)limit
            includeGeometry:(BOOL)includeGeometry
          completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"searchGeofences()"];
    if (near == nil) {
        [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
            if (status != RadarStatusSuccess) {
                if (completionHandler) {
                    [RadarUtils runOnMainThread:^{
                        completionHandler(status, nil, nil);
                    }];
                }
                return;
            }
            [[RadarAPIClient sharedInstance] searchGeofencesNear:location
                                                          radius:radius
                                                            tags:tags
                                                        metadata:metadata
                                                           limit:limit
                                                 includeGeometry:includeGeometry
                                               completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarGeofence *> *_Nullable geofences) {
                                                if (completionHandler) {
                                                    [RadarUtils runOnMainThread:^{
                                                        completionHandler(status, location, geofences);
                                                    }];
                                                }
                                              }];
        }];
    } else {
        [[RadarAPIClient sharedInstance] searchGeofencesNear:near
                                                     radius:radius
                                                       tags:tags
                                                   metadata:metadata
                                                      limit:limit
                                            includeGeometry:includeGeometry
                                          completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarGeofence *> *_Nullable geofences) {
                                            if (completionHandler) {
                                                [RadarUtils runOnMainThread:^{
                                                    completionHandler(status, near, geofences);
                                                }];
                                            }
                                       }];
    }
}

+ (void)autocompleteQuery:(NSString *_Nonnull)query
                     near:(CLLocation *_Nullable)near
                   layers:(NSArray *_Nullable)layers
                    limit:(int)limit
                  country:(NSString *_Nullable)country
              expandUnits:(BOOL)expandUnits
        completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] autocompleteQuery:query
                                                  near:near
                                                layers:layers
                                                 limit:limit
                                               country:country
                                              mailable:NO
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                         if (completionHandler) {
                                             [RadarUtils runOnMainThread:^{
                                                 completionHandler(status, addresses);
                                             }];
                                         }
                                     }];
}

+ (void)autocompleteQuery:(NSString *_Nonnull)query
                     near:(CLLocation *_Nullable)near
                   layers:(NSArray *_Nullable)layers
                    limit:(int)limit
                  country:(NSString *_Nullable)country
                 mailable:(BOOL)mailable
        completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] autocompleteQuery:query
                                                  near:near
                                                layers:layers
                                                 limit:limit
                                               country:country
                                              mailable:mailable
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                         if (completionHandler) {
                                             [RadarUtils runOnMainThread:^{
                                                 completionHandler(status, addresses);
                                             }];
                                         }
                                     }];
}

+ (void)autocompleteQuery:(NSString *_Nonnull)query
                     near:(CLLocation *_Nullable)near
                   layers:(NSArray *_Nullable)layers
                    limit:(int)limit
                  country:(NSString *_Nullable)country
        completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"autocomplete()"];
    [[RadarAPIClient sharedInstance] autocompleteQuery:query
                                                  near:near
                                                layers:layers
                                                 limit:limit
                                               country:country
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                         if (completionHandler) {
                                             [RadarUtils runOnMainThread:^{
                                                 completionHandler(status, addresses);
                                             }];
                                         }
                                     }];
}

+ (void)autocompleteQuery:(NSString *_Nonnull)query near:(CLLocation *_Nullable)near limit:(int)limit completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"autocomplete()"];
    [[RadarAPIClient sharedInstance] autocompleteQuery:query
                                                  near:near
                                                layers:nil
                                                 limit:limit
                                               country:nil
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                         if (completionHandler) {
                                             [RadarUtils runOnMainThread:^{
                                                 completionHandler(status, addresses);
                                             }];
                                         }
                                     }];
}

#pragma mark - Geocoding

+ (void)geocodeAddress:(NSString *)query
                layers:(NSArray<NSString *> *_Nullable)layers
             countries:(NSArray<NSString *> *_Nullable)countries
     completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"geocode()"];
    [[RadarAPIClient sharedInstance] geocodeAddress:query
                                             layers:layers
                                          countries:countries
                                  completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                      [RadarUtils runOnMainThread:^{
                                          completionHandler(status, addresses);
                                      }];
                                  }];
}

+ (void)geocodeAddress:(NSString *)query completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [Radar geocodeAddress:query layers:nil countries:nil completionHandler:completionHandler];
}

+ (void)reverseGeocodeWithCompletionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [Radar reverseGeocodeWithLayers:nil completionHandler:completionHandler];
}

+ (void)reverseGeocodeWithLayers:(NSArray<NSString *> *_Nullable)layers
               completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            if (completionHandler) {
                [RadarUtils runOnMainThread:^{
                    completionHandler(status, nil);
                }];
            }

            return;
        }
        [Radar reverseGeocodeLocation:location layers:layers completionHandler:completionHandler];
    }];
}

+ (void)reverseGeocodeLocation:(CLLocation *)location completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [Radar reverseGeocodeLocation:location layers:nil completionHandler:completionHandler];
}

+ (void)reverseGeocodeLocation:(CLLocation *)location
                        layers:(NSArray<NSString *> *_Nullable)layers
             completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"reverseGeocode()"];
    [[RadarAPIClient sharedInstance] reverseGeocodeLocation:location
                                                     layers:layers
                                          completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                              if (completionHandler) {
                                                  [RadarUtils runOnMainThread:^{
                                                      completionHandler(status, addresses);
                                                  }];
                                              }
                                          }];

}

+ (void)ipGeocodeWithCompletionHandler:(RadarIPGeocodeCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"ipGeocode()"];
    [[RadarAPIClient sharedInstance] ipGeocodeWithCompletionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarAddress *_Nullable address, BOOL proxy) {
        if (completionHandler) {
            [RadarUtils runOnMainThread:^{
                completionHandler(status, address, proxy);
            }];
        }
    }];
}

+ (void)validateAddress:(RadarAddress *_Nonnull)address completionHandler:(RadarValidateAddressCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] validateAddress:address
                                  completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarAddress *_Nullable address, RadarAddressVerificationStatus verificationStatus) {
                                      [RadarUtils runOnMainThread:^{
                                          completionHandler(status, address, verificationStatus);
                                      }];
                                  }];
}

#pragma mark - Distance

+ (void)getDistanceToDestination:(CLLocation *)destination
                           modes:(RadarRouteMode)modes
                           units:(RadarRouteUnits)units
               completionHandler:(RadarRouteCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"getDistance()"];
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            if (completionHandler) {
                [RadarUtils runOnMainThread:^{
                    completionHandler(status, nil);
                }];
            }

            return;
        }

        [[RadarAPIClient sharedInstance] getDistanceFromOrigin:location
                                                   destination:destination
                                                         modes:modes
                                                         units:units
                                                geometryPoints:-1
                                             completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarRoutes *_Nullable routes) {
                                                 if (completionHandler) {
                                                     [RadarUtils runOnMainThread:^{
                                                         completionHandler(status, routes);
                                                     }];
                                                 }
                                             }];
    }];
}

+ (void)getDistanceFromOrigin:(CLLocation *)origin
                  destination:(CLLocation *)destination
                        modes:(RadarRouteMode)modes
                        units:(RadarRouteUnits)units
            completionHandler:(RadarRouteCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"getDistance()"];
    [[RadarAPIClient sharedInstance] getDistanceFromOrigin:origin
                                               destination:destination
                                                     modes:modes
                                                     units:units
                                            geometryPoints:-1
                                         completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarRoutes *_Nullable routes) {
                                             if (completionHandler) {
                                                 [RadarUtils runOnMainThread:^{
                                                     completionHandler(status, routes);
                                                 }];
                                             }
                                         }];
}

+ (void)getMatrixFromOrigins:(NSArray<CLLocation *> *_Nonnull)origins
                destinations:(NSArray<CLLocation *> *_Nonnull)destinations
                        mode:(RadarRouteMode)mode
                       units:(RadarRouteUnits)units
           completionHandler:(RadarRouteMatrixCompletionHandler)completionHandler {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"getMatrix()"];
    [[RadarAPIClient sharedInstance] getMatrixFromOrigins:origins
                                             destinations:destinations
                                                     mode:mode
                                                    units:units
                                        completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarRouteMatrix *_Nullable matrix) {
                                            if (completionHandler) {
                                                [RadarUtils runOnMainThread:^{
                                                    completionHandler(status, matrix);
                                                }];
                                            }
                                        }];
}

#pragma mark - Logging

+ (void)setLogLevel:(RadarLogLevel)level {
    NSMutableDictionary *sdkConfiguration = [[RadarSettings clientSdkConfiguration] mutableCopy];
    NSObject *logLevelObj = sdkConfiguration[@"logLevel"];
    if ([logLevelObj isKindOfClass:[NSString class]] && [[RadarLog stringForLogLevel:level] isEqualToString:(NSString *)logLevelObj]) {
        return;
    }
    [sdkConfiguration setValue:[RadarLog stringForLogLevel:level] forKey:@"logLevel"];
    [RadarSettings setClientSdkConfiguration:sdkConfiguration];

    if ([RadarSettings logLevel] == level) {
        return;
    }
    [RadarSdkConfiguration updateSdkConfigurationFromServer];
}

+ (void)logTermination {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug type:RadarLogTypeNone message:@"App terminating" includeDate:YES includeBattery:YES append:YES];
}

+ (void)logBackgrounding {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug type:RadarLogTypeNone message:@"App entering background" includeDate:YES includeBattery:YES append:YES];
    [[RadarLogBuffer sharedInstance] persistLogs];
}

+ (void)logResigningActive {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug type:RadarLogTypeNone message:@"App resigning active" includeDate:YES includeBattery:YES];
}


#pragma mark - Helpers

+ (NSString *)stringForStatus:(RadarStatus)status {
    NSString *str;
    switch (status) {
    case RadarStatusSuccess:
        str = @"SUCCESS";
        break;
    case RadarStatusErrorPublishableKey:
        str = @"ERROR_PUBLISHABLE_KEY";
        break;
    case RadarStatusErrorPermissions:
        str = @"ERROR_PERMISSIONS";
        break;
    case RadarStatusErrorLocation:
        str = @"ERROR_LOCATION";
        break;
    case RadarStatusErrorBluetooth:
        str = @"ERROR_BLUETOOTH";
        break;
    case RadarStatusErrorNetwork:
        str = @"ERROR_NETWORK";
        break;
    case RadarStatusErrorBadRequest:
        str = @"ERROR_BAD_REQUEST";
        break;
    case RadarStatusErrorUnauthorized:
        str = @"ERROR_UNAUTHORIZED";
        break;
    case RadarStatusErrorPaymentRequired:
        str = @"ERROR_PAYMENT_REQUIRED";
        break;
    case RadarStatusErrorForbidden:
        str = @"ERROR_FORBIDDEN";
        break;
    case RadarStatusErrorNotFound:
        str = @"ERROR_NOT_FOUND";
        break;
    case RadarStatusErrorRateLimit:
        str = @"ERROR_RATE_LIMIT";
        break;
    case RadarStatusErrorServer:
        str = @"ERROR_SERVER";
        break;
    default:
        str = @"ERROR_UNKNOWN";
    }
    return str;
}

+ (NSString *)stringForVerificationStatus:(RadarAddressVerificationStatus)status {
    NSString *str;
    switch (status) {
    case RadarAddressVerificationStatusVerified:
        str = @"VERIFIED";
        break;
    case RadarAddressVerificationStatusPartiallyVerified:
        str = @"PARTIALLY_VERIFIED";
        break;
    case RadarAddressVerificationStatusAmbiguous:
        str = @"AMBIGUOUS";
        break;
    case RadarAddressVerificationStatusUnverified:
        str = @"UNVERIFIED";
        break;
    default:
        str = @"UNKNOWN";
    }
    return str;
}

+ (NSString *)stringForActivityType:(RadarActivityType)type {
    NSString *str;
    switch (type) {
    case RadarActivityTypeUnknown:
        str = @"unknown";
        break;
    case RadarActivityTypeStationary:
        str = @"stationary";
        break;
    case RadarActivityTypeFoot:
        str = @"foot";
        break;
    case RadarActivityTypeRun:
        str = @"run";
        break;
    case RadarActivityTypeBike:
        str = @"bike";
        break;
    case RadarActivityTypeCar:
        str = @"car";
        break;
    }
    return str;
}

+ (NSString *)stringForLocationSource:(RadarLocationSource)source {
    NSString *str;
    switch (source) {
    case RadarLocationSourceForegroundLocation:
        str = @"FOREGROUND_LOCATION";
        break;
    case RadarLocationSourceBackgroundLocation:
        str = @"BACKGROUND_LOCATION";
        break;
    case RadarLocationSourceManualLocation:
        str = @"MANUAL_LOCATION";
        break;
    case RadarLocationSourceVisitArrival:
        str = @"VISIT_ARRIVAL";
        break;
    case RadarLocationSourceVisitDeparture:
        str = @"VISIT_DEPARTURE";
        break;
    case RadarLocationSourceGeofenceEnter:
        str = @"GEOFENCE_ENTER";
        break;
    case RadarLocationSourceGeofenceExit:
        str = @"GEOFENCE_EXIT";
        break;
    case RadarLocationSourceMockLocation:
        str = @"MOCK_LOCATION";
        break;
    case RadarLocationSourceBeaconEnter:
        str = @"BEACON_ENTER";
        break;
    case RadarLocationSourceBeaconExit:
        str = @"BEACON_EXIT";
        break;
    case RadarLocationSourceOffline:
        str = @"OFFLINE_DETECTION";
        break;
    case RadarLocationSourceUnknown:
        str = @"UNKNOWN";
    }
    return str;
}

+ (NSString *)stringForMode:(RadarRouteMode)mode {
    return [RadarRouteModeUtils stringForMode:mode];
}

+ (NSString *)stringForTripStatus:(RadarTripStatus)status {
    NSString *str;
    switch (status) {
    case RadarTripStatusStarted:
        str = @"started";
        break;
    case RadarTripStatusApproaching:
        str = @"approaching";
        break;
    case RadarTripStatusArrived:
        str = @"arrived";
        break;
    case RadarTripStatusExpired:
        str = @"expired";
        break;
    case RadarTripStatusCompleted:
        str = @"completed";
        break;
    case RadarTripStatusCanceled:
        str = @"canceled";
        break;
    default:
        str = @"unknown";
    }
    return str;
}

+ (NSDictionary *)dictionaryForLocation:(CLLocation *)location {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"latitude"] = @(location.coordinate.latitude);
    dict[@"longitude"] = @(location.coordinate.longitude);
    dict[@"accuracy"] = @(location.horizontalAccuracy);
    dict[@"altitude"] = @(location.altitude);
    dict[@"verticalAccuracy"] = @(location.verticalAccuracy);
    dict[@"speed"] = @(location.speed);
    dict[@"speedAccuracy"] = @(location.speedAccuracy);
    dict[@"course"] = @(location.course);
    if (@available(iOS 13.4, *)) {
        dict[@"courseAccuracy"] = @(location.courseAccuracy);
    }
    if (@available(iOS 15.0, *)) {
        CLLocationSourceInformation *sourceInformation = location.sourceInformation;
        if (sourceInformation) {
            if (sourceInformation.isSimulatedBySoftware || sourceInformation.isProducedByAccessory) {
                dict[@"mocked"] = @(YES);
            } else {
                dict[@"mocked"] = @(NO);
            }
        }
    }
    return dict;
}

- (void)applicationWillEnterForeground {
    BOOL updated = [RadarSettings updateSessionId];
    if (updated) {
        [[RadarAPIClient sharedInstance] getConfigForUsage:@"resume"
                                                  verified:NO
                                         completionHandler:^(RadarStatus status, RadarConfig *_Nullable config) {
                                             if (status != RadarStatusSuccess || !config) {
                                                return;
                                             }
                                             [[RadarLocationManager sharedInstance] updateTrackingFromConfig:config];
                                             [RadarSettings setSdkConfiguration:config.meta.sdkConfiguration];
                                         }];
    }

    [Radar logOpenedAppConversion];

    RadarSdkConfiguration *sdkConfiguration = [RadarSettings sdkConfiguration];
    if (sdkConfiguration.trackOnceOnAppOpen) {
        [Radar trackOnceWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium beacons: [Radar getTrackingOptions].beacons completionHandler:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)sendLog:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *_Nonnull)message {
    [[RadarLogBuffer sharedInstance] write:level type:type message:message ];
}

+ (void)flushLogs {
    NSArray<RadarLog *> *flushableLogs = [[RadarLogBuffer sharedInstance] flushableLogs];
    NSUInteger pendingLogCount = [flushableLogs count];
    if (pendingLogCount == 0) {
        return;
    }

    RadarSyncLogsAPICompletionHandler onComplete = ^(RadarStatus status) {
        [[RadarLogBuffer sharedInstance] onFlush:status == RadarStatusSuccess logs:flushableLogs];
    };

    [[RadarAPIClient sharedInstance] syncLogs:flushableLogs
                            completionHandler:^(RadarStatus status) {
                                if (onComplete) {
                                    [RadarUtils runOnMainThread:^{
                                        onComplete(status);
                                    }];
                                }
                            }];
}

+ (void)openURLFromNotification:(UNNotification *)notification {
    [RadarNotificationHelper openURLFromNotification:notification];
}

+ (void)setInAppMessageDelegate:(id)delegate {
    if (@available(iOS 13.0, *)) {
        [[RadarInAppMessageManager shared] setDelegate:delegate];
    }
}

+ (void) loadImage:(NSString*)url completionHandler:(void (^ _Nonnull)(UIImage * _Nullable))completionHandler {
    if (@available(iOS 13.0, *)) {
        return [RadarInAppMessageDelegate_Swift loadImage:url completionHandler:completionHandler];
    } else {
        completionHandler(nil);
    }
}

+ (void) __writeToLogBufferWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *)message forcePersist:(BOOL)forcePersist {
    [[RadarLogBuffer sharedInstance] write:level type:type message:message forcePersist:forcePersist];
}

@end
