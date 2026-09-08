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
- (void)updateMonitoringState;
- (void)getVerifiedLocationTokenWithBeacons:(BOOL)beacons desiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarTrackVerifiedCompletionHandler _Nullable)completionHandler;
- (void)clearVerifiedLocationToken;
- (void)setExpectedJurisdictionWithCountryCode:(NSString *)countryCode stateCode:(NSString *)stateCode;
- (BOOL)isSharing;
- (void)clearSharing;

@end

// duplicate interface, with swift implementations
@interface RadarVerificationmanagerSwift : RadarVerificationManager
@end

@protocol RadarVerificationManagerSwiftHost

@property (assign, nonatomic) NSTimeInterval startedInterval;
@property (assign, nonatomic) BOOL startedBeacons;
@property (strong, nonatomic) NSTimer *intervalTimer;
@property (nonatomic, retain) nw_path_monitor_t monitor;
@property (strong, nonatomic) RadarVerifiedLocationToken *lastToken;
@property (assign, nonatomic) NSTimeInterval lastTokenSystemUptime;
@property (assign, nonatomic) BOOL lastTokenBeacons;
@property (strong, nonatomic) NSString *lastIPs;
@property (assign, nonatomic) NSTimeInterval lastIPChangeDeliveredAt;
@property (copy, nonatomic) NSString *expectedCountryCode;
@property (copy, nonatomic) NSString *expectedStateCode;

@end


NS_ASSUME_NONNULL_END
