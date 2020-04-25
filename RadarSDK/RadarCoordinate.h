//
//  RadarCoordinate.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "RadarJSONCoding.h"

/**
 Represents a location coordinate.
 */
@interface RadarCoordinate : NSObject<RadarJSONCoding>

/**
 The coordinate.
 */
@property (assign, nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (NSDictionary* _Nonnull)dictionaryValue;

@end
