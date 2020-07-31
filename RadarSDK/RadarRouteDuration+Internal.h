//
//  RadarRouteDuration+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarJSONCoding.h"
#import "RadarRouteDuration.h"
#import <Foundation/Foundation.h>

@interface RadarRouteDuration ()<RadarJSONCoding>

- (instancetype _Nullable)initWithValue:(double)value text:(nonnull NSString *)text;

@end
