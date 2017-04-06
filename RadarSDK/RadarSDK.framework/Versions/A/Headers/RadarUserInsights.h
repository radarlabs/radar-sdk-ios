//
//  RadarUserInsights.h
//  RadarSDK
//
//  Copyright © 2017 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarUserInsightsLocation.h"
#import "RadarUserInsightsState.h"

@interface RadarUserInsights : NSObject

/**
 * @abstract The learned home location for the user. May be nil.
 */
@property (nullable, strong, nonatomic, readonly) RadarUserInsightsLocation *homeLocation;

/**
 * @abstract The learned office location for the user. May be nil.
 */
@property (nullable, strong, nonatomic, readonly) RadarUserInsightsLocation *officeLocation;

/**
 * @abstract The state of the user, based on learned home and office locations.
 */
@property (nonnull, strong, nonatomic, readonly) RadarUserInsightsState *state;

@end
