//
//  RadarPolygonGeometry.h
//  RadarSDK
//
//  Created by Russell Cullen on 9/17/18.
//  Copyright © 2018 Radar. All rights reserved.
//

#import "RadarGeofenceGeometry.h"
#import "RadarCoordinate.h"

/**
 Represents the geometry of polygon geofence.
 */
@interface RadarPolygonGeometry : RadarGeofenceGeometry

/**
 The geometry of the polygon geofence. A closed ring of coordinates.
 */
@property (nullable, copy, nonatomic, readonly) NSArray<RadarCoordinate *> *coordinates;

@end
