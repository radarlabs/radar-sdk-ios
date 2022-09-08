//
//  RadarRouteMode.h
//  RadarSDK
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The travel modes for routes.

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

NS_ASSUME_NONNULL_END
