//
//  RadarRoute+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarRoute.h"
#import <Foundation/Foundation.h>

@interface RadarRoute ()

- (nullable instancetype)initWithDistance:(nullable RadarRouteDistance *)distance duration:(nullable RadarRouteDuration *)duration geometry:(nullable RadarRouteGeometry *)geometry;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
