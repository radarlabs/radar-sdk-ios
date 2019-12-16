//
//  RadarAddress.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarAddressConfidence.h"
#import "RadarCoordinate.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarAddress : NSObject

/**
 The location coordinate of the user.
 */
@property(nonnull, copy, nonatomic, readonly) RadarCoordinate *coordinate;

/**
 The formatted address of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *formattedAddress;

/**
 The country of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *country;

/**
 The countryCode of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *countryCode;

/**
 The country flag of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *countryFlag;

/**
 The state of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *state;

/**
 The state code of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *stateCode;

/**
 The postalCode of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *postalCode;

/**
 The city of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *city;

/**
 The borough of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *borough;

/**
 The county of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *county;

/**
 The neighborhood of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *neighborhood;

/**
 The address / house number of the user.
 */
@property(nullable, copy, nonatomic, readonly) NSString *number;

/**
  Confidence in the address received from the API.
 */
@property(nonatomic, assign) enum RadarAddressConfidence confidence;

@end

NS_ASSUME_NONNULL_END
