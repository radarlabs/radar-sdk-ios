//
//  RadarTrip+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarTrip.h"
#import "RadarTripLeg.h"
#import <Foundation/Foundation.h>

@interface RadarTrip ()

- (instancetype _Nullable)initWithId:(NSString *_Nonnull)_id
                          externalId:(NSString *_Nonnull)externalId
                            metadata:(NSDictionary *_Nullable)metadata
              destinationGeofenceTag:(NSString *_Nullable)destinationGeofenceTag
       destinationGeofenceExternalId:(NSString *_Nullable)destinationGeofenceExternalId
                 destinationLocation:(RadarCoordinate *_Nullable)destinationLocation
                                mode:(RadarRouteMode)mode
                         etaDistance:(float)etaDistance
                         etaDuration:(float)etaDuration
                              status:(RadarTripStatus)status
                              orders:(NSArray<RadarTripOrder *> *_Nullable)orders
                                legs:(NSArray<RadarTripLeg *> *_Nullable)legs
                        currentLegId:(NSString *_Nullable)currentLegId;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
