//
//  RadarRouteMatrix+Internal.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

@interface RadarRouteMatrix ()

@property (nonnull, strong, nonatomic, readonly) NSArray<NSArray<RadarRoute *> *> *matrix;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
