//
//  RadarPolygonGeometry.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCoordinate.h"
#import "RadarGeofenceGeometry.h"

/**
 Represents the geometry of polygon geofence.
 */
@interface RadarPolygonGeometry : RadarGeofenceGeometry

/**
 The geometry of the polygon geofence. A closed ring of coordinates.
 */
@property (nullable, copy, nonatomic, readonly) NSArray<RadarCoordinate *> *coordinates;

@end
