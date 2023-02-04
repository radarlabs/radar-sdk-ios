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
#import "RadarContext+Internal.h"
#import "RadarCoordinate+Internal.h"
#import "RadarDelegateHolder.h"
#import "RadarEvent+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarLocationManager.h"
#import "RadarLogger.h"
#import "RadarMeta+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarRouteMatrix+Internal.h"
#import "RadarRoutes+Internal.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarTrip+Internal.h"
#import "RadarTripOptions.h"
#import "RadarUser+Internal.h"
#import "RadarUtils.h"
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
    return @{
        @"Authorization": publishableKey,
        @"Content-Type": @"application/json",
        @"X-Radar-Config": @"true",
        @"X-Radar-Device-Make": [RadarUtils deviceMake],
        @"X-Radar-Device-Model": [RadarUtils deviceModel],
        @"X-Radar-Device-OS": [RadarUtils deviceOS],
        @"X-Radar-Device-Type": [RadarUtils deviceType],
        @"X-Radar-SDK-Version": [RadarUtils sdkVersion]
    };
}

+ (RadarMeta *_Nullable)parseMeta:(NSDictionary *_Nullable)res {
    if (!res) {
        return nil;
    }

    id metaObj = res[@"meta"];
    if (!metaObj || ![metaObj isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *meta = (NSDictionary *)metaObj;
    return [RadarMeta metaFromDictionary:meta];
}

- (void)getConfig:(NSString *_Nullable)usage
completionHandler:(RadarConfigAPICompletionHandler _Nonnull)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return;
    }

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"installId=%@", [RadarSettings installId]];
    [queryString appendFormat:@"&sessionId=%@", [RadarSettings sessionId]];
    NSString *locationAuthorization = [RadarUtils locationAuthorization];
    if (locationAuthorization) {
        [queryString appendFormat:@"&locationAuthorization=%@", locationAuthorization];
    }
    NSString *locationAccuracyAuthorization = [RadarUtils locationAccuracyAuthorization];
    if (locationAccuracyAuthorization) {
        [queryString appendFormat:@"&locationAccuracyAuthorization=%@", locationAccuracyAuthorization];
    }
    if (usage) {
        [queryString appendFormat:@"&usage=%@", usage];
    }

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/config?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (!res) {
                            return;
                        }

                        [Radar flushLogs];

                        RadarMeta *meta = [RadarAPIClient parseMeta:res];
                        completionHandler(status, meta);
                    }];
}

- (void)trackWithLocation:(CLLocation *_Nonnull)location
                  stopped:(BOOL)stopped
               foreground:(BOOL)foreground
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
                  beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
        completionHandler:(RadarTrackAPICompletionHandler _Nonnull)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil, nil, nil, nil);
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
        NSString *adId = [RadarUtils adId];
        if (adId && [RadarSettings adIdEnabled]) {
            params[@"adId"] = adId;
        }
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
    if (!foreground) {
        long timeInMs = (long)(location.timestamp.timeIntervalSince1970 * 1000);
        long nowMs = (long)([NSDate date].timeIntervalSince1970 * 1000);
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
    if (@available(iOS 15.0, *)) {
        CLLocationSourceInformation *sourceInformation = location.sourceInformation;
        if (sourceInformation) {
            if (sourceInformation.isSimulatedBySoftware) {
                params[@"mocked"] = @(YES);
            } else {
                params[@"mocked"] = @(NO);
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

    // NOTE: this is sent up for debugging purposes and can be seen
    // in the locations debug page for a user
    params[@"trackingOptions"] = [options dictionaryValue];

    // NOTE: this is sent up for measuring number of clients set on
    // remote tracking options
    BOOL usingRemoteTrackingOptions = RadarSettings.tracking && RadarSettings.remoteTrackingOptions;
    params[@"usingRemoteTrackingOptions"] = @(usingRemoteTrackingOptions);

    if (anonymous) {
        NSString *const usage = @"track";
        [[RadarAPIClient sharedInstance] getConfig:usage
                                 completionHandler:^(RadarStatus status, RadarMeta *_Nullable meta) {
        }];
    }

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/track", host];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"POST"
                                  url:url
                              headers:headers
                               params:params
                                sleep:YES
                           logPayload:YES
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        if (status != RadarStatusSuccess || !res) {
                            if (options.replay == RadarTrackingOptionsReplayStops && stopped &&
                                !(source == RadarLocationSourceForegroundLocation || source == RadarLocationSourceManualLocation)) {
                                [RadarState setLastFailedStoppedLocation:location];
                            }

                            [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];

                            return completionHandler(status, nil, nil, nil, nil, nil);
                        }

                        [Radar flushLogs];
                        [RadarState setLastFailedStoppedLocation:nil];

                        RadarMeta *_Nullable meta = [RadarAPIClient parseMeta:res];

                        id eventsObj = res[@"events"];
                        id userObj = res[@"user"];
                        id nearbyGeofencesObj = res[@"nearbyGeofences"];
                        NSArray<RadarEvent *> *events = [RadarEvent eventsFromObject:eventsObj];
                        RadarUser *user = [[RadarUser alloc] initWithObject:userObj];
                        NSArray<RadarGeofence *> *nearbyGeofences = [RadarGeofence geofencesFromObject:nearbyGeofencesObj];
        
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
                            
                            // if user was on a trip that ended server side, restore previous tracking options
                            if (!user.trip && [RadarSettings tripOptions]) {
                                [[RadarLocationManager sharedInstance] restartPreviousTrackingOptions];
                                [RadarSettings setTripOptions:nil];
                            }

                            if (location) {
                                [[RadarDelegateHolder sharedInstance] didUpdateLocation:location user:user];
                            }

                            if (events.count) {
                                [[RadarDelegateHolder sharedInstance] didReceiveEvents:events user:user];
                            }

                            return completionHandler(RadarStatusSuccess, res, events, user, nearbyGeofences, meta);
                        }

                        [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];

                        completionHandler(RadarStatusErrorServer, nil, nil, nil, nil, nil);
                    }];
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

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/events/%@/verification", host, eventId];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"PUT"
                                  url:url
                              headers:headers
                               params:params
                                sleep:NO
                           logPayload:YES
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res){

                    }];
}

#pragma mark - Trips

- (void)createTripWithOptions:(RadarTripOptions *)options
            completionHandler:(RadarTripAPICompletionHandler)completionHandler {
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

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/trips", host];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"POST"
                                  url:url
                              headers:headers
                               params:params
                                sleep:NO
                           logPayload:YES
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
    // don't pass the externalId like createTrip() does.

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

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/trips/%@/update", host, options.externalId];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"PATCH"
                                  url:url
                              headers:headers
                               params:params
                                sleep:NO
                           logPayload:YES
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

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"coordinates=%.06f,%.06f", location.coordinate.latitude, location.coordinate.longitude];

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/context?%@", host, queryString];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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

    int finalLimit = MIN(limit, 100);

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"near=%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude];
    [queryString appendFormat:@"&radius=%d", radius];
    [queryString appendFormat:@"&limit=%d", finalLimit];
    if (chains && [chains count] > 0) {
        [queryString appendFormat:@"&chains=%@", [chains componentsJoinedByString:@","]];
    }
    if (categories && [categories count] > 0) {
        [queryString appendFormat:@"&categories=%@", [categories componentsJoinedByString:@","]];
    }
    if (groups && [groups count] > 0) {
        [queryString appendFormat:@"&groups=%@", [groups componentsJoinedByString:@","]];
    }

    [chainMetadata enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        [queryString appendFormat:@"&chainMetadata[%@]=\"%@\"", key, value];
    }];

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/search/places?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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
          completionHandler:(RadarSearchGeofencesAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    int finalLimit = MIN(limit, 100);

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"near=%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude];
    [queryString appendFormat:@"&radius=%d", radius];
    [queryString appendFormat:@"&limit=%d", finalLimit];
    if (tags && [tags count] > 0) {
        [queryString appendFormat:@"&tags=%@", [tags componentsJoinedByString:@","]];
    }
    if (metadata && [metadata count] > 0) {
        for (NSString *key in metadata) {
            [queryString appendFormat:@"&metadata[%@]=%@", key, metadata[key]];
        }
    }

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/search/geofences?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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

    int finalLimit = MIN(limit, 100);

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"near=%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude];
    [queryString appendFormat:@"&radius=%d", radius];
    [queryString appendFormat:@"&limit=%d", finalLimit];

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/search/beacons?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];
    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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
        completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    int finalLimit = MIN(limit, 100);

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"query=%@", query];
    if (near) {
        [queryString appendFormat:@"&near=%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude];
    }
    if (layers && layers.count > 0) {
        [queryString appendFormat:@"&layers=%@", [layers componentsJoinedByString:@","]];
    }
    if (limit) {
        [queryString appendFormat:@"&limit=%d", finalLimit];
    }
    if (country) {
        [queryString appendFormat:@"&country=%@", country];
    }

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/search/autocomplete?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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

- (void)autocompleteQuery:(NSString *)query near:(CLLocation *_Nullable)near limit:(int)limit completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    int finalLimit = MIN(limit, 100);

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"query=%@", query];
    if (near) {
        [queryString appendFormat:@"&near=%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude];
    }
    if (limit) {
        [queryString appendFormat:@"&limit=%d", finalLimit];
    }

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/search/autocomplete?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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

- (void)geocodeAddress:(NSString *)query completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"query=%@", query];

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/geocode/forward?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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

- (void)reverseGeocodeLocation:(CLLocation *)location completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"coordinates=%.06f,%.06f", location.coordinate.latitude, location.coordinate.longitude];

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/geocode/reverse?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/geocode/ip", host];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"origin=%.06f,%.06f", origin.coordinate.latitude, origin.coordinate.longitude];
    [queryString appendFormat:@"&destination=%.06f,%.06f", destination.coordinate.latitude, destination.coordinate.longitude];
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
    [queryString appendFormat:@"&modes=%@", [modesArr componentsJoinedByString:@","]];
    NSString *unitsStr;
    if (units == RadarRouteUnitsMetric) {
        unitsStr = @"metric";
    } else {
        unitsStr = @"imperial";
    }
    [queryString appendFormat:@"&units=%@", unitsStr];
    if (geometryPoints > 1) {
        [queryString appendFormat:@"&geometryPoints=%d", geometryPoints];
    }
    [queryString appendString:@"&geometry=linestring"];

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/route/distance?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendString:@"origins="];
    for (int i = 0; i < origins.count; i++) {
        CLLocation *origin = origins[i];
        [queryString appendFormat:@"%.06f,%.06f", origin.coordinate.latitude, origin.coordinate.longitude];
        if (i < origins.count - 1) {
            [queryString appendString:@"|"];
        }
    }
    [queryString appendString:@"&destinations="];
    for (int i = 0; i < destinations.count; i++) {
        CLLocation *destination = destinations[i];
        [queryString appendFormat:@"%.06f,%.06f", destination.coordinate.latitude, destination.coordinate.longitude];
        if (i < destinations.count - 1) {
            [queryString appendString:@"|"];
        }
    }
    NSString *modeStr;
    if (mode == RadarRouteModeFoot) {
        modeStr = @"foot";
    } else if (mode == RadarRouteModeBike) {
        modeStr = @"bike";
    } else if (mode == RadarRouteModeCar) {
        modeStr = @"car";
    } else if (mode == RadarRouteModeTruck) {
        modeStr = @"truck";
    } else if (mode == RadarRouteModeMotorbike) {
        modeStr = @"motorbike";
    }
    [queryString appendFormat:@"&mode=%@", modeStr];
    NSString *unitsStr;
    if (units == RadarRouteUnitsMetric) {
        unitsStr = @"metric";
    } else {
        unitsStr = @"imperial";
    }
    [queryString appendFormat:@"&units=%@", unitsStr];

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/route/matrix?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET"
                                  url:url
                              headers:headers
                               params:nil
                                sleep:NO
                           logPayload:YES
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

- (void)sendEvent:(NSString *)customType
     withMetadata:(NSDictionary *_Nullable)metadata
             user:(RadarUser *_Nullable)user
      trackEvents:(NSArray<RadarEvent *> *_Nullable)trackEvents
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

    params[@"type"] = customType;
    params[@"metadata"] = metadata;

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/events", host];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"POST"
                                  url:url
                              headers:headers
                               params:params
                                sleep:NO
                           logPayload:YES
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
        if (status != RadarStatusSuccess || !res) {
            return completionHandler(status, nil, nil);
        }

        id eventObj = res[@"event"];
        RadarEvent *customEvent = [[RadarEvent alloc] initWithObject:eventObj];

        if (!customEvent) {
            // If the server didn't send back an event, then there was a
            // problem.
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError
                                               message:@"POST /events did not return a new event"];

            return completionHandler(RadarStatusErrorServer, nil, nil);
        } else {
            // construct the array of events to return in the callback - custom event at index 0, followed by track events
            NSMutableArray *finalEvents;
            if (trackEvents.count > 0) {
                finalEvents = [NSMutableArray arrayWithArray:trackEvents];
                [finalEvents insertObject:customEvent atIndex:0];
            } else {
                finalEvents = [NSMutableArray arrayWithObject:customEvent];
            }

            // The events are returned in the completion handler, but they're
            // also sent back via the RadarDelegate, just like
            // -updateTripWithOptions:status:completionHandler: does.
            [[RadarDelegateHolder sharedInstance] didReceiveEvents:finalEvents user:user];

            return completionHandler(RadarStatusSuccess, res, finalEvents);
        }
    }];
}

- (void)syncLogs:(NSArray<RadarLog *> *)logs completionHandler:(RadarSyncLogsAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey);
    }

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/logs", host];

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

    // "logPayload = false" enforces "don't log the logging call".
    // Otherwise, all log entries would continue to coalesce and would never fully clear from the buffer.
    [self.apiHelper requestWithMethod:@"POST"
                                  url:url
                              headers:headers
                               params:params
                                sleep:NO
                           logPayload:NO
                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res) {
                        return completionHandler(status);
                    }];
}

@end
