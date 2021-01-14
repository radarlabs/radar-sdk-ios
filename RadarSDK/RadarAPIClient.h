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
#import "RadarRegion.h"
#import "RadarRoutes.h"
#import "RadarUser.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^_Nullable RadarTrackAPICompletionHandler)(
    RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user, NSArray<RadarGeofence *> *_Nullable nearbyGeofences);

typedef void (^_Nullable RadarContextAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, RadarContext *_Nullable context);

typedef void (^_Nullable RadarSearchPlacesAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarPlace *> *_Nullable places);

typedef void (^_Nullable RadarSearchGeofencesAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarGeofence *> *_Nullable geofences);

typedef void (^_Nullable RadarSearchBeaconsAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons);

typedef void (^_Nullable RadarGeocodeAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarAddress *> *_Nullable addresses);

typedef void (^_Nullable RadarIPGeocodeAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, RadarAddress *_Nullable address, BOOL proxy);

typedef void (^_Nullable RadarDistanceAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, RadarRoutes *_Nullable routes);

@interface RadarAPIClient : NSObject

@property (nullable, weak, nonatomic) id<RadarDelegate> delegate;
@property (nonnull, strong, nonatomic) RadarAPIHelper *apiHelper;

+ (instancetype)sharedInstance;

+ (NSDictionary *)headersWithPublishableKey:(NSString *)publishableKey;

- (void)getConfig;

- (void)trackWithLocation:(CLLocation *_Nonnull)location
                  stopped:(BOOL)stopped
               foreground:(BOOL)foreground
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
            nearbyBeacons:(NSArray<NSString *> *_Nullable)nearbyBeacons
        completionHandler:(RadarTrackAPICompletionHandler _Nullable)completionHandler;

- (void)verifyEventId:(NSString *_Nonnull)eventId verification:(RadarEventVerification)verification verifiedPlaceId:(NSString *_Nullable)verifiedPlaceId;

- (void)updateTripWithStatus:(RadarTripStatus)status;

- (void)getContextForLocation:(CLLocation *_Nonnull)location completionHandler:(RadarContextAPICompletionHandler _Nullable)completionHandler;

- (void)searchPlacesNear:(CLLocation *_Nonnull)near
                  radius:(int)radius
                  chains:(NSArray *_Nullable)chains
              categories:(NSArray *_Nullable)categories
                  groups:(NSArray *_Nullable)groups
                   limit:(int)limit
       completionHandler:(RadarSearchPlacesAPICompletionHandler _Nullable)completionHandler;

- (void)searchGeofencesNear:(CLLocation *_Nonnull)near
                     radius:(int)radius
                       tags:(NSArray *_Nullable)tags
                   metadata:(NSDictionary *_Nullable)metadata
                      limit:(int)limit
          completionHandler:(RadarSearchGeofencesAPICompletionHandler _Nullable)completionHandler;

- (void)searchBeaconsNear:(CLLocation *_Nonnull)near radius:(int)radius limit:(int)limit completionHandler:(RadarSearchBeaconsAPICompletionHandler _Nullable)completionHandler;

- (void)autocompleteQuery:(NSString *_Nonnull)query
                     near:(CLLocation *_Nonnull)near
                    limit:(int)limit
        completionHandler:(RadarGeocodeAPICompletionHandler _Nullable)completionHandler;

- (void)geocodeAddress:(NSString *_Nonnull)query completionHandler:(RadarGeocodeAPICompletionHandler _Nullable)completionHandler;

- (void)reverseGeocodeLocation:(CLLocation *_Nonnull)location completionHandler:(RadarGeocodeAPICompletionHandler _Nullable)completionHandler;

- (void)ipGeocodeWithCompletionHandler:(RadarIPGeocodeAPICompletionHandler _Nullable)completionHandler;

- (void)getDistanceFromOrigin:(CLLocation *_Nonnull)origin
                  destination:(CLLocation *_Nonnull)destination
                        modes:(RadarRouteMode)modes
                        units:(RadarRouteUnits)units
               geometryPoints:(int)geometryPoints
            completionHandler:(RadarDistanceAPICompletionHandler _Nullable)completionHandler;

@end

NS_ASSUME_NONNULL_END
