//
//  RadarCircleGeometry.h
//  RadarSDK
//
//  Created by Russell Cullen on 9/17/18.
//  Copyright © 2018 Radar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RadarCoordinate.h"
#import "RadarGeofenceGeometry.h"

/**
 Represents the geometry of a circle geofence.
 */
@interface RadarCircleGeometry : RadarGeofenceGeometry

/**
 The center of the circle geofence.
 */
@property (nonnull, strong, nonatomic, readonly) RadarCoordinate *center;

/**
 The radius of the circle geofence in meters.
 */
@property (assign, nonatomic, readonly) double radius;

@end
