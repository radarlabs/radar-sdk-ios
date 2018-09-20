//
//  RadarGeofence.h
//  RadarSDK
//
//  Copyright © 2016 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarGeofenceGeometry.h"

/**
 Represents a geofence. For more information about Geofences, see https://radar.io/documentation/geofences.
 
 @see https://radar.io/documentation/geofences
 */
@interface RadarGeofence : NSObject

/**
 The Radar ID of the geofence.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_id;

/**
 The description of the geofence. Not to be confused with the `NSObject` `description` property.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_description;

/**
 The tag of the geofence.
 */
@property (nullable, copy, nonatomic, readonly) NSString *tag;

/**
 The external ID of the geofence.
 */
@property (nullable, copy, nonatomic, readonly) NSString *externalId;

/**
 The optional set of custom key-value pairs for the geofence.
 */
@property (nullable, copy, nonatomic, readonly) NSDictionary *metadata;

/**
 The geometry of the geofence.
 */
@property (nonnull, strong, nonatomic, readonly) RadarGeofenceGeometry *geometry;

@end
