//
//  RadarAPIClient.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAPIClient.h"

#import "Radar+Internal.h"
#import "Radar.h"
#import "RadarAddress+Internal.h"
#import "RadarBeacon+Internal.h"
#import "RadarConfig.h"
#import "RadarContext+Internal.h"
#import "RadarCoordinate+Internal.h"
#import "RadarDelegateHolder.h"
#import "RadarEvent+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarLocationManager.h"
#import "RadarLogger.h"
#import "RadarPlace+Internal.h"
#import "RadarReplay.h"
#import "RadarReplayBuffer.h"
#import "RadarRouteMatrix+Internal.h"
#import "RadarRoutes+Internal.h"
#import "RadarSdkConfiguration.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarTrip+Internal.h"
#import "RadarTripOptions.h"
#import "RadarUser+Internal.h"
#import "RadarUtils.h"
#import "RadarVerificationManager.h"
#import "RadarVerifiedLocationToken+Internal.h"
#import <os/log.h>

@implementation RadarAPIClient

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _apiHelper = [RadarAPIHelper new];
    }
    return self;
}

+ (NSDictionary *)headersWithPublishableKey:(NSString *)publishableKey {
    NSMutableDictionary *headers = [@{
        @"Authorization": publishableKey,
        @"Content-Type": @"application/json",
        @"X-Radar-Config": @"true",
        @"X-Radar-Device-Make": [RadarUtils deviceMake],
        @"X-Radar-Device-Model": [RadarUtils deviceModel],
        @"X-Radar-Device-OS": [RadarUtils deviceOS],
        @"X-Radar-Device-Type": [RadarUtils deviceType],
        @"X-Radar-SDK-Version": [RadarUtils sdkVersion],
        @"X-Radar-Mobile-Origin": [[NSBundle mainBundle] bundleIdentifier],

    } mutableCopy];
    if ([RadarSettings xPlatform]) {
        [headers addEntriesFromDictionary:@{
            @"X-Radar-X-Platform-SDK-Type": [RadarSettings xPlatformSDKType],
            @"X-Radar-X-Platform-SDK-Version": [RadarSettings xPlatformSDKVersion]
        }];
    } else {
        [headers addEntriesFromDictionary:@{
            @"X-Radar-X-Platform-SDK-Type": @"Native"
        }];
    }
    return headers;
}

- (void)getConfigForUsage:(NSString *_Nullable)usage verified:(BOOL)verified completionHandler:(RadarConfigAPICompletionHandler _Nonnull)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return;
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"installId" value:[RadarSettings installId]]];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"sessionId" value:[RadarSettings sessionId]]];
    NSString *_id = [RadarSettings _id];
    if (_id != nil) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"id" value:_id]];
    }
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"locationAuthorization" value:[RadarUtils locationAuthorization]]];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"locationAccuracyAuthorization" value:[RadarUtils locationAccuracyAuthorization]]];
    if (usage) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"usage" value:usage]];
    }
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"verified" value:(verified ? @"true" : @"false")]];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"clientSdkConfiguration" value:[RadarUtils dictionaryToJson:[RadarSettings clientSdkConfiguration]]]];

    NSURLComponents *query = [[NSURLComponents alloc] init];
    [query setQueryItems:queryString];
    NSString *url = [NSString stringWithFormat:@"v1/config%@", query.string];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:verified
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (!res) {
                            return;
                        }

                        [Radar flushLogs];

                        RadarConfig *config = [RadarConfig fromDictionary:res];

                        completionHandler(status, config);
                    }];
}

- (void)flushReplays:(NSArray<NSDictionary *> *_Nonnull)replays
   completionHandler:(RadarFlushReplaysAPICompletionHandler _Nonnull)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return;
    }

    NSString *url = @"v1/track/replay";

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    NSMutableDictionary *requestParams = [NSMutableDictionary new];
    requestParams[@"replays"] = replays;

    [self.apiHelper requestWithMethod:@"POST"
                                  url:url
                              headers:headers
                               params:requestParams
                                sleep:NO
                           logPayload:NO
                      extendedTimeout:YES
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                            id eventsObj = res[@"events"];
                            id userObj = res[@"user"];

                            NSArray<RadarEvent *> *events = [RadarEvent eventsFromObject:eventsObj];
                            RadarUser *user = [[RadarUser alloc] initWithObject:userObj];
                            if (events && events.count) {
                                [[RadarDelegateHolder sharedInstance] didReceiveEvents:events user:user];
                            }

                        completionHandler(status, res);
                    }];
}

- (void)trackWithLocation:(CLLocation *_Nonnull)location
                  stopped:(BOOL)stopped
               foreground:(BOOL)foreground
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
                  beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
        completionHandler:(RadarTrackAPICompletionHandler _Nonnull)completionHandler {
    [self trackWithLocation:location
                    stopped:stopped
                 foreground:foreground
                     source:source
                   replayed:replayed
                    beacons:beacons
                   verified:NO
          attestationString:nil
                      keyId:nil
           attestationError:nil
                  encrypted:NO
          completionHandler:completionHandler];
}

- (void)trackWithLocation:(CLLocation *_Nonnull)location
                  stopped:(BOOL)stopped
               foreground:(BOOL)foreground
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
                  beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                 verified:(BOOL)verified
        attestationString:(NSString *_Nullable)attestationString
                    keyId:(NSString *_Nullable)keyId
         attestationError:(NSString *_Nullable)attestationError
                encrypted:(BOOL)encrypted
        completionHandler:(RadarTrackAPICompletionHandler _Nonnull)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil, nil, nil, nil, nil);
    }
    NSMutableDictionary *params = [NSMutableDictionary new];
    BOOL anonymous = [RadarSettings anonymousTrackingEnabled];
    params[@"anonymous"] = @(anonymous);
    if (anonymous) {
        params[@"deviceId"] = @"anonymous";
        params[@"geofenceIds"] = [RadarState geofenceIds];
        params[@"placeId"] = [RadarState placeId];
        params[@"regionIds"] = [RadarState regionIds];
        params[@"beaconIds"] = [RadarState beaconIds];
    } else {
        params[@"id"] = [RadarSettings _id];
        params[@"installId"] = [RadarSettings installId];
        params[@"userId"] = [RadarSettings userId];
        params[@"deviceId"] = [RadarUtils deviceId];
        params[@"description"] = [RadarSettings __description];
        params[@"metadata"] = [RadarSettings metadata];
        NSString *sessionId = [RadarSettings sessionId];
        if (sessionId) {
            params[@"sessionId"] = sessionId;
        }
    }
    params[@"latitude"] = @(location.coordinate.latitude);
    params[@"longitude"] = @(location.coordinate.longitude);
    CLLocationAccuracy accuracy = location.horizontalAccuracy;
    if (accuracy <= 0) {
        accuracy = 1;
    }
    params[@"accuracy"] = @(accuracy);
    params[@"altitude"] = @(location.altitude);
    params[@"verticalAccuracy"] = @(location.verticalAccuracy);
    params[@"speed"] = @(location.speed);
    params[@"speedAccuracy"] = @(location.speedAccuracy);
    params[@"course"] = @(location.course);
    if (@available(iOS 13.4, *)) {
        params[@"courseAccuracy"] = @(location.courseAccuracy);
    }
    if (location.floor) {
        params[@"floorLevel"] = @(location.floor.level);
    }
    long nowMs = (long)([NSDate date].timeIntervalSince1970 * 1000);
    if (!foreground) {
        long timeInMs = (long)(location.timestamp.timeIntervalSince1970 * 1000);
        params[@"updatedAtMsDiff"] = @(nowMs - timeInMs);
    }
    params[@"foreground"] = @(foreground);
    params[@"stopped"] = @(stopped);
    params[@"replayed"] = @(replayed);
    params[@"deviceType"] = [RadarUtils deviceType];
    params[@"deviceMake"] = [RadarUtils deviceMake];
    params[@"sdkVersion"] = [RadarUtils sdkVersion];
    params[@"deviceModel"] = [RadarUtils deviceModel];
    params[@"deviceOS"] = [RadarUtils deviceOS];
    params[@"country"] = [RadarUtils country];
    params[@"timeZoneOffset"] = [RadarUtils timeZoneOffset];
    params[@"source"] = [Radar stringForLocationSource:source];
    if ([RadarSettings xPlatform]) {
        params[@"xPlatformType"] = [RadarSettings xPlatformSDKType];
        params[@"xPlatformSDKVersion"] = [RadarSettings xPlatformSDKVersion];
    } else {
        params[@"xPlatformType"] = @"Native";
    }
    NSMutableArray<NSString *> *fraudFailureReasons = [NSMutableArray new];
    if (@available(iOS 15.0, *)) {
        CLLocationSourceInformation *sourceInformation = location.sourceInformation;
        if (sourceInformation) {
            if (sourceInformation.isSimulatedBySoftware) {
                params[@"mocked"] = @(YES);
                [fraudFailureReasons addObject:@"fraud_mocked_from_mock_provider"];
            }
            if (sourceInformation.isProducedByAccessory) {
                [fraudFailureReasons addObject:@"fraud_mocked_produced_by_accessory"];
            }
        }
    }
    
    RadarTripOptions *tripOptions = Radar.getTripOptions;

    if (tripOptions) {
        NSMutableDictionary *tripParams = [NSMutableDictionary new];
        tripParams[@"version"] = @("2");
        [tripParams setValue:tripOptions.externalId forKey:@"externalId"];
        [tripParams setValue:tripOptions.metadata forKey:@"metadata"];
        [tripParams setValue:tripOptions.destinationGeofenceTag forKey:@"destinationGeofenceTag"];
        [tripParams setValue:tripOptions.destinationGeofenceExternalId forKey:@"destinationGeofenceExternalId"];
        [tripParams setValue:[Radar stringForMode:tripOptions.mode] forKey:@"mode"];
        params[@"tripOptions"] = tripParams;
    }

    RadarTrackingOptions *options = [Radar getTrackingOptions];
    if (options.syncGeofences) {
        params[@"nearbyGeofences"] = @(YES);
    }
    if (beacons) {
        params[@"beacons"] = [RadarBeacon arrayForBeacons:beacons];
    }
    NSString *locationAuthorization = [RadarUtils locationAuthorization];
    if (locationAuthorization) {
        params[@"locationAuthorization"] = locationAuthorization;
    }
    NSString *locationAccuracyAuthorization = [RadarUtils locationAccuracyAuthorization];
    if (locationAccuracyAuthorization) {
        params[@"locationAccuracyAuthorization"] = locationAccuracyAuthorization;
    }

    params[@"trackingOptions"] = [options dictionaryValue];

    BOOL usingRemoteTrackingOptions = RadarSettings.tracking && RadarSettings.remoteTrackingOptions;
    params[@"usingRemoteTrackingOptions"] = @(usingRemoteTrackingOptions);

    params[@"verified"] = @(verified);
    if (verified) {
        params[@"attestationString"] = attestationString;
        params[@"keyId"] = keyId;
        params[@"attestationError"] = attestationError;
        params[@"encrypted"] = @(encrypted);
        BOOL jailbroken = [[RadarVerificationManager sharedInstance] isJailbroken];
        params[@"compromised"] = @(jailbroken);
        if (jailbroken) {
            [fraudFailureReasons addObject:@"fraud_compromised_jailbroken"];
        }
    }
    params[@"appId"] = [[NSBundle mainBundle] bundleIdentifier];
    
    params[@"fraudFailureReasons"] = fraudFailureReasons;

    if (anonymous) {
        [[RadarAPIClient sharedInstance] getConfigForUsage:@"track"
                                                  verified:verified
                                         completionHandler:^(RadarStatus status, RadarConfig *_Nullable config){

                                         }];
    }

    NSString *url = @"v1/track";
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    NSArray<RadarReplay *> *replays = [[RadarReplayBuffer sharedInstance] flushableReplays];
    NSUInteger replayCount = replays.count;
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Checking replays in API client | replayCount = %lu", (unsigned long)replayCount]];
    NSMutableDictionary *requestParams = [params mutableCopy];

    BOOL replaying = options.replay == RadarTrackingOptionsReplayAll && replayCount > 0 && !verified;
    if (replaying) {
        [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:params completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
            if (status != RadarStatusSuccess) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Failed to flush replays"]];
                [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];
            } else {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Successfully flushed replays"]];
                [RadarState setLastFailedStoppedLocation:nil];
                [RadarSettings updateLastTrackedTime];
            }

            completionHandler(status, nil, nil, nil, nil, nil, nil);
        }];
    } else {
        [self.apiHelper requestWithMethod:@"POST"
                                      url:url
                                  headers:headers
                                   params:requestParams
                                    sleep:YES
                               logPayload:YES
                          extendedTimeout:NO
                                 verified:verified
                        completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                            if (status != RadarStatusSuccess || !res) {
                                if (options.replay == RadarTrackingOptionsReplayAll) {
                                    // create a copy of params that we can use to write to the buffer in case of request failure
                                    NSMutableDictionary *bufferParams = [params mutableCopy];
                                    bufferParams[@"replayed"] = @(YES);
                                    bufferParams[@"updatedAtMs"] = @(nowMs);
                                    // remove the updatedAtMsDiff key because for replays we want to rely on the updatedAtMs key for the time instead
                                    [bufferParams removeObjectForKey:@"updatedAtMsDiff"];

                                    [[RadarReplayBuffer sharedInstance] writeNewReplayToBuffer:bufferParams];
                                } else if (options.replay == RadarTrackingOptionsReplayStops && stopped &&
                                        !(source == RadarLocationSourceForegroundLocation || source == RadarLocationSourceManualLocation)) {
                                    [RadarState setLastFailedStoppedLocation:location];
                                }

                                [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];

                                return completionHandler(status, nil, nil, nil, nil, nil, nil);
                            }

                            [[RadarReplayBuffer sharedInstance] clearBuffer];
                            [RadarState setLastFailedStoppedLocation:nil];
                            [Radar flushLogs];
                            [RadarSettings updateLastTrackedTime];

                            RadarConfig *config = [RadarConfig fromDictionary:res];

                            id eventsObj = res[@"events"];
                            id userObj = res[@"user"];
                            id nearbyGeofencesObj = res[@"nearbyGeofences"];
                            NSArray<RadarEvent *> *events = [RadarEvent eventsFromObject:eventsObj];
                            RadarUser *user = [[RadarUser alloc] initWithObject:userObj];
                            NSArray<RadarGeofence *> *nearbyGeofences = [RadarGeofence geofencesFromObject:nearbyGeofencesObj];
                            RadarVerifiedLocationToken *token = [[RadarVerifiedLocationToken alloc] initWithObject:res];

                            if (user) {
                                BOOL inGeofences = user.geofences && user.geofences.count;
                                BOOL atPlace = user.place != nil;
                                BOOL canExit = inGeofences || atPlace;
                                [RadarState setCanExit:canExit];

                                NSMutableArray *geofenceIds = [NSMutableArray new];
                                if (user.geofences) {
                                    for (RadarGeofence *geofence in user.geofences) {
                                        [geofenceIds addObject:geofence._id];
                                    }
                                }
                                [RadarState setGeofenceIds:geofenceIds];

                                NSString *placeId = nil;
                                if (user.place) {
                                    placeId = user.place._id;
                                }
                                [RadarState setPlaceId:placeId];

                                NSMutableArray *regionIds = [NSMutableArray new];
                                if (user.country) {
                                    [regionIds addObject:user.country._id];
                                }
                                if (user.state) {
                                    [regionIds addObject:user.state._id];
                                }
                                if (user.dma) {
                                    [regionIds addObject:user.dma._id];
                                }
                                if (user.postalCode) {
                                    [regionIds addObject:user.postalCode._id];
                                }
                                [RadarState setRegionIds:regionIds];

                                NSMutableArray *beaconIds = [NSMutableArray new];
                                if (user.beacons) {
                                    for (RadarBeacon *beacon in user.beacons) {
                                        [beaconIds addObject:beacon._id];
                                    }
                                }
                                [RadarState setBeaconIds:beaconIds];
                            }

                            if (events && user) {
                                [RadarSettings setId:user._id];

                                // if user was on a trip that ended server-side, restore previous tracking options
                                if (!user.trip && [RadarSettings tripOptions]) {
                                    [[RadarLocationManager sharedInstance] restartPreviousTrackingOptions];
                                    [RadarSettings setTripOptions:nil];
                                }

                                [RadarSettings setUserDebug:user.debug];

                                if (location) {
                                    [[RadarDelegateHolder sharedInstance] didUpdateLocation:location user:user];
                                }

                                if (events.count) {
                                    [[RadarDelegateHolder sharedInstance] didReceiveEvents:events user:user];
                                }
                                
                                if (token) {
                                    [[RadarDelegateHolder sharedInstance] didUpdateToken:token];
                                }

                                return completionHandler(RadarStatusSuccess, res, events, user, nearbyGeofences, config, token);
                            }

                            [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];

                            completionHandler(RadarStatusErrorServer, nil, nil, nil, nil, nil, nil);
                        }];
    }
}

- (void)verifyEventId:(NSString *)eventId verification:(RadarEventVerification)verification verifiedPlaceId:(NSString *)verifiedPlaceId {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey || !eventId) {
        return;
    }

    NSMutableDictionary *params = [NSMutableDictionary new];

    params[@"verification"] = @(verification);
    if (verifiedPlaceId) {
        params[@"verifiedPlaceId"] = verifiedPlaceId;
    }

    NSString *url = [NSString stringWithFormat:@"v1/events/%@/verification", eventId];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"PUT"
                                  url:url
                              headers:headers
                               params:params
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res){

                    }];
}

#pragma mark - Trips

- (void)createTripWithOptions:(RadarTripOptions *)options completionHandler:(RadarTripAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    if (!options || !options.externalId) {
        return completionHandler(RadarStatusErrorBadRequest, nil, nil);
    }

    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"userId"] = RadarSettings.userId;
    params[@"externalId"] = options.externalId;

    if (options.metadata) {
        params[@"metadata"] = options.metadata;
    }

    if (options.destinationGeofenceTag) {
        params[@"destinationGeofenceTag"] = options.destinationGeofenceTag;
    }

    if (options.destinationGeofenceExternalId) {
        params[@"destinationGeofenceExternalId"] = options.destinationGeofenceExternalId;
    }

    params[@"mode"] = [Radar stringForMode:options.mode];

    if (options.scheduledArrivalAt) {
        params[@"scheduledArrivalAt"] = [[RadarUtils isoDateFormatter] stringFromDate:options.scheduledArrivalAt];
    }

    if (options.approachingThreshold > 0) {
        params[@"approachingThreshold"] = [NSString stringWithFormat:@"%d", options.approachingThreshold];
    }

    NSString *url = [NSString stringWithFormat:@"v1/trips"];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"POST"
                                  url:url
                              headers:headers
                               params:params
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id tripObj = res[@"trip"];
                        id eventsObj = res[@"events"];
                        RadarTrip *trip = [[RadarTrip alloc] initWithObject:tripObj];
                        NSArray<RadarEvent *> *events = [RadarEvent eventsFromObject:eventsObj];

                        if (events && events.count) {
                            [[RadarDelegateHolder sharedInstance] didReceiveEvents:events user:nil];
                        }

                        completionHandler(RadarStatusSuccess, trip, events);
                    }];
}

- (void)updateTripWithOptions:(RadarTripOptions *)options status:(RadarTripStatus)status completionHandler:(RadarTripAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    if (!options || !options.externalId) {
        return completionHandler(RadarStatusErrorBadRequest, nil, nil);
    }

    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"userId"] = [RadarSettings userId];
    // don't pass the externalId like createTrip() does

    if (status != RadarTripStatusUnknown) {
        params[@"status"] = [Radar stringForTripStatus:status];
    }

    if (options.metadata) {
        params[@"metadata"] = options.metadata;
    }

    if (options.destinationGeofenceTag) {
        params[@"destinationGeofenceTag"] = options.destinationGeofenceTag;
    }

    if (options.destinationGeofenceExternalId) {
        params[@"destinationGeofenceExternalId"] = options.destinationGeofenceExternalId;
    }

    params[@"mode"] = [Radar stringForMode:options.mode];

    if (options.scheduledArrivalAt) {
        params[@"scheduledArrivalAt"] = [[RadarUtils isoDateFormatter] stringFromDate:options.scheduledArrivalAt];
    }

    if (options.approachingThreshold > 0) {
        params[@"approachingThreshold"] = [NSString stringWithFormat:@"%d", options.approachingThreshold];
    }

    NSString *url = [NSString stringWithFormat:@"v1/trips/%@/update", options.externalId];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"PATCH"
                                  url:url
                              headers:headers
                               params:params
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id tripObj = res[@"trip"];
                        id eventsObj = res[@"events"];
                        RadarTrip *trip = [[RadarTrip alloc] initWithObject:tripObj];
                        NSArray<RadarEvent *> *events = [RadarEvent eventsFromObject:eventsObj];

                        if (events && events.count) {
                            [[RadarDelegateHolder sharedInstance] didReceiveEvents:events user:nil];
                        }

                        completionHandler(RadarStatusSuccess, trip, events);
                    }];
}

- (void)getContextForLocation:(CLLocation *_Nonnull)location completionHandler:(RadarContextAPICompletionHandler _Nonnull)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"coordinates"
                                                       value:[NSString stringWithFormat:@"%.06f,%.06f", location.coordinate.latitude, location.coordinate.longitude]]];

    NSURLComponents* url = [[NSURLComponents alloc] initWithString:@"v1/context"];
    [url setQueryItems:queryString];
    
    NSLog(@"TEST: %@", url.string);

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id contextObj = res[@"context"];
                        RadarContext *context = [[RadarContext alloc] initWithObject:contextObj];
                        if (context) {
                            return completionHandler(RadarStatusSuccess, res, context);
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil);
                    }];
}

- (void)searchPlacesNear:(CLLocation *_Nonnull)near
                  radius:(int)radius
                  chains:(NSArray *_Nullable)chains
           chainMetadata:(NSDictionary<NSString *, NSString *> *_Nullable)chainMetadata
              categories:(NSArray *_Nullable)categories
                  groups:(NSArray *_Nullable)groups
                   limit:(int)limit
       completionHandler:(RadarSearchPlacesAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"near"
                                                       value:[NSString stringWithFormat:@"%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude]]];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"radius" value:@(radius).stringValue]];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"limit" value:@(MIN(limit, 100)).stringValue]];
    if (chains && [chains count] > 0) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"chains" value:[chains componentsJoinedByString:@","]]];
    }
    if (categories && [categories count] > 0) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"categories" value:[categories componentsJoinedByString:@","]]];
    }
    if (groups && [groups count] > 0) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"groups" value:[groups componentsJoinedByString:@","]]];
    }

    [chainMetadata enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull value, BOOL *_Nonnull stop) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:[NSString stringWithFormat:@"chainMetadata[%@]", key]
                                                           value:[NSString stringWithFormat:@"\"%@\"", value]]];
    }];

    
    NSURLComponents* url = [[NSURLComponents alloc] initWithString:@"v1/search/places"];
    [url setQueryItems:queryString];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id placesObj = res[@"places"];
                        NSArray<RadarPlace *> *places = [RadarPlace placesFromObject:placesObj];
                        if (places) {
                            return completionHandler(RadarStatusSuccess, res, places);
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil);
                    }];
}

- (void)searchGeofencesNear:(CLLocation *_Nonnull)near
                     radius:(int)radius
                       tags:(NSArray *_Nullable)tags
                   metadata:(NSDictionary *_Nullable)metadata
                      limit:(int)limit
            includeGeometry:(BOOL)includeGeometry
          completionHandler:(RadarSearchGeofencesAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"near"
                                                       value:[NSString stringWithFormat:@"%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude]]];
    
    if (radius > 0) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"radius"
                                                           value:@(radius).stringValue]];
        
    }
    
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"limit"
                                                       value:@(MIN(limit, 1000)).stringValue]];
    if (tags && [tags count] > 0) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"tags"
                                                           value:[tags componentsJoinedByString:@","]]];
    }
    if (metadata && [metadata count] > 0) {
        for (NSString *key in metadata) {
            [queryString addObject:[NSURLQueryItem queryItemWithName:[NSString stringWithFormat:@"metadata[%@]", key]
                                                               value:[NSString stringWithFormat:@"%@", metadata[key]]]];
        }
    }
    
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"includeGeometry"
                                                       value:(includeGeometry ? @"true" : @"false")]];
    
    NSURLComponents *url = [[NSURLComponents alloc] initWithString:@"v1/search/geofences%@"];
    [url setQueryItems:queryString];
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id geofencesObj = res[@"geofences"];
                        NSArray<RadarGeofence *> *geofences = [RadarGeofence geofencesFromObject:geofencesObj];
                        if (geofences) {
                            return completionHandler(RadarStatusSuccess, res, geofences);
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil);
                    }];
}

- (void)searchBeaconsNear:(CLLocation *)near radius:(int)radius limit:(int)limit completionHandler:(RadarSearchBeaconsAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil, nil);
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"near"
                                                       value:[NSString stringWithFormat:@"%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude]]];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"radius"  value:@(radius).stringValue]];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"limit=%d" value:@(MIN(limit, 100)).stringValue]];

    NSURLComponents *url = [[NSURLComponents alloc] initWithString:@"v1/search/beacons"];
    [url setQueryItems:queryString];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];
    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil, nil);
                        }

                        id beaconsObj = res[@"beacons"];
                        NSArray<RadarBeacon *> *beacons = [RadarBeacon beaconsFromObject:beaconsObj];

                        NSMutableArray<NSString *> *beaconUUIDs = [NSMutableArray new];
                        id metaObj = res[@"meta"];
                        if (metaObj) {
                            NSDictionary *meta = (NSDictionary *)metaObj;
                            id settingsObj = meta[@"settings"];
                            if (settingsObj) {
                                NSDictionary *settings = (NSDictionary *)settingsObj;
                                id beaconsObj = settings[@"beacons"];
                                if (beaconsObj) {
                                    NSDictionary *beacons = (NSDictionary *)beaconsObj;
                                    NSArray<NSString *> *uuids = beacons[@"uuids"];
                                    for (NSString *uuid in uuids) {
                                        if (uuid && uuid.length) {
                                            [beaconUUIDs addObject:uuid];
                                        }
                                    }
                                    [RadarSettings setBeaconUUIDs:beaconUUIDs];
                                }
                            }
                        }

                        completionHandler(RadarStatusSuccess, res, beacons, beaconUUIDs);
                    }];
}

- (void)autocompleteQuery:(NSString *)query
                     near:(CLLocation *_Nullable)near
                   layers:(NSArray<NSString *> *_Nullable)layers
                    limit:(int)limit
                  country:(NSString *_Nullable)country
                 mailable:(BOOL)mailable
        completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"query" value:query]];
    if (near) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"near"
                                                           value:[NSString stringWithFormat:@"%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude]]];
    }
    if (layers && layers.count > 0) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"layers" value:[layers componentsJoinedByString:@","]]];
    }
    if (limit) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"limit" value:@(MIN(limit, 100)).stringValue]];
    }
    if (country) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"country" value:country]];
    }
    if (mailable) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"mailable" value:@"true"]];
    }
    
    NSURLComponents *url = [[NSURLComponents alloc] initWithString:@"v1/search/autocomplete"];
    [url setQueryItems:queryString];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id addressesObj = res[@"addresses"];
                        NSArray<RadarAddress *> *addresses = [RadarAddress addressesFromObject:addressesObj];
                        if (addresses) {
                            return completionHandler(RadarStatusSuccess, res, addresses);
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil);
                    }];
}

- (void)autocompleteQuery:(NSString *)query
                     near:(CLLocation *_Nullable)near
                   layers:(NSArray<NSString *> *_Nullable)layers
                    limit:(int)limit
                  country:(NSString *_Nullable)country
        completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    int finalLimit = MIN(limit, 100);

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"query" value:query]];
    if (near) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"near" value:[NSString stringWithFormat:@"%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude]]];
    }
    if (layers && layers.count > 0) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"layers" value:[layers componentsJoinedByString:@","]]];
    }
    if (limit) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"limit" value:@(MIN(limit, 100)).stringValue]];
    }
    if (country) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"country" value:country]];
    }

    NSURLComponents *url = [[NSURLComponents alloc] initWithString:@"v1/search/autocomplete"];
    [url setQueryItems:queryString];
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id addressesObj = res[@"addresses"];
                        NSArray<RadarAddress *> *addresses = [RadarAddress addressesFromObject:addressesObj];
                        if (addresses) {
                            return completionHandler(RadarStatusSuccess, res, addresses);
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil);
                    }];
}

- (void)validateAddress:(RadarAddress *)address completionHandler:(RadarValidateAddressAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil, RadarAddressVerificationStatusNone);
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    if (!address.countryCode || !address.stateCode || !address.city || !address.number || !address.postalCode || !address.street) {
        if (completionHandler) {
            [RadarUtils runOnMainThread:^{
                completionHandler(RadarStatusErrorBadRequest, nil, nil, RadarAddressVerificationStatusNone);
            }];
        }

        return;
    } else {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"countryCode" value:address.countryCode]];
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"stateCode" value:address.stateCode]];
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"city" value:address.city]];
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"number" value:address.number]];
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"postalCode" value:address.postalCode]];
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"street" value:address.street]];
    }

    if (address.unit) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"unit" value:address.unit]];
    }

    NSURLComponents *url = [[NSURLComponents alloc] initWithString:@"v1/addresses/validate"];
    [url setQueryItems:queryString];
    
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil, RadarAddressVerificationStatusNone);
                        }

                        id addressObj = res[@"address"];
                        id resultObj = res[@"result"];
                        if (!addressObj || !resultObj) {
                            return completionHandler(RadarStatusErrorServer, nil, nil, RadarAddressVerificationStatusNone);
                        }

                        RadarAddress *address = [[RadarAddress alloc] initWithObject:addressObj];

                        NSDictionary *result = res[@"result"];
                        if (result[@"verificationStatus"]) {
                            RadarAddressVerificationStatus verificationStatus = [RadarAddress addressVerificationStatusForString:result[@"verificationStatus"]];

                            if (completionHandler) {
                                [RadarUtils runOnMainThread:^{
                                    completionHandler(RadarStatusSuccess, res, address, verificationStatus);
                                }];
                            }
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil, RadarAddressVerificationStatusNone);
                    }];
}

- (void)geocodeAddress:(NSString *)query 
                layers:(NSArray<NSString *> *_Nullable)layers
             countries:(NSArray<NSString *> *_Nullable)countries
     completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"query" value:query]];
    if (layers && layers.count > 0) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"layers" value:[layers componentsJoinedByString:@","]]];
    }
    if (countries && countries.count > 0) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"country" value:[countries componentsJoinedByString:@","]]];
    }
    
    NSURLComponents *url = [[NSURLComponents alloc] initWithString:@"v1/geocode/forward"];
    [url setQueryItems:queryString];
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id addressesObj = res[@"addresses"];
                        NSArray<RadarAddress *> *addresses = [RadarAddress addressesFromObject:addressesObj];
                        if (addresses) {
                            return completionHandler(RadarStatusSuccess, res, addresses);
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil);
                    }];
}

- (void)reverseGeocodeLocation:(CLLocation *)location 
                        layers:(NSArray<NSString *> *_Nullable)layers
             completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"coordinates"
                                                       value:[NSString stringWithFormat:@"%.06f,%.06f", location.coordinate.latitude, location.coordinate.longitude]]];
    if (layers && layers.count > 0) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"layers" value:[layers componentsJoinedByString:@","]]];
    }

    NSURLComponents *url = [[NSURLComponents alloc] initWithString:@"v1/geocode/reverse"];
    [url setQueryItems:queryString];
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id addressesObj = res[@"addresses"];
                        NSArray<RadarAddress *> *addresses = [RadarAddress addressesFromObject:addressesObj];
                        if (addresses) {
                            return completionHandler(RadarStatusSuccess, res, addresses);
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil);
                    }];
}

- (void)ipGeocodeWithCompletionHandler:(RadarIPGeocodeAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil, NO);
    }

    NSString *url = @"v1/geocode/ip";

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil, NO);
                        }

                        id addressObj = res[@"address"];
                        RadarAddress *address = [[RadarAddress alloc] initWithObject:addressObj];
                        id proxyObj = res[@"proxy"];
                        BOOL proxy = NO;
                        if ([proxyObj isKindOfClass:[NSNumber class]]) {
                            NSNumber *proxyNumber = (NSNumber *)proxyObj;
                            proxy = [proxyNumber boolValue];
                        }

                        if (address) {
                            return completionHandler(RadarStatusSuccess, res, address, proxy);
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil, NO);
                    }];
}

- (void)getDistanceFromOrigin:(CLLocation *)origin
                  destination:(CLLocation *)destination
                        modes:(RadarRouteMode)modes
                        units:(RadarRouteUnits)units
               geometryPoints:(int)geometryPoints
            completionHandler:(RadarDistanceAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"origin" value:[NSString stringWithFormat:@"%.06f,%.06f", origin.coordinate.latitude, origin.coordinate.longitude]]];
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"destination" value:[NSString stringWithFormat:@"%.06f,%.06f", destination.coordinate.latitude, destination.coordinate.longitude]]];
    NSMutableArray<NSString *> *modesArr = [NSMutableArray array];
    if (modes & RadarRouteModeFoot) {
        [modesArr addObject:@"foot"];
    }
    if (modes & RadarRouteModeBike) {
        [modesArr addObject:@"bike"];
    }
    if (modes & RadarRouteModeCar) {
        [modesArr addObject:@"car"];
    }
    if (modes & RadarRouteModeTruck) {
        [modesArr addObject:@"truck"];
    }
    if (modes & RadarRouteModeMotorbike) {
        [modesArr addObject:@"motorbike"];
    }
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"modes" value:[modesArr componentsJoinedByString:@","]]];
    NSString *unitsStr;
    if (units == RadarRouteUnitsMetric) {
        unitsStr = @"metric";
    } else {
        unitsStr = @"imperial";
    }
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"units" value:unitsStr]];
    if (geometryPoints > 1) {
        [queryString addObject:[NSURLQueryItem queryItemWithName:@"geometryPoints" value:@(geometryPoints).stringValue]];
    }
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"&geometry" value:@"linestring"]];

    NSURLComponents *url = [[NSURLComponents alloc] initWithString:@"v1/route/distance"];
    [url setQueryItems:queryString];
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id routesObj = res[@"routes"];
                        RadarRoutes *routes = [[RadarRoutes alloc] initWithObject:routesObj];
                        if (routes) {
                            return completionHandler(RadarStatusSuccess, res, routes);
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil);
                    }];
}

- (void)getMatrixFromOrigins:(NSArray<CLLocation *> *)origins
                destinations:(NSArray<CLLocation *> *)destinations
                        mode:(RadarRouteMode)mode
                       units:(RadarRouteUnits)units
           completionHandler:(RadarMatrixAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableArray *queryString = [[NSMutableArray alloc] init];
    
    NSMutableArray *originsString = [[NSMutableArray alloc] init];
    for (int i = 0; i < origins.count; i++) {
        [originsString addObject:[NSString stringWithFormat:@"%.06f,%.06f", origins[i].coordinate.latitude, origins[i].coordinate.longitude]];
    }
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"origins" value:[originsString componentsJoinedByString:@"|"]]];
    
    NSMutableArray *destinationsString = [[NSMutableArray alloc] init];
    for (int i = 0; i < destinations.count; i++) {
        [destinationsString addObject:[NSString stringWithFormat:@"%.06f,%.06f", origins[i].coordinate.latitude, origins[i].coordinate.longitude]];
    }
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"destinations" value:[originsString componentsJoinedByString:@"|"]]];
    
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"mode" value:[Radar stringForMode:mode]]];
    NSString *unitsStr;
    if (units == RadarRouteUnitsMetric) {
        unitsStr = @"metric";
    } else {
        unitsStr = @"imperial";
    }
    [queryString addObject:[NSURLQueryItem queryItemWithName:@"units" value:unitsStr]];

    NSURLComponents *url = [[NSURLComponents alloc] initWithString:@"v1/route/matrix"];
    [url setQueryItems:queryString];
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url.string
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id matrixObj = res[@"matrix"];
                        RadarRouteMatrix *matrix = [[RadarRouteMatrix alloc] initWithObject:matrixObj];
                        if (matrix) {
                            return completionHandler(RadarStatusSuccess, res, matrix);
                        }

                        completionHandler(RadarStatusErrorServer, nil, nil);
                    }];
}

- (void)sendEvent:(NSString *)conversionName
     withMetadata:(NSDictionary *_Nullable)metadata
completionHandler:(RadarSendEventAPICompletionHandler _Nonnull)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"id"] = [RadarSettings _id];
    params[@"installId"] = [RadarSettings installId];
    params[@"userId"] = [RadarSettings userId];
    params[@"deviceId"] = [RadarUtils deviceId];

    params[@"type"] = conversionName;
    params[@"metadata"] = metadata;

    NSString *url = @"v1/events";
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"POST"
                                  url:url
                              headers:headers
                               params:params
                                sleep:NO
                           logPayload:YES
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            return completionHandler(status, nil, nil);
                        }

                        id eventObj = res[@"event"];
                        RadarEvent *customEvent = [[RadarEvent alloc] initWithObject:eventObj];

                        if (!customEvent) {
                            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"POST /events did not return a new event"];

                            return completionHandler(RadarStatusErrorServer, nil, nil);
                        }

                        return completionHandler(RadarStatusSuccess, res, customEvent);
                    }];
}

- (void)syncLogs:(NSArray<RadarLog *> *)logs completionHandler:(RadarSyncLogsAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey);
    }

    NSString *url = @"v1/logs";

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    NSMutableDictionary *params = [NSMutableDictionary new];

    params[@"id"] = [RadarSettings _id];
    params[@"installId"] = [RadarSettings installId];
    params[@"deviceId"] = [RadarUtils deviceId];
    NSString *sessionId = [RadarSettings sessionId];
    if (sessionId) {
        params[@"sessionId"] = sessionId;
    }
    NSArray *logsArray = [RadarLog arrayForLogs:logs];
    [params setValue:logsArray forKey:@"logs"];

    [self.apiHelper requestWithMethod:@"POST"
                                  url:url
                              headers:headers
                               params:params
                                sleep:NO
                           logPayload:NO // avoid logging the logging call
                      extendedTimeout:NO
                             verified:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        return completionHandler(status);
                    }];
}

@end
