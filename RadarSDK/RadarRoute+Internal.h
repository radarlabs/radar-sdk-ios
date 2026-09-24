//
//  RadarRoute+Internal.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarRoute.h"
#import <Foundation/Foundation.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@interface RadarRoute ()

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end

@interface RadarRouteDistance ()

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
