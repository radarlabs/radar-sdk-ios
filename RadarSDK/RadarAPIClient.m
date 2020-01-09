//
//  RadarAPIClient.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAPIClient.h"

#import "RadarAddress+Internal.h"
#import "RadarEvent+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarRegion+Internal.h"
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
    [queryString appendFormat:@"&deviceId=%@", [RadarUtils deviceId]];
    [queryString appendFormat:@"&deviceType=%@", [RadarUtils deviceType]];
    [queryString appendFormat:@"&deviceMake=%@", [RadarUtils deviceMake]];
    [queryString appendFormat:@"&sdkVersion=%@", [RadarUtils sdkVersion]];
    NSString *deviceModel = [RadarUtils deviceModel];
    if (deviceModel) {
        [queryString appendFormat:@"&deviceModel=%@", deviceModel];
    }
    NSString *deviceOS = [RadarUtils deviceOS];
    if (deviceOS) {
        [queryString appendFormat:@"&deviceOS=%@", deviceOS];
    }
    
    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/config?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSDictionary *headers = @{
        @"Authorization": publishableKey,
        @"Content-Type": @"application/json",
        @"User-Agent": [RadarUtils userAgent],
        @"X-Radar-Config": @"true",
    };
    
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
    params[@"accuracy"] = @(location.horizontalAccuracy);
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
    NSString *deviceModel = [RadarUtils deviceModel];
    if (deviceModel) {
        params[@"deviceModel"] = deviceModel;
    }
    NSString *deviceOS = [RadarUtils deviceOS];
    if (deviceOS) {
        params[@"deviceOS"] = deviceOS;
    }
    NSString *country = [RadarUtils country];
    if (country) {
        params[@"country"] = country;
    }
    NSNumber *timeZoneOffset = [RadarUtils timeZoneOffset];
    if (timeZoneOffset) {
        params[@"timeZoneOffset"] = timeZoneOffset;
    }
    NSString *uaChannelId = [RadarUtils uaChannelId];
    if (uaChannelId) {
        params[@"uaChannelId"] = uaChannelId;
    }
    NSString *uaNamedUserId = [RadarUtils uaNamedUserId];
    if (uaNamedUserId) {
        params[@"uaNamedUserId"] = uaNamedUserId;
    }
    NSString *uaSessionId = [RadarUtils uaSessionId];
    if (uaSessionId) {
        params[@"uaSessionId"] = uaSessionId;
    }
    params[@"source"] = [Radar stringForSource:source];
    
    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/track", host];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSDictionary *headers = @{
        @"Authorization": publishableKey,
        @"Content-Type": @"application/json",
        @"User-Agent": [RadarUtils userAgent],
        @"X-Radar-Config": @"true",
    };
    
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
    params[@"deviceType"] = [RadarUtils deviceType];
    params[@"deviceMake"] = [RadarUtils deviceMake];
    params[@"sdkVersion"] = [RadarUtils sdkVersion];
    NSString *deviceModel = [RadarUtils deviceModel];
    if (deviceModel) {
        params[@"deviceModel"] = deviceModel;
    }
    NSString *deviceOS = [RadarUtils deviceOS];
    if (deviceOS) {
        params[@"deviceOS"] = deviceOS;
    }
    
    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/events/%@/verification", host, eventId];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSDictionary *headers = @{
        @"Authorization": publishableKey,
        @"Content-Type": @"application/json",
        @"User-Agent": [RadarUtils userAgent],
    };
    
    [self.apiHelper requestWithMethod:@"PUT" url:url headers:headers params:params completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
        
    }];
}

- (void)searchPlacesWithLocation:(CLLocation * _Nonnull)location
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
    [queryString appendFormat:@"latitude=%.15f", location.coordinate.latitude];
    [queryString appendFormat:@"&longitude=%.15f", location.coordinate.longitude];
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
    [queryString appendFormat:@"&deviceType=%@", [RadarUtils deviceType]];
    [queryString appendFormat:@"&deviceMake=%@", [RadarUtils deviceMake]];
    [queryString appendFormat:@"&sdkVersion=%@", [RadarUtils sdkVersion]];
    NSString *deviceModel = [RadarUtils deviceModel];
    if (deviceModel) {
        [queryString appendFormat:@"&deviceModel=%@", deviceModel];
    }
    NSString *deviceOS = [RadarUtils deviceOS];
    if (deviceOS) {
        [queryString appendFormat:@"&deviceOS=%@", deviceOS];
    }
    
    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/search/places?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSDictionary *headers = @{
        @"Authorization": publishableKey,
        @"Content-Type": @"application/json",
        @"User-Agent": [RadarUtils userAgent],
        @"X-Radar-Config": @"true",
    };
    
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

- (void)searchGeofencesWithLocation:(CLLocation * _Nonnull)location
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
    [queryString appendFormat:@"latitude=%.15f", location.coordinate.latitude];
    [queryString appendFormat:@"&longitude=%.15f", location.coordinate.longitude];
    [queryString appendFormat:@"&radius=%d", radius];
    [queryString appendFormat:@"&limit=%d", finalLimit];
    if (tags && [tags count] > 0) {
        [queryString appendFormat:@"&tags=%@", [tags componentsJoinedByString:@","]];
    }
    [queryString appendFormat:@"&deviceType=%@", [RadarUtils deviceType]];
    [queryString appendFormat:@"&deviceMake=%@", [RadarUtils deviceMake]];
    [queryString appendFormat:@"&sdkVersion=%@", [RadarUtils sdkVersion]];
    NSString *deviceModel = [RadarUtils deviceModel];
    if (deviceModel) {
        [queryString appendFormat:@"&deviceModel=%@", deviceModel];
    }
    NSString *deviceOS = [RadarUtils deviceOS];
    if (deviceOS) {
        [queryString appendFormat:@"&deviceOS=%@", deviceOS];
    }

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/search/geofences?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = @{
        @"Authorization": publishableKey,
        @"Content-Type": @"application/json",
        @"User-Agent": [RadarUtils userAgent],
        @"X-Radar-Config": @"true",
    };

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

    NSDictionary *headers = @{
        @"Authorization": publishableKey,
        @"Content-Type": @"application/json",
        @"User-Agent": [RadarUtils userAgent],
        @"X-Radar-Config": @"true",
    };

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
    [queryString appendFormat:@"latitude=%.15f", location.coordinate.latitude];
    [queryString appendFormat:@"&longitude=%.15f", location.coordinate.longitude];

    NSString *host = [RadarSettings host];
    NSString *url = [NSString stringWithFormat:@"%@/v1/geocode/reverse?%@", host, queryString];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSDictionary *headers = @{
        @"Authorization": publishableKey,
        @"Content-Type": @"application/json",
        @"User-Agent": [RadarUtils userAgent],
        @"X-Radar-Config": @"true",
    };

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

    NSDictionary *headers = @{
        @"Authorization": publishableKey,
        @"Content-Type": @"application/json",
        @"User-Agent": [RadarUtils userAgent],
        @"X-Radar-Config": @"true",
    };

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

@end
