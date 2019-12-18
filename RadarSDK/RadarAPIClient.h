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
#import "RadarEvent.h"
#import "RadarRegion.h"
#import "RadarUser.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ _Nullable RadarTrackAPICompletionHandler)(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarEvent *> * _Nullable events, RadarUser * _Nullable user);

typedef void(^ _Nullable RadarSearchPlacesAPICompletionHandler)(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarPlace *> * _Nullable places);

typedef void(^ _Nullable RadarSearchGeofencesAPICompletionHandler)(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarGeofence *> * _Nullable geofences);

typedef void(^ _Nullable RadarGeocodeAPICompletionHandler)(RadarStatus status, NSDictionary * _Nullable res, NSArray<RadarAddress *> * _Nullable addresses);

typedef void(^ _Nullable RadarIPGeocodeAPICompletionHandler)(RadarStatus status, NSDictionary * _Nullable res, RadarRegion * _Nullable region);

@interface RadarAPIClient : NSObject

@property (nullable, weak, nonatomic) id<RadarDelegate> delegate;
@property (nonnull, strong, nonatomic) RadarAPIHelper *apiHelper;

+ (instancetype)sharedInstance;

- (void)getConfig;

- (void)trackWithLocation:(CLLocation * _Nonnull)location
                  stopped:(BOOL)stopped
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
        completionHandler:(RadarTrackAPICompletionHandler _Nullable)completionHandler;

- (void)verifyEventId:(NSString * _Nonnull)eventId
         verification:(RadarEventVerification)verification
      verifiedPlaceId:(NSString * _Nullable)verifiedPlaceId;

- (void)searchPlacesWithLocation:(CLLocation * _Nonnull)location
                          radius:(int)radius
                          chains:(NSArray * _Nullable)chains
                      categories:(NSArray * _Nullable)categories
                          groups:(NSArray * _Nullable)groups
                           limit:(int)limit
               completionHandler:(RadarSearchPlacesAPICompletionHandler _Nullable)completionHandler;

- (void)searchGeofencesWithLocation:(CLLocation * _Nonnull)location
                             radius:(int)radius
                               tags:(NSArray * _Nullable)tags
                              limit:(int)limit
                  completionHandler:(RadarSearchGeofencesAPICompletionHandler _Nullable)completionHandler;

- (void)geocode:(NSString * _Nonnull)query
        completionHandler:(RadarGeocodeAPICompletionHandler _Nullable)completionHandler;

- (void)reverseGeocode:(CLLocation * _Nonnull)location
     completionHandler:(RadarGeocodeAPICompletionHandler _Nullable)completionHandler;

- (void)ipGeocode:(RadarIPGeocodeAPICompletionHandler _Nullable)completionHandler;

@end

NS_ASSUME_NONNULL_END
