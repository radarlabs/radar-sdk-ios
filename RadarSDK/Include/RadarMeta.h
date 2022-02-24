//
//  RadarMeta.h
//  RadarSDK
//
//  Created by Jeff Kao on 10/1/21.
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarTrackingOptions.h"
#import <Foundation/Foundation.h>

/**
 Represents the meta block returned by a Radar API request

 @see https://radar.io/documentation/api#track
 */
@interface RadarMeta : NSObject

/**
 The tracking options returned from enabling tracking options in the Radar dashboard.
 */
@property (nullable, strong, nonatomic, readwrite) RadarTrackingOptions *trackingOptions;

@end
