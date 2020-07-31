//
//  RadarRoutes+Internal.h
//  RadarSDK
//
//  Created by Nick Patrick on 2/1/20.
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarJSONCoding.h"
#import "RadarRoutes.h"
#import <Foundation/Foundation.h>

@interface RadarRoutes ()<RadarJSONCoding>

- (nullable instancetype)initWithGeodesic:(nullable RadarRouteDistance *)geodesic foot:(nullable RadarRoute *)foot bike:(nullable RadarRoute *)bike car:(nullable RadarRoute *)car;

@end
