//
//  RadarUserInsights+Internal.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarJSONCoding.h"
#import "RadarUserInsightsLocation.h"
#import "RadarUserInsightsState.h"
#import <Foundation/Foundation.h>

@interface RadarUserInsights ()<RadarJSONCoding>

- (instancetype _Nullable)initWithHomeLocation:(RadarUserInsightsLocation* _Nonnull)homeLocation
                                officeLocation:(RadarUserInsightsLocation* _Nonnull)officeLocation
                                         state:(RadarUserInsightsState* _Nonnull)state;

@end
