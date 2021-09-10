//
//  Radar.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"

#import "RadarAPIClient.h"
#import "RadarBeaconManager.h"
#import "RadarCoordinate+Internal.h"
#import "RadarDelegateHolder.h"
#import "RadarLocationManager.h"
#import "RadarLogger.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarUtils.h"

@interface Radar ()

@property (nullable, weak, nonatomic) id<RadarDelegate> delegate;

@end

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

    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance]
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
        [RadarSettings updateSessionId];
    }

    [RadarSettings setPublishableKey:publishableKey];
    [[RadarLocationManager sharedInstance] updateTracking];
    [[RadarAPIClient sharedInstance] getConfig];
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
    return [RadarSettings __description];
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
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        [RadarUtils runOnMainThread:^{
            completionHandler(status, location, stopped);
        }];
    }];
}

+ (void)getLocationWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarLocationCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithDesiredAccuracy:desiredAccuracy
                                                        completionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
                                                            [RadarUtils runOnMainThread:^{
                                                                completionHandler(status, location, stopped);
                                                            }];
                                                        }];
}

+ (void)trackOnceWithCompletionHandler:(RadarTrackCompletionHandler)completionHandler {
    [self trackOnceWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium beacons:NO completionHandler:completionHandler];
}

+ (void)trackOnceWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy beacons:(BOOL)beacons completionHandler:(RadarTrackCompletionHandler)completionHandler {
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

                         void (^callTrackAPI)(NSArray<NSString *> *_Nullable) = ^(NSArray<NSString *> *_Nullable nearbyBeacons) {
                             [[RadarAPIClient sharedInstance] trackWithLocation:location
                                                                        stopped:stopped
                                                                     foreground:YES
                                                                         source:RadarLocationSourceForegroundLocation
                                                                       replayed:NO
                                                                  nearbyBeacons:nearbyBeacons
                                                              completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events,
                                                                                  RadarUser *_Nullable user, NSArray<RadarGeofence *> *_Nullable nearbyGeofences) {
                                                                  if (completionHandler) {
                                                                      [RadarUtils runOnMainThread:^{
                                                                          completionHandler(status, location, events, user);
                                                                      }];
                                                                  }
                                                              }];
                         };

                         if (beacons) {
                             [[RadarAPIClient sharedInstance] searchBeaconsNear:location
                                                                         radius:1000
                                                                          limit:10
                                                              completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons) {
                                                                  if (status != RadarStatusSuccess || !beacons) {
                                                                      callTrackAPI(nil);

                                                                      return;
                                                                  }

                                                                  [[RadarLocationManager sharedInstance] replaceSyncedBeacons:beacons];

                                                                  [RadarUtils runOnMainThread:^{
                                                                      [[RadarBeaconManager sharedInstance]
                                                                               rangeBeacons:beacons
                                                                          completionHandler:^(RadarStatus status, NSArray<NSString *> *_Nullable nearbyBeacons) {
                                                                              if (status != RadarStatusSuccess || !nearbyBeacons) {
                                                                                  callTrackAPI(nil);

                                                                                  return;
                                                                              }

                                                                              callTrackAPI(nearbyBeacons);
                                                                          }];
                                                                  }];
                                                              }];
                         } else {
                             callTrackAPI(nil);
                         }
                     }];
}

+ (void)trackOnceWithLocation:(CLLocation *)location completionHandler:(RadarTrackCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] trackWithLocation:location
                                               stopped:NO
                                            foreground:YES
                                                source:RadarLocationSourceManualLocation
                                              replayed:NO
                                         nearbyBeacons:nil
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                                         NSArray<RadarGeofence *> *_Nullable nearbyGeofences) {
                                         if (completionHandler) {
                                             [RadarUtils runOnMainThread:^{
                                                 completionHandler(status, location, events, user);
                                             }];
                                         }
                                     }];
}

+ (void)startTrackingWithOptions:(RadarTrackingOptions *)options {
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
                            nearbyBeacons:nil
                        completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user,
                                            NSArray<RadarGeofence *> *_Nullable nearbyGeofences) {
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
    [[RadarLocationManager sharedInstance] stopTracking];
}

+ (BOOL)isTracking {
    return [RadarSettings tracking];
}

+ (RadarTrackingOptions *)getTrackingOptions {
    return [RadarSettings trackingOptions];
}

+ (void)setDelegate:(id<RadarDelegate>)delegate {
    [RadarDelegateHolder sharedInstance].delegate = delegate;
}

+ (void)acceptEventId:(NSString *)eventId verifiedPlaceId:(NSString *)verifiedPlaceId {
    [[RadarAPIClient sharedInstance] verifyEventId:eventId verification:RadarEventVerificationAccept verifiedPlaceId:verifiedPlaceId];
}

+ (void)rejectEventId:(NSString *)eventId {
    [[RadarAPIClient sharedInstance] verifyEventId:eventId verification:RadarEventVerificationReject verifiedPlaceId:nil];
}

+ (RadarTripOptions *)getTripOptions {
    return [RadarSettings tripOptions];
}

+ (void)startTripWithOptions:(RadarTripOptions *)options {
    [self startTripWithOptions:options completionHandler:nil];
}

+ (void)startTripWithOptions:(RadarTripOptions *)options completionHandler:(RadarTripCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] updateTripWithOptions:options
                                                    status:RadarTripStatusStarted
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

+ (void)updateTripWithOptions:(RadarTripOptions *)options status:(RadarTripStatus)status completionHandler:(RadarTripCompletionHandler)completionHandler {
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
    RadarTripOptions *options = [RadarSettings tripOptions];
    [[RadarAPIClient sharedInstance] updateTripWithOptions:options
                                                    status:RadarTripStatusCompleted
                                         completionHandler:^(RadarStatus status, RadarTrip *trip, NSArray<RadarEvent *> *events) {
                                             if (status == RadarStatusSuccess || status == RadarStatusErrorNotFound) {
                                                 [RadarSettings setTripOptions:nil];

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
    RadarTripOptions *options = [RadarSettings tripOptions];
    [[RadarAPIClient sharedInstance] updateTripWithOptions:options
                                                    status:RadarTripStatusCanceled
                                         completionHandler:^(RadarStatus status, RadarTrip *trip, NSArray<RadarEvent *> *events) {
                                             if (status == RadarStatusSuccess || status == RadarStatusErrorNotFound) {
                                                 [RadarSettings setTripOptions:nil];

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

+ (void)getContextWithCompletionHandler:(RadarContextCompletionHandler)completionHandler {
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
    [[RadarAPIClient sharedInstance] getContextForLocation:location
                                         completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarContext *_Nullable context) {
                                             if (completionHandler) {
                                                 [RadarUtils runOnMainThread:^{
                                                     completionHandler(status, location, context);
                                                 }];
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
                                               categories:categories
                                                   groups:groups
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
                   limit:(int)limit
       completionHandler:(RadarSearchPlacesCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] searchPlacesNear:near
                                               radius:radius
                                               chains:chains
                                           categories:categories
                                               groups:groups
                                                limit:limit
                                    completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarPlace *> *_Nullable places) {
                                        [RadarUtils runOnMainThread:^{
                                            completionHandler(status, near, places);
                                        }];
                                    }];
}

+ (void)searchGeofencesWithRadius:(int)radius
                             tags:(NSArray *_Nullable)tags
                         metadata:(NSDictionary *_Nullable)metadata
                            limit:(int)limit
                completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler {
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
                                           completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarGeofence *> *_Nullable geofences) {
                                               if (completionHandler) {
                                                   [RadarUtils runOnMainThread:^{
                                                       completionHandler(status, location, geofences);
                                                   }];
                                               }
                                           }];
    }];
}

+ (void)searchGeofencesNear:(CLLocation *_Nonnull)near
                     radius:(int)radius
                       tags:(NSArray *_Nullable)tags
                   metadata:(NSDictionary *_Nullable)metadata
                      limit:(int)limit
          completionHandler:(RadarSearchGeofencesCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] searchGeofencesNear:near
                                                  radius:radius
                                                    tags:tags
                                                metadata:metadata
                                                   limit:limit
                                       completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarGeofence *> *_Nullable geofences) {
                                           if (completionHandler) {
                                               [RadarUtils runOnMainThread:^{
                                                   completionHandler(status, near, geofences);
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

+ (void)geocodeAddress:(NSString *)query completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] geocodeAddress:query
                                  completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                      [RadarUtils runOnMainThread:^{
                                          completionHandler(status, addresses);
                                      }];
                                  }];
}

+ (void)reverseGeocodeWithCompletionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarLocationManager sharedInstance] getLocationWithCompletionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
        if (status != RadarStatusSuccess) {
            if (completionHandler) {
                [RadarUtils runOnMainThread:^{
                    completionHandler(status, nil);
                }];
            }

            return;
        }

        [[RadarAPIClient sharedInstance] reverseGeocodeLocation:location
                                              completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                                  if (completionHandler) {
                                                      [RadarUtils runOnMainThread:^{
                                                          completionHandler(status, addresses);
                                                      }];
                                                  }
                                              }];
    }];
}

+ (void)reverseGeocodeLocation:(CLLocation *)location completionHandler:(RadarGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] reverseGeocodeLocation:location
                                          completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses) {
                                              if (completionHandler) {
                                                  [RadarUtils runOnMainThread:^{
                                                      completionHandler(status, addresses);
                                                  }];
                                              }
                                          }];
}

+ (void)ipGeocodeWithCompletionHandler:(RadarIPGeocodeCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance] ipGeocodeWithCompletionHandler:^(RadarStatus status, NSDictionary *_Nullable res, RadarAddress *_Nullable address, BOOL proxy) {
        if (completionHandler) {
            [RadarUtils runOnMainThread:^{
                completionHandler(status, address, proxy);
            }];
        }
    }];
}

+ (void)getDistanceToDestination:(CLLocation *)destination
                           modes:(RadarRouteMode)modes
                           units:(RadarRouteUnits)units
               completionHandler:(RadarRouteCompletionHandler)completionHandler {
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
    case RadarLocationSourceUnknown:
        str = @"UNKNOWN";
    }
    return str;
}

+ (NSString *)stringForMode:(RadarRouteMode)mode {
    NSString *str;
    switch (mode) {
    case RadarRouteModeFoot:
        str = @"foot";
        break;
    case RadarRouteModeBike:
        str = @"bike";
        break;
    case RadarRouteModeCar:
        str = @"car";
        break;
    case RadarRouteModeTruck:
        str = @"truck";
        break;
    case RadarRouteModeMotorbike:
        str = @"motorbike";
        break;
    }
    return str;
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
    return dict;
}

- (void)applicationWillEnterForeground {
    BOOL updated = [RadarSettings updateSessionId];
    if (updated) {
        [[RadarAPIClient sharedInstance] getConfig];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
