//
//  RadarCoordinate+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCoordinate.h"

@interface RadarCoordinate ()

+ (NSArray<RadarCoordinate *> *_Nullable)coordinatesFromObject:(id _Nonnull)object;
- (instancetype _Nullable)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
