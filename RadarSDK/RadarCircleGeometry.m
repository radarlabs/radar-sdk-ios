//
//  RadarCircleGeometry.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCircleGeometry+Internal.h"

@implementation RadarCircleGeometry

- (instancetype)initWithCenter:(RadarCoordinate *)center radius:(double)radius {
    self = [super init];
    if (self) {
        _center = center;
        _radius = radius;
    }
    return self;
}

@end
