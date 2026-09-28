//
//  RadarCircleGeometry+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@interface RadarCircleGeometry ()

- (instancetype)initWithCenter:(RadarCoordinate *)center radius:(double)radius;

@end
