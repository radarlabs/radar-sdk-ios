//
//  RadarChain.h
//  RadarSDK
//
//  Copyright © 2017 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadarChain : NSObject

/**
 * @abstract A human-readable unique ID for the chain, provided by Radar.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *slug;

/**
 * @abstract The name of the chain.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *name;

@end
