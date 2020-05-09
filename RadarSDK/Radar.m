//
//  Radar.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"

#import "RadarAPIClient.h"
#import "RadarCoordinate+Internal.h"
#import "RadarLocationManager.h"
#import "RadarLogger.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarUtils.h"

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
    [[RadarLocationManager sharedInstance] updateTracking];
}

+ (NSString *_Nullable)getPublishableKey {
    return [RadarSettings publishableKey];
}

+ (void)setUserId:(NSString *)userId {
    [RadarSettings setUserId:userId];
}

+ (NSString *_Nullable)getUserId {
    return [RadarSettings userId];
}

+ (void)setDescription:(NSString *)description {
    [RadarSettings setDescription:description];
}

+ (NSString *_Nullable)getDescription {
    return [RadarSettings _description];
}

+ (void)setMetadata:(NSDictionary *)metadata {
    [RadarSettings setMetadata:metadata];
}

+ (NSDictionary *_Nullable)getMetadata {
    return [RadarSettings metadata];
}

+ (void)setAdIdEnabled:(BOOL)enabled {
    [RadarSettings setAdIdEnabled:enabled];
}

+ (void)getLocationWithCompletionHandler:(RadarLocationCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:completionHandler];
}

+ (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarLocationCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithDesiredAccuracy:desiredAccuracy completionHandler:completionHandler];
}

+ (void)trackOnceWithCompletionHandler:(RadarTrackCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            if (completionHandler) {
                completionHandler(status, nil, nil, nil);
            }

            return;
        }

        [[RadarAPIClient sharedInstance] trackWithLocation:location
                                                   stopped:stopped
                                                foreground:YES
                                                    source:RadarLocationSourceForegroundLocation
                                                  replayed:NO
                                         completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user) {
                                             if (completionHandler) {
                                                 completionHandler(status, location, events, user);
                                             }
                                         }];
    }];
}

+ (void)trackOnceWithLocation:(CLLocation *)location completionHandler:(RadarTrackCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] trackWithLocation:location
                                               stopped:NO
                                            foreground:YES
                                                source:RadarLocationSourceManualLocation
                                              replayed:NO
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user) {
                                         if (completionHandler) {
                                             completionHandler(status, location, events, user);
                                         }
                                     }];
}

+ (void)startTrackingWithOptions:(RadarTrackingOptions *)options {
    [[RadarLocationManager sharedInstance] startTrackingWithOptions:options];
}

+ (void)mockTrackingWithOrigin:(CLLocation *)origin
                   destination:(CLLocation *)destination
                          mode:(RadarRouteMode)mode
                        points:(int)points
                      interval:(NSTimeInterval)interval
             completionHandler:(RadarTrackCompletionHandler _Nullable)completionHandler {
    [[RadarAPIClient sharedInstance] getMockFromOrigin:origin
                                           destination:destination
                                                  mode:mode
                                                points:points
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarCoordinate *> *_Nullable coordinates) {
                                         if (status != RadarStatusSuccess || !coordinates) {
                                             if (completionHandler) {
                                                 completionHandler(status, nil, nil, nil);
                                             }

                                             return;
                                         }

                                         NSTimeInterval intervalLimit = interval;
                                         if (intervalLimit < 5) {
                                             intervalLimit = 5;
                                         } else if (intervalLimit > 60) {
                                             intervalLimit = 60;
                                         }

                                         for (int i = 0; i < coordinates.count; i++) {
                                             RadarCoordinate *coordinate = coordinates[i];
                                             __block CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate.coordinate
                                                                                                          altitude:-1
                                                                                                horizontalAccuracy:5
                                                                                                  verticalAccuracy:-1
                                                                                                         timestamp:[NSDate new]];
                                             __block BOOL stopped = (i == 0) || (i == coordinates.count - 1);

                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                 [[RadarAPIClient sharedInstance] trackWithLocation:location
                                                                                            stopped:stopped
                                                                                         foreground:NO
                                                                                             source:RadarLocationSourceMockLocation
                                                                                           replayed:NO
                                                                                  completionHandler:^(RadarStatus status, NSDictionary *_Nullable res,
                                                                                                      NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user) {
                                                                                      if (completionHandler) {
                                                                                          completionHandler(status, location, events, user);
                                                                                      }
                                                                                  }];
                                             });
                                         }
                                     }];
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

+ (void)acceptEventId:(NSString *)eventId verifiedPlaceId:(NSString *)verifiedPlaceId {
    [[RadarAPIClient sharedInstance] verifyEventId:eventId verification:RadarEventVerificationAccept verifiedPlaceId:verifiedPlaceId];
}

+ (void)rejectEventId:(NSString *)eventId {
    [[RadarAPIClient sharedInstance] verifyEventId:eventId verification:RadarEventVerificationReject verifiedPlaceId:nil];
}

+ (void)getContextWithCompletionHandler:(RadarContextCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            if (completionHandler) {
                return completionHandler(status, nil, nil);
            }
        }

        [[RadarAPIClient sharedInstance] getContextForLocation:location
                                             completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarContext *_Nullable context) {
                                                 if (completionHandler) {
                                                     completionHandler(status, location, context);
                                                 }
                                             }];
    }];
}

+ (void)getContextForLocation:(CLLocation *)location completionHandler:(RadarContextCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] getContextForLocation:location
                                         completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarContext *_Nullable context) {
                                             if (completionHandler) {
                                                 completionHandler(status, location, context);
                                             }
                                         }];
}

+ (void)searchPlacesWithRadius:(int)radius
                        chains:(NSArray *_Nullable)chains
                    categories:(NSArray *_Nullable)categories
                        groups:(NSArray *_Nullable)groups
                         limit:(int)limit
             completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            return completionHandler(status, nil, nil);
        }

        [[RadarAPIClient sharedInstance] searchPlacesNear:location
                                                   radius:radius
                                                   chains:chains
                                               categories:categories
                                                   groups:groups
                                                    limit:limit
                                        completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarPlace *> *_Nullable places) {
                                            completionHandler(status, location, places);
                                        }];
    }];
}

+ (void)searchPlacesNear:(CLLocation *_Nonnull)near
                  radius:(int)radius
                  chains:(NSArray *_Nullable)chains
              categories:(NSArray *_Nullable)categories
                  groups:(NSArray *_Nullable)groups
                   limit:(int)limit
       completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] searchPlacesNear:near
                                               radius:radius
                                               chains:chains
                                           categories:categories
                                               groups:groups
                                                limit:limit
                                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarPlace *> *_Nullable places) {
                                        completionHandler(status, near, places);
                                    }];
}

+ (void)searchGeofencesWithRadius:(int)radius tags:(NSArray *_Nullable)tags limit:(int)limit completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            return completionHandler(status, nil, nil);
        }

        [[RadarAPIClient sharedInstance] searchGeofencesNear:location
                                                      radius:radius
                                                        tags:tags
                                                       limit:limit
                                           completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarGeofence *> *_Nullable geofences) {
                                               completionHandler(status, location, geofences);
                                           }];
    }];
}

+ (void)searchGeofencesNear:(CLLocation *_Nonnull)near
                     radius:(int)radius
                       tags:(NSArray *_Nullable)tags
                      limit:(int)limit
          completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] searchGeofencesNear:near
                                                  radius:radius
                                                    tags:tags
                                                   limit:limit
                                       completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarGeofence *> *_Nullable geofences) {
                                           completionHandler(status, near, geofences);
                                       }];
}

+ (void)searchPointsWithRadius:(int)radius tags:(NSArray<NSString *> *)tags limit:(int)limit completionHandler:(RadarSearchPointsCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            return completionHandler(status, nil, nil);
        }

        [[RadarAPIClient sharedInstance] searchPointsNear:location
                                                   radius:radius
                                                     tags:tags
                                                    limit:limit
                                        completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarPoint *> *_Nullable points) {
                                            completionHandler(status, location, points);
                                        }];
    }];
}

+ (void)searchPointsNear:(CLLocation *)near
                  radius:(int)radius
                    tags:(NSArray<NSString *> *)tags
                   limit:(int)limit
       completionHandler:(RadarSearchPointsCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] searchPointsNear:near
                                               radius:radius
                                                 tags:tags
                                                limit:limit
                                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarPoint *> *_Nullable points) {
                                        completionHandler(status, near, points);
                                    }];
}

+ (void)autocompleteQuery:(NSString *)query near:(CLLocation *)near limit:(int)limit completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] autocompleteQuery:query
                                                  near:near
                                                 limit:limit
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                         completionHandler(status, addresses);
                                     }];
}

+ (void)geocodeAddress:(NSString *)query completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] geocodeAddress:query
                                  completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                      completionHandler(status, addresses);
                                  }];
}

+ (void)reverseGeocodeWithCompletionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            return completionHandler(status, nil);
        }

        [[RadarAPIClient sharedInstance] reverseGeocodeLocation:location
                                              completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                                  completionHandler(status, addresses);
                                              }];
    }];
}

+ (void)reverseGeocodeLocation:(CLLocation *)location completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] reverseGeocodeLocation:location
                                          completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                              completionHandler(status, addresses);
                                          }];
}

+ (void)ipGeocodeWithCompletionHandler:(RadarIPGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] ipGeocodeWithCompletionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarAddress *_Nullable address) {
        completionHandler(status, address);
    }];
}

+ (void)getDistanceToDestination:(CLLocation *)destination
                           modes:(RadarRouteMode)modes
                           units:(RadarRouteUnits)units
               completionHandler:(RadarRouteCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            return completionHandler(status, nil);
        }

        [[RadarAPIClient sharedInstance] getDistanceFromOrigin:location
                                                   destination:destination
                                                         modes:modes
                                                         units:units
                                             completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarRoutes *_Nullable routes) {
                                                 completionHandler(status, routes);
                                             }];
    }];
}

+ (void)getDistanceFromOrigin:(CLLocation *)origin
                  destination:(CLLocation *)destination
                        modes:(RadarRouteMode)modes
                        units:(RadarRouteUnits)units
            completionHandler:(RadarRouteCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] getDistanceFromOrigin:origin
                                               destination:destination
                                                     modes:modes
                                                     units:units
                                         completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarRoutes *_Nullable routes) {
                                             completionHandler(status, routes);
                                         }];
}

+ (void)setLogLevel:(RadarLogLevel)level {
    [RadarSettings setLogLevel:level];
}

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

+ (NSString *)stringForSource:(RadarLocationSource)source {
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
    case RadarLocationSourceGeofenceEnter:
        str = @"GEOFENCE_ENTER";
        break;
    case RadarLocationSourceGeofenceExit:
        str = @"GEOFENCE_EXIT";
        break;
    case RadarLocationSourceVisitArrival:
        str = @"VISIT_ARRIVAL";
        break;
    case RadarLocationSourceVisitDeparture:
        str = @"VISIT_DEPARTURE";
        break;
    case RadarLocationSourceMockLocation:
        str = @"MOCK_LOCATION";
        break;
    case RadarLocationSourceUnknown:
        str = @"UNKNOWN";
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
    return dict;
}

@end
