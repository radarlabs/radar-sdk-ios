//
//  RadarRegion.h
//  RadarSDK
//
//  Copyright © 2019 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a region. For more information about Regions, see https://radar.io/documentation/regions.
 
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

@end

NS_ASSUME_NONNULL_END
