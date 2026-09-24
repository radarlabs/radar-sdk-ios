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
