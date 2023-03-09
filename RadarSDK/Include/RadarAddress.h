//
//  RadarAddress.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarCoordinate.h"
#import <Foundation/Foundation.h>

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

// Verification status enum for RadarAddress with values 'V', 'P', 'A', 'R', and 'U'
typedef NS_ENUM(NSInteger, RadarAddressVerificationStatus) {
    /// Unknown
    RadarAddressVerificationStatusNone NS_SWIFT_NAME(none) = 0,
    /// Verified: complete match was made between the input data and a single record from the available reference data
    RadarAddressVerificationStatusVerified NS_SWIFT_NAME(verified) = 1,
    /// Partially verified: a partial match was made between the input data and a single record from the available reference data
    RadarAddressVerificationStatusPartiallyVerified NS_SWIFT_NAME(partiallyVerified) = 2,
    /// Ambiguous: more than one close reference data match
    RadarAddressVerificationStatusAmbiguous NS_SWIFT_NAME(ambiguous) = 3,
    /// Reverted: record could not be verified to the specified minimum acceptable level. The output fields will contain the input data
    RadarAddressVerificationStatusReverted NS_SWIFT_NAME(reverted) = 4,
    /// Unverified: unable to verify. The output fields will contain the input data
    RadarAddressVerificationStatusUnverified NS_SWIFT_NAME(unverified) = 5
};

NS_ASSUME_NONNULL_BEGIN

/**
 Represents an address.

 @see https://radar.com/documentation/api#geocoding
 */
@interface RadarAddress : NSObject

/**
 The location coordinate of the address.
 */
@property (assign, nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
 The formatted string representation of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *formattedAddress;

/**
 The name of the country of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *country;

/**
 The unique code of the country of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *countryCode;

/**
 The flag of the country of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *countryFlag;

/**
 The name of the DMA of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *dma;

/**
 The unique code of the DMA of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *dmaCode;

/**
 The name of the state of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *state;

/**
 The unique code of the state of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *stateCode;

/**
 The postal code of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *postalCode;

/**
 The city of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *city;

/**
 The borough of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *borough;

/**
 The county of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *county;

/**
 The neighborhood of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *neighborhood;

/**
 The street number of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *number;

/**
 The street name of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *street;

/**
 The label of the address.
 */
@property (nullable, copy, nonatomic, readonly) NSString *addressLabel;

/**
 The label of the place.
 */
@property (nullable, copy, nonatomic, readonly) NSString *placeLabel;

/**
The unit of the address.
*/
@property (nullable, copy, nonatomic, readonly) NSString *unit;

/**
The plus4 value for the zip of the address.
*/
@property (nullable, copy, nonatomic, readonly) NSString *plus4;

/**
The property type of the address.
*/
@property (nullable, copy, nonatomic, readonly) NSString *propertyType;

/**
The verification status of the address.
*/
@property (nonatomic, assign) enum RadarAddressVerificationStatus verificationStatus;

/**
  The confidence level of the geocoding result.
 */
@property (nonatomic, assign) enum RadarAddressConfidence confidence;

+ (NSArray<NSDictionary *> *_Nullable)arrayForAddresses:(NSArray<RadarAddress *> *_Nullable)addresses;
- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
