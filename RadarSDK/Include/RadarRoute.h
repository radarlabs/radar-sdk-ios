//
//  RadarRoute.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarRouteDistance.h"
#import "RadarRouteDuration.h"
#import "RadarRouteGeometry.h"

NS_ASSUME_NONNULL_BEGIN

/** The travel modes for routes.
 @see https://radar.com/documentation/api#routing
*/
typedef NS_OPTIONS(NSInteger, RadarRouteMode) {
    /// Foot
    RadarRouteModeFoot NS_SWIFT_NAME(foot) = 1 << 0,
    /// Bike
    RadarRouteModeBike NS_SWIFT_NAME(bike) = 1 << 1,
    /// Car
    RadarRouteModeCar NS_SWIFT_NAME(car) = 1 << 2,
    /// Truck
    RadarRouteModeTruck NS_SWIFT_NAME(truck) = 1 << 3,
    /// Motorbike
    RadarRouteModeMotorbike NS_SWIFT_NAME(motorbike) = 1 << 4
};

/**
 Represents a route between an origin and a destination.

 @see https://radar.com/documentation/api#routing
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

/**
 The geometry of the route.
 */
@property (nonnull, strong, nonatomic, readonly) RadarRouteGeometry *geometry;

- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
