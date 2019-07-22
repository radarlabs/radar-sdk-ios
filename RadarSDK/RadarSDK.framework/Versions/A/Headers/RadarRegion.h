//
//  RadarRegion.h
//  RadarSDK
//
//  Copyright © 2019 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a change in user state. For more information, see https://radar.io/documentation.
 
 @see https://radar.io/documentation
 */
@interface RadarRegion : NSObject

/**
 The id of the region.
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
 The type of region.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *type;

@end

NS_ASSUME_NONNULL_END
