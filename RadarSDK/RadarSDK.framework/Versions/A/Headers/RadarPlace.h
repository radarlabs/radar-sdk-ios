//
//  RadarPlace.h
//  RadarSDK
//
//  Copyright © 2017 Radar. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "RadarChain.h"
#import "RadarCoordinate.h"

/**
 Represents a place. For more information about Places, see https://radar.io/documentation/places.
 
 @see https://radar.io/documentation/places
 */
@interface RadarPlace : NSObject

/**
 The Radar ID of the place.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_id;

/**
 The Facebook page ID of the place, if known.
 */
@property (nullable, copy, nonatomic, readonly) NSString *facebookId;

/**
 The Facebook page ID of the place, if known.
 */
@property (nullable, copy, nonatomic, readonly) NSString *facebookPlaceId;

/**
 The name of the place.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *name;

/**
 The categories of the place. For a full list of categories, see https://radar.io/documentation/places/categories.
 
 @see https://radar.io/documentation/places/categories
 */
@property (nonnull, copy, nonatomic, readonly) NSArray<NSString *> *categories;


/**
 The chain of the place, if known. May be `nil` for places without a chain. For a full list of chains, see https://radar.io/documentation/places/chains.
 
 @see https://radar.io/documentation/places/chains
 */
@property (nullable, strong, nonatomic, readonly) RadarChain *chain;

/**
 The location of the place.
 */
@property (nonnull, strong, nonatomic, readonly) RadarCoordinate *location;

/**
 The group for the place, if any. For a full list of groups, see https://radar.io/documentation/places/groups.
 
 @see https://radar.io/documentation/places/groups
 */
@property (nullable, strong, nonatomic, readonly) NSString *group;

/**
 The metadata for the place, if part of a group. For details of metadata fields see https://radar.io/documentation/places/groups.
 
 @see https://radar.io/documentation/places/groups
 */
@property (nullable, strong, nonatomic, readonly) NSDictionary *metadata;

/**
 Returns a boolean indicating whether the place is part of the specified chain.
 
 @return A boolean indicating whether the place is part of the specified the chain.
 **/
- (BOOL)isChain:(NSString *_Nullable)slug;

/**
 Returns a boolean indicating whether the place has the specified category.
 
 @return A boolean indicating whether the place has the specified category.
 **/
- (BOOL)hasCategory:(NSString *_Nullable)category;

@end
