//
//  RadarGeofence.h
//  RadarSDK
//
//  Copyright © 2016 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadarGeofence : NSObject

/**
 * @abstract The unique ID for the geofence, provided by Radar.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_id;

/**
 * @abstract A description for the geofence. Not to be confused with the NSObject description property.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_description;

/**
 * @abstract An optional group for the geofence.
 */
@property (nullable, copy, nonatomic, readonly) NSString *tag;

/**
 * @abstract An optional external ID for the geofence.
 */
@property (nullable, copy, nonatomic, readonly) NSString *externalId;

/**
 * @abstract An optional set of custom key-value pairs for the geofence.
 */
@property (nullable, copy, nonatomic, readonly) NSDictionary *metadata;

@end
