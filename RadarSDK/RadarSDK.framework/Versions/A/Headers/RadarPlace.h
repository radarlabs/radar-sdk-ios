//
//  RadarPlace.h
//  RadarSDK
//
//  Copyright © 2017 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarChain.h"

@interface RadarPlace : NSObject

/**
 * @abstract The unique ID for the place, provided by Radar.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_id;

/**
 * @abstract A Facebook ID for the place, if known.
 */
@property (nullable, copy, nonatomic, readonly) NSString *facebookId;

/**
 * @abstract The name of the place.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *name;

/**
 * @abstract The categories of the place.
 */
@property (nonnull, copy, nonatomic, readonly) NSArray<NSString *> *categories;


/**
 * @abstract The chain of the place, if known.
 */
@property (nullable, strong, nonatomic, readonly) RadarChain *chain;

/**
 @abstract Returns a boolean indicating whether the place is part of the specified chain.
 @return A boolean indicating whether the place is part of the specified the chain.
 **/
- (BOOL)isChain:(NSString *_Nullable)slug;

/**
 @abstract Returns a boolean indicating whether the place has the specified category.
 @return A boolean indicating whether the place has the specified category.
 **/
- (BOOL)hasCategory:(NSString *_Nullable)category;

@end
