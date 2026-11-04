//
//  RadarRoutes+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@interface RadarRoutes ()

- (instancetype _Nonnull)initWithGeodesic:(nullable RadarRouteDistance *)geodesic
                                     foot:(nullable RadarRoute *)foot
                                     bike:(nullable RadarRoute *)bike
                                      car:(nullable RadarRoute *)car
                                    truck:(nullable RadarRoute *)truck
                                motorbike:(nullable RadarRoute *)motorbike;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
