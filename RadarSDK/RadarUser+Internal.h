//
//  RadarUser+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarGeofence.h"
#import "RadarTrip.h"
#import "RadarUser.h"
#import <Foundation/Foundation.h>

@interface RadarUser ()

- (instancetype _Nullable)initWithId:(NSString *_Nonnull)_id
                              userId:(NSString *_Nullable)userId
                            deviceId:(NSString *_Nullable)deviceId
                         description:(NSString *_Nullable)description
                            metadata:(NSDictionary *_Nullable)metadata
                            location:(CLLocation *_Nonnull)location
                        activityType:(RadarActivityType)activityType
                           geofences:(NSArray *_Nullable)geofences
                               place:(RadarPlace *_Nullable)place
                             beacons:(NSArray *_Nullable)beacons
                             stopped:(BOOL)stopped
                          foreground:(BOOL)foreground
                             country:(RadarRegion *_Nullable)country
                               state:(RadarRegion *_Nullable)state
                                 dma:(RadarRegion *_Nullable)dma
                          postalCode:(RadarRegion *_Nullable)postalCode
                   nearbyPlaceChains:(nullable NSArray<RadarChain *> *)nearbyPlaceChains
                            segments:(nullable NSArray<RadarSegment *> *)segments
                           topChains:(nullable NSArray<RadarChain *> *)topChains
                              source:(RadarLocationSource)source
                                trip:(RadarTrip *_Nullable)trip
                               debug:(BOOL)debug
                               fraud:(RadarFraud *_Nullable)fraud
                               altitude:(double)altitude
                            floorLevel:(double)floorLevel
                     barometricAltitude:(double)barometricAltitude
                      verticalAccuracy:(double)verticalAccuracy;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
