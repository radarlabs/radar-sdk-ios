//
//  RadarTripOptions.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An options class used to configure trip tracking.

 @see https://radar.io/documentation/sdk/ios
 */
@interface RadarTripOptions : NSObject

- (instancetype)initWithExternalId:(NSString *_Nonnull)externalId;

/**
 A stable unique ID for the trip.
 */
@property (nonnull, nonatomic, copy) NSString *externalId;

/**
 An optional set of custom key-value pairs for the trip.
 */
@property (nullable, nonatomic, copy) NSDictionary *metadata;

/**
 For trips with a destination, the tag of the destination geofence.
 */
@property (nullable, nonatomic, copy) NSString *destinationGeofenceTag;

/**
 For trips with a destination, the external ID of the destination geofence.
 */
@property (nullable, nonatomic, copy) NSString *destinationGeofenceExternalId;

/**
 For trips with a destination, the travel mode.
 */
@property (nonatomic, assign) RadarRouteMode mode;

+ (RadarTripOptions *)tripOptionsFromDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
