//
//  RadarTrip.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarCoordinate.h"
#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, RadarRouteMode);

/**
 Represents a trip. For more information, see https://radar.io/documentation/trip-tracking.

 @see https://radar.io/documentation/trip-tracking
 */
@interface RadarTrip : NSObject

/**
 The external ID of the trip.
 */
@property (nullable, copy, nonatomic, readonly) NSString *externalId;

/**
 The optional set of custom key-value pairs for the trip.
 */
@property (nullable, copy, nonatomic, readonly) NSDictionary *metadata;

/**
 For trips with a destination, the tag of the destination geofence.
 */
@property (nullable, copy, nonatomic, readonly) NSString *destinationGeofenceTag;

/**
 For trips with a destination, the external ID of the destination geofence.
 */
@property (nullable, copy, nonatomic, readonly) NSString *destinationGeofenceExternalId;

/**
 For trips with a destination, the location of the destination geofence.
 */
@property (nonnull, strong, nonatomic, readonly) RadarCoordinate *destinationLocation;

/**
 The travel mode for the trip.
 */
@property (assign, nonatomic, readonly) RadarRouteMode mode;

/**
 For trips with a destination, the distance to the destination geofence in meters based on the travel mode for the trip.
 */
@property (assign, nonatomic, readonly) float etaDistance;

/**
 For trips with a destination, the ETA to the destination geofence in minutes based on the travel mode for the trip.
 */
@property (assign, nonatomic, readonly) float etaDuration;

/**
 For trips with a destination, a boolean indicating whether the user has arrived (destination geofence entered).
 */
@property (assign, nonatomic, readonly) BOOL arrived;

@end
