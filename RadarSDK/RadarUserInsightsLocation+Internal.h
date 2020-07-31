//
//  RadarUserInsightsLocation+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarJSONCoding.h"
#import "RadarUserInsightsLocation.h"
#import <Foundation/Foundation.h>

@interface RadarUserInsightsLocation ()<RadarJSONCoding>

- (instancetype _Nullable)initWithType:(RadarUserInsightsLocationType)type
                              location:(RadarCoordinate* _Nullable)location
                            confidence:(RadarUserInsightsLocationConfidence)confidence
                             updatedAt:(NSDate* _Nonnull)updatedAt
                               country:(RadarRegion* _Nullable)country
                                 state:(RadarRegion* _Nullable)state
                                   dma:(RadarRegion* _Nullable)dma
                            postalCode:(RadarRegion* _Nullable)postalCode;

@end
