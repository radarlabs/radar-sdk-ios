//
//  RadarPolygonGeometry+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarPolygonGeometry.h"

@interface RadarPolygonGeometry ()

- (instancetype)initWithCoordinates:(NSArray<RadarCoordinate *> *)coordinates center:(RadarCoordinate *)center radius:(double)radius;

@end
