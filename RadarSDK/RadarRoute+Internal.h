//
//  RadarRoute+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarRoute.h"

@interface RadarRoute ()

- (nullable instancetype)initWithDistance:(nullable RadarRouteDistance *)distance
                                 duration:(nullable RadarRouteDuration *)duration;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
