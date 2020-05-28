//
//  RadarCoordinate.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "RadarJSONCoding.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a location coordinate.
 */
@interface RadarCoordinate : NSObject<RadarJSONCoding, NSCopying>

/**
 The coordinate.
 */
@property (assign, nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end

NS_ASSUME_NONNULL_END
