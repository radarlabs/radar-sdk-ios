//
//  RadarAddressLocationDetails.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarAddressPlace.h"

NS_ASSUME_NONNULL_BEGIN

/**
 What address enrichment knows about a location.
 */
@interface RadarAddressLocationDetails : NSObject

/**
 How the location is used, or `unknown`.
 */
@property (copy, nonatomic, readonly) NSString *usage;

/**
 The dwelling type, `n/a` for usages that have none, or `unknown`.
 */
@property (copy, nonatomic, readonly) NSString *dwelling;

/**
 The grounds of the location.
 */
@property (copy, nonatomic, readonly) NSArray<NSString *> *grounds;

/**
 The places on the grounds of the location.
 */
@property (copy, nonatomic, readonly) NSArray<RadarAddressPlace *> *places;

- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
