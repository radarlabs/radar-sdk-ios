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

@property (assign, nonatomic) BOOL started;

+ (instancetype)sharedInstance;
- (void)trackVerifiedWithCompletionHandler:(RadarTrackVerifiedCompletionHandler _Nullable)completionHandler;
- (void)trackVerifiedWithBeacons:(BOOL)beacons desiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy reason:(NSString *_Nullable)reason transactionId:(NSString *_Nullable)transactionId completionHandler:(RadarTrackVerifiedCompletionHandler _Nullable)completionHandler;
- (void)startTrackingVerifiedWithInterval:(NSTimeInterval)interval beacons:(BOOL)beacons;
- (void)stopTrackingVerified;
- (void)getVerifiedLocationTokenWithBeacons:(BOOL)beacons desiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarTrackVerifiedCompletionHandler _Nullable)completionHandler;
- (void)clearVerifiedLocationToken;
- (void)setExpectedJurisdictionWithCountryCode:(NSString *)countryCode stateCode:(NSString *)stateCode;

@end

NS_ASSUME_NONNULL_END
