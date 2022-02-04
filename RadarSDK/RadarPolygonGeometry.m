//
//  RadarPolygonGeometry.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarPolygonGeometry+Internal.h"

@implementation RadarPolygonGeometry

- (instancetype)initWithCoordinates:(NSArray<RadarCoordinate *> *)coordinates center:(RadarCoordinate *)center radius:(double)radius {
    self = [super init];
    if (self) {
        __coordinates = coordinates;
        _center = center;
        _radius = radius;
    }
    return self;
}

@end
