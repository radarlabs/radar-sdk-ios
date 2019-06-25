//
//  RadarChain.h
//  RadarSDK
//
//  Copyright © 2017 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Represents the chain of a place. For more information about Places, see https://radar.io/documentation/places.
 
 @see https://radar.io/documentation/places
 */
@interface RadarChain : NSObject

/**
 The unique ID of the chain. For a full list of chains, see https://radar.io/documentation/places/chains.
 
 @see https://radar.io/documentation/places/chains
 */
@property (nonnull, copy, nonatomic, readonly) NSString *slug;

/**
 The name of the chain. For a full list of chains, see https://radar.io/documentation/places/chains.
 
 @see https://radar.io/documentation/places/chains
 */
@property (nonnull, copy, nonatomic, readonly) NSString *name;

/**
 The external ID of the chain.
 */
@property (nullable, copy, nonatomic, readonly) NSString *externalId;

/**
 The optional set of custom key-value pairs for the chain.
 */
@property (nullable, copy, nonatomic, readonly) NSDictionary *metadata;

@end
