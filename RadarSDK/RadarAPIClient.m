//
//  RadarAPIClient.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAPIClient.h"

#import "RadarAddress+Internal.h"
#import "RadarContext+Internal.h"
#import "RadarEvent+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarRegion+Internal.h"
#import "RadarRoutes+Internal.h"
#import "RadarLogger.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarUser+Internal.h"
#import "RadarUtils.h"

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

- (void)getConfig {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return;
    }
    
    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"installId=%@", [RadarSettings installId]];
    NSString *userId = [RadarSettings userId];
    if (userId) {
        [queryString appendFormat:@"&userId=%@", userId];
    }
    NSString *deviceId = [RadarUtils deviceId];
    if (deviceId) {
        [queryString appendFormat:@"&deviceId=%@", userId];
    }
    
    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/config?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];
    
    [self.apiHelper requestWithMethod:@"GET" url:url headers:headers params:nil completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
        if (!res) {
            return;
        }
        
        id metaObj = res[@"meta"];
        if (metaObj && [metaObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *meta = (NSDictionary *)metaObj;
            id configObj = meta[@"config"];
            if (configObj && [configObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *config = (NSDictionary *)configObj;
                [RadarSettings setConfig:config];
            }
        }
    }];
}

- (void)trackWithLocation:(CLLocation * _Nonnull)location
                  stopped:(BOOL)stopped
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
        completionHandler:(RadarTrackAPICompletionHandler _Nullable)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil, nil);
    }
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"installId"] = [RadarSettings installId];
    params[@"id"] = [RadarSettings _id];
    params[@"userId"] = [RadarSettings userId];
    params[@"deviceId"] = [RadarUtils deviceId];
    params[@"description"] = [RadarSettings _description];
    params[@"metadata"] = [RadarSettings metadata];
    NSString *adId = [RadarUtils adId];
    if (adId && [RadarSettings adIdEnabled]) {
        params[@"adId"] = adId;
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
    params[@"course"] = @(location.course);
    if (location.floor) {
        params[@"floorLevel"] = @(location.floor.level);
    }
    BOOL foreground = [RadarUtils foreground];
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
    params[@"uaChannelId"] = [RadarUtils uaChannelId];
    params[@"uaNamedUserId"] = [RadarUtils uaNamedUserId];
    params[@"uaSessionId"] = [RadarUtils uaSessionId];
    params[@"source"] = [Radar stringForSource:source];
    
    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/track", host];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];
    
    [self.apiHelper requestWithMethod:@"POST" url:url headers:headers params:params completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
        if (status != RadarStatusSuccess || !res) {
            RadarTrackingOptions *options = [RadarSettings trackingOptions];
            if (options.replay == RadarTrackingOptionsReplayStops && stopped && !(source == RadarLocationSourceForegroundLocation || source == RadarLocationSourceManualLocation)) {
                [RadarState setLastFailedStoppedLocation:location];
            }
            
            if (self.delegate) {
                [self.delegate didFailWithStatus:status];
            }
            
            return completionHandler(status, nil, nil, nil);
        }
        
        [RadarState setLastFailedStoppedLocation:nil];
        
        id metaObj = res[@"meta"];
        if (metaObj && [metaObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *meta = (NSDictionary *)metaObj;
            id configObj = meta[@"config"];
            if (configObj && [configObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *config = (NSDictionary *)configObj;
                [RadarSettings setConfig:config];
            }
        }
        
        id eventsObj = res[@"events"];
        id userObj = res[@"user"];
        NSArray<RadarEvent *> *events = [RadarEvent eventsFromObject:eventsObj];
        RadarUser *user = [[RadarUser alloc] initWithObject:userObj];
        if (events && user) {
            if (self.delegate) {
                if (location) {
                    [self.delegate didUpdateLocation:location user:user];
                }
                
                if (events.count) {
                    [self.delegate didReceiveEvents:events user:user];
                }
            }
            
            return completionHandler(RadarStatusSuccess, res, events, user);
        }
        
        if (self.delegate) {
            [self.delegate didFailWithStatus:status];
        }
        
        completionHandler(RadarStatusErrorServer, nil, nil, nil);
    }];
}

- (void)verifyEventId:(NSString *)eventId
         verification:(RadarEventVerification)verification
      verifiedPlaceId:(NSString *)verifiedPlaceId {
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
    
    [self.apiHelper requestWithMethod:@"PUT" url:url headers:headers params:params completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
        
    }];
}

- (void)getContextForLocation:(CLLocation * _Nonnull)location
            completionHandler:(RadarContextAPICompletionHandler _Nullable)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"coordinates=%.06f,%.06f", location.coordinate.latitude, location.coordinate.longitude];

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/context?%@", host, queryString];
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET" url:url headers:headers params:nil completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
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

- (void)searchPlacesNear:(CLLocation * _Nonnull)near
                  radius:(int)radius
                  chains:(NSArray * _Nullable)chains
              categories:(NSArray * _Nullable)categories
                  groups:(NSArray * _Nullable)groups
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
    
    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/search/places?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];
    
    [self.apiHelper requestWithMethod:@"GET" url:url headers:headers params:nil completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
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

- (void)searchGeofencesNear:(CLLocation * _Nonnull)near
                     radius:(int)radius
                       tags:(NSArray * _Nullable)tags
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

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/search/geofences?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET" url:url headers:headers params:nil completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
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

- (void)autocompleteQuery:(NSString *)query
                     near:(CLLocation * _Nonnull)near
                    limit:(int)limit
        completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
    NSString *publishableKey = [RadarSettings publishableKey];
    if (!publishableKey) {
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }
    
    int finalLimit = MIN(limit, 100);
    
    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"query=%@", query];
    [queryString appendFormat:@"&near=%.06f,%.06f", near.coordinate.latitude, near.coordinate.longitude];
    [queryString appendFormat:@"&limit=%d", finalLimit];
    
    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/search/autocomplete?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET" url:url headers:headers params:nil completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
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

- (void)geocodeAddress:(NSString *)query
     completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
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

    [self.apiHelper requestWithMethod:@"GET" url:url headers:headers params:nil completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
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
             completionHandler:(RadarGeocodeAPICompletionHandler)completionHandler {
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

    [self.apiHelper requestWithMethod:@"GET" url:url headers:headers params:nil completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
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
        return completionHandler(RadarStatusErrorPublishableKey, nil, nil);
    }

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/geocode/ip", host];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET" url:url headers:headers params:nil completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
        if (status != RadarStatusSuccess || !res) {
            return completionHandler(status, nil, nil);
        }

        id countryObj = res[@"country"];
        RadarRegion *country = [[RadarRegion alloc]  initWithObject:countryObj];

        if (country) {
            return completionHandler(RadarStatusSuccess, res, country);
        }

        completionHandler(RadarStatusErrorServer, nil, nil);
    }];
}

- (void)getDistanceFromOrigin:(CLLocation *)origin
                  destination:(CLLocation *)destination
                        modes:(RadarRouteMode)modes
                        units:(RadarRouteUnits)units
            completionHandler:(RadarRouteAPICompletionHandler)completionHandler {
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
    if (modes & RadarRouteModeTransit) {
        [modesArr addObject:@"transit"];
    }
    [queryString appendFormat:@"&modes=%@", [modesArr componentsJoinedByString:@","]];
    NSString *unitsStr;
    if (units == RadarRouteUnitsMetric) {
        unitsStr = @"metric";
    } else {
        unitsStr = @"imperial";
    }
    [queryString appendFormat:@"&units=%@", unitsStr];
    
    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/route/distance?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = [RadarAPIClient headersWithPublishableKey:publishableKey];

    [self.apiHelper requestWithMethod:@"GET" url:url headers:headers params:nil completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
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

@end
