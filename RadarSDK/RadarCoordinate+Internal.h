//
//  RadarCoordinate+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif


@interface RadarCoordinate ()

+ (NSArray<RadarCoordinate *> *_Nullable)coordinatesFromObject:(id _Nonnull)object;
- (instancetype _Nullable)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
