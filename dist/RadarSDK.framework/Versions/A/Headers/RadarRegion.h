//
//  RadarRegion.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a region.

 @see https://radar.io/documentation/regions
 */
@interface RadarRegion : NSObject

/**
 The Radar ID of the region.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_id;

/**
 The name of the region.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *name;

/**
 The unique code for the region.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *code;

/**
 The type of the region.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *type;

/**
 The optional flag of the region.
 */
@property (nullable, copy, nonatomic, readonly) NSString *flag;

- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
