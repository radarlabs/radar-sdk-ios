//
//  RadarAddress.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarCoordinate.h"

// RadarAddressConfidence enum
typedef NS_ENUM(NSInteger, RadarAddressConfidence) {
    RadarAddressConfidenceExact,
    RadarAddressConfidenceInterpolated,
    RadarAddressConfidenceFallback,
    RadarAddressConfidenceNone
};

NS_ASSUME_NONNULL_BEGIN

@interface RadarAddress : NSObject

/**
 The location coordinate of the address.
 */
@property(nonnull, copy, nonatomic, readonly) RadarCoordinate *coordinate;

/**
 The fully formatted representation of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *formattedAddress;

/**
 The country of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *country;

/**
 The country code of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *countryCode;

/**
 The country flag of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *countryFlag;

/**
 The state of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *state;

/**
 The state code of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *stateCode;

/**
 The postal code of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *postalCode;

/**
 The city of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *city;

/**
 The borough of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *borough;

/**
 The county of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *county;

/**
 The neighborhood of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *neighborhood;

/**
 The number / house number of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *number;

/**
  Confidence in the address received from the API.
 */
@property(nonatomic, assign) enum RadarAddressConfidence confidence;

@end

NS_ASSUME_NONNULL_END
