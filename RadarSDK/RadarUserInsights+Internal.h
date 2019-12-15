//
//  RadarUserInsights+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarUserInsightsLocation.h"
#import "RadarUserInsightsState.h"

@interface RadarUserInsights ()

- (instancetype _Nullable)initWithHomeLocation:(RadarUserInsightsLocation * _Nonnull)homeLocation officeLocation:(RadarUserInsightsLocation * _Nonnull)officeLocation state:(RadarUserInsightsState * _Nonnull)state;
- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
