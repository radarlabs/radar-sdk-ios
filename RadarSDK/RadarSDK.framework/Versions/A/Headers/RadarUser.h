//
//  RadarUser.h
//  RadarSDK
//
//  Copyright © 2016 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarGeofence.h"
#import "RadarPlace.h"
#import "RadarUserInsights.h"

@interface RadarUser : NSObject

/**
 * @abstract The unique ID for the user, provided by Radar.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_id;

/**
 * @abstract The unique ID for the user, provided when you identified the user.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *userId;

/**
 * @abstract An optional description for the user. Not to be confused with the NSObject description property.
 */
@property (nullable, copy, nonatomic, readonly) NSString *_description;

/**
 * @abstract An optional set of custom key-value pairs for the user.
 */
@property (nullable, copy, nonatomic, readonly) NSDictionary *metadata;

/**
 * @abstract An array of the user's last known geofences. May be nil or empty if the user is not in any geofences.
 */
@property (nullable, copy, nonatomic, readonly) NSArray<RadarGeofence *> *geofences;

/**
 * @abstract The user's last known place. May be nil if the user is not at a place, or if Places is turned off.
 */
@property (nullable, copy, nonatomic, readonly) RadarPlace *place;

/**
 * @abstract Learned insights for the user. May be nil if no insights are available, or if Insights is turned off.
 */
@property (nullable, strong, nonatomic, readonly) RadarUserInsights *insights;

@end
