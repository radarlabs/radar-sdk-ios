//
//  Radar.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"

#import "RadarAPIClient.h"
#import "RadarLogger.h"
#import "RadarLocationManager.h"
#import "RadarSettings.h"
#import "RadarState.h"

@implementation Radar

+ (id)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

+ (void)initializeWithPublishableKey:(NSString *)publishableKey {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Initializing"];
    
    [RadarSettings setPublishableKey:publishableKey];
    [[RadarAPIClient sharedInstance] getConfig];
}

+ (NSString * _Nullable)getPublishableKey {
    return [RadarSettings publishableKey];
}

+ (void)setUserId:(NSString *)userId {
    [RadarSettings setUserId:userId];
}

+ (NSString * _Nullable)getUserId {
    return [RadarSettings userId];
}

+ (void)setDescription:(NSString *)description {
    [RadarSettings setDescription:description];
}

+ (NSString * _Nullable)getDescription {
    return [RadarSettings _description];
}

+ (void)setMetadata:(NSDictionary *)metadata {
    [RadarSettings setMetadata:metadata];
}

+ (NSDictionary * _Nullable)getMetadata {
    return [RadarSettings metadata];
}

+ (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:completionHandler];
}

+ (void)trackOnceWithCompletionHandler:(RadarTrackCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation * _Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            if (completionHandler) {
                completionHandler(status, nil, nil, nil);
            }
            
            return;
        }
        
        [[RadarAPIClient sharedInstance] trackWithLocation:location stopped:stopped source:RadarLocationSourceForegroundLocation replayed:NO completionHandler:^(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarEvent *> * _Nullable events, RadarUser * _Nullable user) {
            if (completionHandler) {
                completionHandler(status, location, events, user);
            }
        }];
    }];
}

+ (void)trackOnceWithLocation:(CLLocation *)location
            completionHandler:(RadarTrackCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] trackWithLocation:location stopped:NO source:RadarLocationSourceManualLocation replayed:NO completionHandler:^(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarEvent *> * _Nullable events, RadarUser * _Nullable user) {
        if (completionHandler) {
            completionHandler(status, location, events, user);
        }
    }];
}

+ (void)startTracking {
    [[RadarLocationManager sharedInstance] startTrackingWithOptions:[RadarTrackingOptions efficient]];
}

+ (void)startTrackingWithOptions:(RadarTrackingOptions *)options {
    [[RadarLocationManager sharedInstance] startTrackingWithOptions:options];
}

+ (void)stopTracking {
    [[RadarLocationManager sharedInstance] stopTracking];
}

+ (BOOL)isTracking {
    return [RadarSettings tracking];
}

+ (RadarTrackingOptions *)getTrackingOptions {
    return [RadarSettings trackingOptions];
}

+ (void)setDelegate:(id<RadarDelegate>)delegate {
    [[RadarLocationManager sharedInstance] setDelegate:delegate];
    [[RadarAPIClient sharedInstance] setDelegate:delegate];
    [[RadarLogger sharedInstance] setDelegate:delegate];
}

+ (void)acceptEventId:(NSString *)eventId
      verifiedPlaceId:(NSString *)verifiedPlaceId {
    [[RadarAPIClient sharedInstance] verifyEventId:eventId verification:RadarEventVerificationAccept verifiedPlaceId:verifiedPlaceId];
}

+ (void)rejectEventId:(NSString *)eventId {
    [[RadarAPIClient sharedInstance] verifyEventId:eventId verification:RadarEventVerificationReject verifiedPlaceId:nil];
}

+ (void)searchPlacesWithRadius:(int)radius
                        chains:(NSArray * _Nullable)chains
                    categories:(NSArray * _Nullable)categories
                        groups:(NSArray * _Nullable)groups
                         limit:(int)limit
             completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation * _Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            return completionHandler(status, nil, nil);
        }
        
        [[RadarAPIClient sharedInstance] searchPlacesWithLocation:location radius:radius chains:chains categories:categories groups:groups limit:limit completionHandler:^(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarPlace *> * _Nullable places) {
            completionHandler(status, location, places);
        }];
    }];
}

+ (void)searchPlacesWithLocation:(CLLocation * _Nonnull)location
                          radius:(int)radius
                          chains:(NSArray * _Nullable)chains
                      categories:(NSArray * _Nullable)categories
                          groups:(NSArray * _Nullable)groups
                           limit:(int)limit
               completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] searchPlacesWithLocation:location radius:radius chains:chains categories:categories groups:groups limit:limit completionHandler:^(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarPlace *> * _Nullable places) {
        completionHandler(status, location, places);
    }];
}

+ (void)searchGeofencesWithRadius:(int)radius
                             tags:(NSArray * _Nullable)tags
                            limit:(int)limit
                completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation * _Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            return completionHandler(status, nil, nil);
        }
    
        [[RadarAPIClient sharedInstance] searchGeofencesWithLocation:location radius:radius tags:tags limit:limit completionHandler:^(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarGeofence *> * _Nullable geofences) {
            completionHandler(status, location, geofences);
        }];
    }];
}

+ (void)searchGeofencesWithLocation:(CLLocation * _Nonnull)location
                             radius:(int)radius
                               tags:(NSArray * _Nullable)tags
                              limit:(int)limit
                  completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] searchGeofencesWithLocation:location radius:radius tags:tags limit:limit completionHandler:^(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarGeofence *> * _Nullable geofences) {
        completionHandler(status, location, geofences);
    }];
}

+ (void)geocode:(NSString *)query completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] geocode:query completionHandler:^(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarAddress *> * _Nullable addresses) {
        completionHandler(status, res, addresses);
    }];
}

+ (void)reverseGeocode:(CLLocation *)location completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] reverseGeocode:location completionHandler:^(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarAddress *> * _Nullable addresses) {
        completionHandler(status, res, addresses);
    }];
}

+ (void)ipGeocode:(RadarIPGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] ipGeocode:^(RadarStatus status, NSDictionary * _Nullable res, RadarRegion * _Nullable region) {
        completionHandler(status, res, region);
    }];
}

+ (void)setLogLevel:(RadarLogLevel)level {
    [RadarSettings setLogLevel:level];
}

+ (NSString *)stringForStatus:(RadarStatus)status {
    NSString *str;
    switch(status) {
        case RadarStatusSuccess:
            str = @"success";
            break;
        case RadarStatusErrorPublishableKey:
            str = @"errorPublishableKey";
            break;
        case RadarStatusErrorPermissions:
            str = @"errorPermissions";
            break;
        case RadarStatusErrorLocation:
            str = @"errorLocation";
            break;
        case RadarStatusErrorNetwork:
            str = @"errorNetwork";
            break;
        case RadarStatusErrorUnauthorized:
            str = @"errorUnauthorized";
            break;
        case RadarStatusErrorRateLimit:
            str = @"errorRateLimit";
            break;
        case RadarStatusErrorServer:
            str = @"errorServer";
            break;
        default:
            str = @"errorUnknown";
    }
    return str;
}

+ (NSString *)stringForSource:(RadarLocationSource)source {
    NSString *str;
    switch(source) {
        case RadarLocationSourceForegroundLocation:
            str = @"foregroundLocation";
            break;
        case RadarLocationSourceBackgroundLocation:
            str = @"backgroundLocation";
            break;
        case RadarLocationSourceGeofenceEnter:
            str = @"geofenceEnter";
            break;
        case RadarLocationSourceGeofenceExit:
            str = @"geofenceExit";
            break;
        case RadarLocationSourceVisitArrival:
            str = @"visitArrival";
            break;
        case RadarLocationSourceVisitDeparture:
            str = @"visitDeparture";
            break;
        default:
            str = nil;
    }
    return str;
}

@end
