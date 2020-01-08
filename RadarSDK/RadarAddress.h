//
//  RadarAddress.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarCoordinate.h"

/**
  The confidence levels for geocoding results.
 */
typedef NS_ENUM(NSInteger, RadarAddressConfidence) {
    /// Unknown
    RadarAddressConfidenceNone NS_SWIFT_NAME(none) = 0,
    /// Exact
    RadarAddressConfidenceExact NS_SWIFT_NAME(exact) = 1,
    /// Interpolated
    RadarAddressConfidenceInterpolated NS_SWIFT_NAME(interpolated) = 2,
    /// Fallback
    RadarAddressConfidenceFallback NS_SWIFT_NAME(fallback) = 3
};

NS_ASSUME_NONNULL_BEGIN

@interface RadarAddress : NSObject

/**
 The latitude and longitude of the address.
 */
@property(nonnull, copy, nonatomic, readonly) RadarCoordinate *coordinate;

/**
 The formatted string representation of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *formattedAddress;

/**
 The name of the country of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *country;

/**
 The unique code of the country of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *countryCode;

/**
 The flag of the country of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *countryFlag;

/**
 The name of the address.
 */
@property(nullable, copy, nonatomic, readonly) NSString *state;

/**
 The unique code of the state of the address.
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
 The number of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *number;

/**
  The confidence level of the geocoding result.
 */
@property (nonatomic, assign) enum RadarAddressConfidence confidence;

@end

NS_ASSUME_NONNULL_END
