//
//  RadarRoute.h
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarRouteDistance.h"
#import "RadarRouteDuration.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a route between an origin and a destination.
 */
@interface RadarRoute : NSObject

/**
 The distance of the route.
 */
@property (nonnull, strong, nonatomic, readonly) RadarRouteDistance *distance;

/**
 The duration of the route.
 */
@property (nonnull, strong, nonatomic, readonly) RadarRouteDuration *duration;

- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
