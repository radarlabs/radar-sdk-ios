//
//  RadarUserInsightsState.h
//  RadarSDK
//
//  Copyright © 2017 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Represents the learned home, work, and traveling state of the current user. For more information about Insights, see https://radar.io/documentation/insights.
 
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

@end
