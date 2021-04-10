//
//  RadarGeofence.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarGeofenceGeometry.h"
#import <Foundation/Foundation.h>

/**
 Represents a geofence.

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

+ (NSArray<NSDictionary *> *_Nullable)arrayForGeofences:(NSArray<RadarGeofence *> *_Nullable)geofences;
- (NSDictionary *_Nonnull)dictionaryValue;

@end
