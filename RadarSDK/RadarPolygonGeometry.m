//
//  RadarPolygonGeometry.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarPolygonGeometry+Internal.h"

@implementation RadarPolygonGeometry

- (instancetype)initWithCoordinates:(NSArray *)coordinates
{
    self = [super init];
    if (self) {
        _coordinates = coordinates;
    }
    return self;
}

@end
