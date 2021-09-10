//
//  RadarUserInsights.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarUserInsightsLocation.h"
#import "RadarUserInsightsState.h"
#import <Foundation/Foundation.h>

/**
 Represents the learned home, work, traveling and commuting state and locations of the current user.

 @see https://radar.io/documentation/insights
 */
@interface RadarUserInsights : NSObject

/**
 The learned home location of the user. May be `nil` if not yet learned, or if Insights is turned off.
 */
@property (nullable, strong, nonatomic, readonly) RadarUserInsightsLocation *homeLocation;

/**
 The learned office location of the user. May be `nil` if not yet learned, or if Insights is turned off.
 */
@property (nullable, strong, nonatomic, readonly) RadarUserInsightsLocation *officeLocation;

/**
 The state of the user, based on learned home and office locations.
 */
@property (nonnull, strong, nonatomic, readonly) RadarUserInsightsState *state;

- (NSDictionary *_Nonnull)dictionaryValue;

@end
