//
//  RadarRouteDistance+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarJSONCoding.h"
#import "RadarRouteDistance.h"
#import <Foundation/Foundation.h>

@interface RadarRouteDistance ()<RadarJSONCoding>

- (instancetype _Nullable)initWithValue:(double)value text:(nonnull NSString *)text;

@end
