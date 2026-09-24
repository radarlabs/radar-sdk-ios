//
//  RadarOperatingHour+Internal.h
//  RadarSDK
//
//  Created by Kenny Hu on 10/7/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@interface RadarOperatingHours()

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
