//
//  RadarAPIClient.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarAPIHelper.h"

#import "RadarAddress.h"
#import "RadarBeacon.h"
#import "RadarContext.h"
#import "RadarEvent.h"
#import "RadarLog.h"
#import "RadarMeta.h"
#import "RadarRegion.h"
#import "RadarRouteMatrix.h"
#import "RadarRoutes.h"
#import "RadarUser.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^_Nonnull RadarTrackAPICompletionHandler)(RadarStatus status,
                                                        NSDictionary *_Nullable res,
                                                        NSArray<RadarEvent *> *_Nullable events,
                                                        RadarUser *_Nullable user,
                                                        NSArray<RadarGeofence *> *_Nullable nearbyGeofences,
                                                        RadarMeta *_Nullable meta);

typedef void (^_Nonnull RadarTripAPICompletionHandler)(RadarStatus status, RadarTrip *_Nullable trip, NSArray<RadarEvent *> *_Nullable events);

typedef void (^_Nonnull RadarContextAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, RadarContext *_Nullable context);

typedef void (^_Nonnull RadarSearchPlacesAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarPlace *> *_Nullable places);

typedef void (^_Nonnull RadarSearchGeofencesAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarGeofence *> *_Nullable geofences);

typedef void (^_Nonnull RadarSearchBeaconsAPICompletionHandler)(RadarStatus status,
                                                                NSDictionary *_Nullable res,
                                                                NSArray<RadarBeacon *> *_Nullable beacons,
                                                                NSArray<NSString *> *_Nullable beaconUUIDs);

typedef void (^_Nonnull RadarGeocodeAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses);

typedef void (^_Nonnull RadarIPGeocodeAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, RadarAddress *_Nullable address, BOOL proxy);

typedef void (^_Nonnull RadarDistanceAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, RadarRoutes *_Nullable routes);

typedef void (^_Nonnull RadarMatrixAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, RadarRouteMatrix *_Nullable matrix);

typedef void (^_Nonnull RadarConfigAPICompletionHandler)(RadarStatus status, RadarMeta *_Nullable meta);

typedef void (^_Nonnull RadarSendEventAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable event);

typedef void (^_Nonnull RadarSyncLogsAPICompletionHandler)(RadarStatus status);

@interface RadarAPIClient : NSObject

@property (nonnull, strong, nonatomic) RadarAPIHelper *apiHelper;

+ (instancetype)sharedInstance;

+ (NSDictionary *)headersWithPublishableKey:(NSString *)publishableKey;

+ (RadarMeta *_Nullable)parseMeta:(NSDictionary *_Nullable)res;

- (void)getConfig:(BOOL)trackUsage
completionHandler:(RadarConfigAPICompletionHandler _Nonnull)completionHandler;

- (void)trackWithLocation:(CLLocation *_Nonnull)location
                  stopped:(BOOL)stopped
               foreground:(BOOL)foreground
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
                  beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
        completionHandler:(RadarTrackAPICompletionHandler _Nonnull)completionHandler;

- (void)verifyEventId:(NSString *_Nonnull)eventId verification:(RadarEventVerification)verification verifiedPlaceId:(NSString *_Nullable)verifiedPlaceId;

- (void)createTripWithOptions:(RadarTripOptions *_Nullable)options
            completionHandler:(RadarTripAPICompletionHandler _Nonnull)completionHandler;

- (void)updateTripWithOptions:(RadarTripOptions *_Nullable)options
                       status:(RadarTripStatus)status
            completionHandler:(RadarTripAPICompletionHandler _Nonnull)completionHandler;

- (void)getContextForLocation:(CLLocation *_Nonnull)location completionHandler:(RadarContextAPICompletionHandler _Nonnull)completionHandler;

- (void)searchPlacesNear:(CLLocation *_Nonnull)near
                  radius:(int)radius
                  chains:(NSArray *_Nullable)chains
           chainMetadata:(NSDictionary<NSString *, NSString *> *_Nullable)chainMetadata
              categories:(NSArray *_Nullable)categories
                  groups:(NSArray *_Nullable)groups
                   limit:(int)limit
       completionHandler:(RadarSearchPlacesAPICompletionHandler _Nonnull)completionHandler;

- (void)searchGeofencesNear:(CLLocation *_Nonnull)near
                     radius:(int)radius
                       tags:(NSArray *_Nullable)tags
                   metadata:(NSDictionary *_Nullable)metadata
                      limit:(int)limit
          completionHandler:(RadarSearchGeofencesAPICompletionHandler _Nonnull)completionHandler;

- (void)searchBeaconsNear:(CLLocation *_Nonnull)near radius:(int)radius limit:(int)limit completionHandler:(RadarSearchBeaconsAPICompletionHandler _Nonnull)completionHandler;

- (void)autocompleteQuery:(NSString *_Nonnull)query
                     near:(CLLocation *_Nullable)near
                   layers:(NSArray<NSString *> *_Nullable)layers
                    limit:(int)limit
                  country:(NSString *_Nullable)country
        completionHandler:(RadarGeocodeAPICompletionHandler _Nonnull)completionHandler;

- (void)geocodeAddress:(NSString *_Nonnull)query completionHandler:(RadarGeocodeAPICompletionHandler _Nonnull)completionHandler;

- (void)reverseGeocodeLocation:(CLLocation *_Nonnull)location completionHandler:(RadarGeocodeAPICompletionHandler _Nonnull)completionHandler;

- (void)ipGeocodeWithCompletionHandler:(RadarIPGeocodeAPICompletionHandler _Nonnull)completionHandler;

- (void)getDistanceFromOrigin:(CLLocation *_Nonnull)origin
                  destination:(CLLocation *_Nonnull)destination
                        modes:(RadarRouteMode)modes
                        units:(RadarRouteUnits)units
               geometryPoints:(int)geometryPoints
            completionHandler:(RadarDistanceAPICompletionHandler _Nonnull)completionHandler;

- (void)getMatrixFromOrigins:(NSArray<CLLocation *> *_Nonnull)origins
                destinations:(NSArray<CLLocation *> *_Nonnull)destinations
                        mode:(RadarRouteMode)mode
                       units:(RadarRouteUnits)units
           completionHandler:(RadarMatrixAPICompletionHandler _Nonnull)completionHandler;

- (void)sendEvent:(NSString *)type
     withMetadata:(NSDictionary *_Nullable)metadata
             user:(RadarUser *_Nullable)user
      trackEvents:(NSArray<RadarEvent *> *_Nullable)trackEvents
completionHandler:(RadarSendEventAPICompletionHandler _Nonnull)completionHandler;

- (void)syncLogs:(NSArray<RadarLog *> *)logs completionHandler:(RadarSyncLogsAPICompletionHandler _Nonnull)completionHandler;

@end

NS_ASSUME_NONNULL_END
