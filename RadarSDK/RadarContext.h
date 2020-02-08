//
//  RadarContext.h
//  RadarSDK
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarGeofence.h"
#import "RadarPlace.h"
#import "RadarRegion.h"

/**
 TODO(coryp): RadarContext description and documentation reference

 @see https://radar.io/documentation
 */
@interface RadarContext : NSObject

/**
 A boolean indicating whether the location context was generated with your live API key.
 */
@property (assign, nonatomic, readonly) BOOL live;

/**
 An array of the geofences the location is in. May be `nil` or empty if the location is not in any geofences.
 
 @see https://radar.io/documentation/geofences
 */
@property (nullable, copy, nonatomic, readonly) NSArray<RadarGeofence *> *geofences;

/**
 The place a location is at. May be `nil` if the location is not at a place, or if Places is not enabled.
 
 @see https://radar.io/documentation/places
 */
@property (nullable, copy, nonatomic, readonly) RadarPlace *place;

/**
 The location's country. May be `nil` if country is not available or if Regions is not enabled.
 
 @see https://radar.io/documentation/regions
 */
@property (nullable, strong, nonatomic, readonly) RadarRegion *country;

/**
 The location's state. May be `nil` if state is not available or if Regions is not enabled.
 
 @see https://radar.io/documentation/regions
 */
@property (nullable, strong, nonatomic, readonly) RadarRegion *state;

/**
 The location's designated market area (DMA). May be `nil` if DMA is not available or if Regions is not enabled.
 
 @see https://radar.io/documentation/regions
 */
@property (nullable, strong, nonatomic, readonly) RadarRegion *dma;

/**
 The location's postal code. May be `nil` if postal code is not available or if Regions is not enabled.
 
 @see https://radar.io/documentation/regions
 */
@property (nullable, strong, nonatomic, readonly) RadarRegion *postalCode;

@end
