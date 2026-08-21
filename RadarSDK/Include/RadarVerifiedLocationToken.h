//
//  RadarVerifiedLocationToken.h
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent.h"
#import "RadarUser.h"
#import <Foundation/Foundation.h>

/**
 The wire format of a verified response token, controlled by a server-side project setting.

 @see https://radar.com/documentation/fraud
 */
typedef NS_ENUM(NSInteger, RadarTokenFormat) {
    /// A signed JSON Web Token (JWT). Verify the token server-side using your secret key.
    RadarTokenFormatJWS NS_SWIFT_NAME(jws) = 0,
    /// A signed JWT nested in an encrypted JWE. Opaque to the SDK; decrypt with your private key
    /// and verify against Radar's JWKS server-side.
    RadarTokenFormatJWE NS_SWIFT_NAME(jwe) = 1,
};

/**
 Represents a user's verified location.

 @see https://radar.com/documentation/fraud
 */
@interface RadarVerifiedLocationToken : NSObject

/**
 The user. `nil` when `format` is `RadarTokenFormatJWE`, since the payload only exists inside the encrypted token.
 */
@property (nullable, strong, nonatomic, readonly) RadarUser *user;

/**
 An array of events. `nil` when `format` is `RadarTokenFormatJWE`, since the payload only exists inside the encrypted token.
 */
@property (nullable, strong, nonatomic, readonly) NSArray<RadarEvent *> *events;

/**
 A signed JSON Web Token (JWT) containing the user and array of events. When `format` is `RadarTokenFormatJWE`, an encrypted
 JWE instead. Verify (and, for JWE, decrypt) the token server-side.
 */
@property (nullable, copy, nonatomic, readonly) NSString *token;

/**
 The datetime when the token expires.
 */
@property (nullable, copy, nonatomic, readonly) NSDate *expiresAt;

/**
 The number of seconds until the token expires.
 */
@property (assign, nonatomic, readonly) NSTimeInterval expiresIn;

/**
 A boolean indicating whether the user passed all jurisdiction and fraud detection checks.
 */
@property (assign, nonatomic, readonly) bool passed;

/**
 An array of failure reasons for jurisdiction and fraud detection checks. `nil` when `format` is
 `RadarTokenFormatJWE`, since the reasons only exist inside the encrypted token.
 */
@property (nullable, copy, nonatomic, readonly) NSArray<NSString *> *failureReasons;

/**
 The Radar ID of the location check.
 */
@property (nullable, copy, nonatomic, readonly) NSString *_id;

/**
 The wire format of the token. `RadarTokenFormatJWS` unless the server indicates otherwise.
 */
@property (assign, nonatomic, readonly) RadarTokenFormat format;

/**
 The full dictionary value of the token.
 */
@property (nullable, copy, nonatomic, readonly) NSDictionary *fullDict;

- (NSDictionary *_Nonnull)dictionaryValue;

@end
