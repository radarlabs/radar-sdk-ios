//
//  RadarUserInsightsState.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Represents the learned home, work, traveling and commuting state of the current user.

 @see https://radar.io/documentation/insights
 */
@interface RadarUserInsightsState : NSObject

/**
 A boolean indicating whether the user is at home, based on learned home location.
 */
@property (assign, nonatomic, readonly) BOOL home;

/**
 A boolean indicating whether the user is at the office, based on learned office location.
 */
@property (assign, nonatomic, readonly) BOOL office;

/**
 A boolean indicating whether the user is traveling, based on learned home location.
 */
@property (assign, nonatomic, readonly) BOOL traveling;

/**
 A boolean indicating whether the user is commuting, based on learned home location.
 */
@property (assign, nonatomic, readonly) BOOL commuting;

- (NSDictionary* _Nonnull)dictionaryValue;

@end
