//
//  RadarUserInsightsState.h
//  RadarSDK
//
//  Copyright © 2017 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadarUserInsightsState : NSObject

/**
 * @abstract A boolean indicating whether the user is at home, based on learned home location.
 */
@property (assign, nonatomic, readonly) BOOL home;

/**
 * @abstract A boolean indicating whether the user is at the office, based on learned office location.
 */
@property (assign, nonatomic, readonly) BOOL office;

/**
 * @abstract A boolean indicating whether the user is traveling, based on learned home location.
 */
@property (assign, nonatomic, readonly) BOOL traveling;

@end
