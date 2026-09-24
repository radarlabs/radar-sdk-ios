//
//  RadarExpectedAddress.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The confidence levels for a match between the user's location and their expected address.
 */
typedef NS_ENUM(NSInteger, RadarExpectedAddressConfidence) {
    /// Unknown
    RadarExpectedAddressConfidenceUnknown NS_SWIFT_NAME(unknown),
    /// Low
    RadarExpectedAddressConfidenceLow NS_SWIFT_NAME(low),
    /// Medium
    RadarExpectedAddressConfidenceMedium NS_SWIFT_NAME(medium),
    /// High
    RadarExpectedAddressConfidenceHigh NS_SWIFT_NAME(high)
};

/**
 Represents a comparison between the user's location and the expected address set with `setExpectedAddress:`.
 */
@interface RadarExpectedAddress : NSObject

/**
 The user's expected address, as passed to `setExpectedAddress:`.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *expectedAddress;

/**
 The formatted expected address, as geocoded by Radar. May be `nil` if the expected address could not be geocoded.
 */
@property (nullable, copy, nonatomic, readonly) NSString *formattedAddress;

/**
 The latitude of the geocoded expected address. May be `nil` if the expected address could not be geocoded.
 */
@property (nullable, strong, nonatomic, readonly) NSNumber *latitude;

/**
 The longitude of the geocoded expected address. May be `nil` if the expected address could not be geocoded.
 */
@property (nullable, strong, nonatomic, readonly) NSNumber *longitude;

/**
 A boolean indicating whether the user is at their expected address.
 */
@property (assign, nonatomic, readonly) BOOL atAddress;

/**
 The confidence of the match between the user's location and their expected address. May be
 `RadarExpectedAddressConfidenceUnknown` if confidence is not available.
 */
@property (assign, nonatomic, readonly) RadarExpectedAddressConfidence confidence;

/**
 The distance in meters between the user's location and their expected address. May be `nil` if the expected
 address could not be geocoded.
 */
@property (nullable, strong, nonatomic, readonly) NSNumber *distance;

- (NSDictionary *_Nonnull)dictionaryValue;

@end
