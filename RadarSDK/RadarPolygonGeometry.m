//
//  RadarPolygonGeometry.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarPolygonGeometry+Internal.h"
#import "RadarCoordinate+Internal.h"

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

- (NSDictionary *)dictionaryValue {
    NSMutableArray *coordinatesArr = [NSMutableArray new];
    for (RadarCoordinate *coordinate in self._coordinates) {
        [coordinatesArr addObject:[coordinate dictionaryValue]];
    }
    return @{@"type": @"Polygon", @"coordinates": @[coordinatesArr]};
}

@end
