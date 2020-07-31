//
//  RadarCoordinate+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCoordinate.h"
#import "RadarJSONCoding.h"

@interface RadarCoordinate ()<RadarJSONCoding>

// init from an array of GeoPoint (will this method ever be used?)
+ (NSArray<RadarCoordinate *> *_Nullable)coordinatesFromObject:(id _Nonnull)object;

// init from an array of coordinates `[[longitude, latitude], [longitude, latitude], ...]`
+ (NSArray<RadarCoordinate *> *_Nullable)coordinatesFromJSONCoordinates:(id _Nonnull)coordinateArrayObject;

// init from CLLocationCoordinate2D
- (instancetype _Nullable)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end
