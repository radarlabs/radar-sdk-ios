//
//  RadarAutocompleteEnrichedAddress.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarAddressLocationDetails.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The enriched form of a selected address.

 Carries only these two fields. It is not a `RadarAddress`, and none of that type's other fields are returned.

 @see https://radar.com/documentation/api#autocomplete
 */
@interface RadarAutocompleteEnrichedAddress : NSObject

/**
 The formatted string representation of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *formattedAddress;

/**
 What address enrichment knows about the location.
 */
@property (nonatomic, readonly) RadarAddressLocationDetails *locationDetails;

- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
