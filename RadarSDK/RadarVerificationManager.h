//
//  RadarVerificationManager.h
//  RadarSDK
//
//  Created by Nick Patrick on 1/3/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarVerificationManager : NSObject

typedef void (^_Nullable RadarVerificationCompletionHandler)(NSString *_Nullable attestationString, NSString *_Nullable keyId, NSString *_Nullable attestationError);

+ (instancetype)sharedInstance;
- (void)trackVerifiedWithCompletionHandler:(RadarTrackVerifiedCompletionHandler _Nullable)completionHandler;
- (void)trackVerifiedWithBeacons:(BOOL)beacons completionHandler:(RadarTrackVerifiedCompletionHandler _Nullable)completionHandler;
- (void)startTrackingVerifiedWithInterval:(NSTimeInterval)interval beacons:(BOOL)beacons;
- (void)stopTrackingVerified;
- (void)getVerifiedLocationTokenWithCompletionHandler:(RadarTrackVerifiedCompletionHandler _Nullable)completionHandler;
- (void)setExpectedJurisdictionWithCountryCode:(NSString *)countryCode stateCode:(NSString *)stateCode;
- (void)getAttestationWithNonce:(NSString *)nonce completionHandler:(RadarVerificationCompletionHandler)completionHandler;
- (BOOL)isJailbroken;

@end

NS_ASSUME_NONNULL_END
