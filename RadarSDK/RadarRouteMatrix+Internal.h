//
//  RadarRouteMatrix+Internal.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarRouteMatrix.h"
#import <Foundation/Foundation.h>

@interface RadarRouteMatrix ()

@property (nonnull, strong, nonatomic, readonly) NSArray<NSArray<RadarRoute *> *> *matrix;

- (instancetype _Nullable)initWithObject:(id _Nonnull)object;

@end
