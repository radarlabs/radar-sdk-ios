//
//  RadarCoordinate.h
//  RadarSDK
//
//  Copyright © 2018 Radar. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

/**
 Represents a location coordinate.
 */
@interface RadarCoordinate : NSObject

/**
 The coordinate.
 */
@property (assign, nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end
