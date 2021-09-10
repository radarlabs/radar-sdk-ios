//
//  RadarRoutes+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarRoutes.h"
#import <Foundation/Foundation.h>

@interface RadarRoutes ()

- (nullable instancetype)initWithGeodesic:(nullable RadarRouteDistance *)geodesic
                                     foot:(nullable RadarRoute *)foot
                                     bike:(nullable RadarRoute *)bike
                                      car:(nullable RadarRoute *)car
                                    truck:(nullable RadarRoute *)truck
                                motorbike:(nullable RadarRoute *)motorbike;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
