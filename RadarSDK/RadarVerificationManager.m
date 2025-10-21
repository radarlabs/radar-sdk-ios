//
//  RadarVerificationManager.m
//  RadarSDK
//
//  Created by Nick Patrick on 1/3/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Network;

#import "RadarVerificationManager.h"

#import "Radar+Internal.h"
#import "RadarAPIClient.h"
#import "RadarBeaconManager.h"
#import "RadarDelegateHolder.h"
#import "RadarLocationManager.h"
#import "RadarLogger.h"
#import "RadarState.h"
#import "RadarUtils.h"
#import "RadarSDKFraudProtocol.h"

@interface RadarVerificationManager ()

@property (assign, nonatomic) NSTimeInterval startedInterval;
@property (assign, nonatomic) BOOL startedBeacons;
@property (strong, nonatomic) RadarVerifiedLocationToken *lastToken;
@property (assign, nonatomic) NSTimeInterval lastTokenSystemUptime;
@property (assign, nonatomic) BOOL lastTokenBeacons;
@property (copy, nonatomic) NSString *expectedCountryCode;
@property (copy, nonatomic) NSString *expectedStateCode;

@end

@implementation RadarVerificationManager

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    if ([NSThread isMainThread]) {
        dispatch_once(&once, ^{
            sharedInstance = [self new];
        });
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_once(&once, ^{
                sharedInstance = [self new];
            });
        });
    }
    return sharedInstance;
}

- (void)trackVerifiedWithCompletionHandler:(RadarTrackVerifiedCompletionHandler)completionHandler {
    [self trackVerifiedWithBeacons:NO desiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium reason:nil transactionId:nil completionHandler:completionHandler];
}

- (void)trackVerifiedWithBeacons:(BOOL)beacons desiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy reason:(NSString *)reason transactionId:(NSString *)transactionId completionHandler:(RadarTrackVerifiedCompletionHandler)completionHandler {
    if (!reason) {
        reason = @"manual";
    }
    
    BOOL lastTokenBeacons = beacons;
    
    [[RadarAPIClient sharedInstance]
     getConfigForUsage:@"verify"
     verified:YES
     completionHandler:^(RadarStatus status, RadarConfig *_Nullable config) {
        if (status != RadarStatusSuccess || !config) {
            [RadarUtils runOnMainThread:^{
                if (status != RadarStatusSuccess) {
                    [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];
                }
                
                if (completionHandler) {
                    completionHandler(status, nil);
                }
            }];
            
            return;
        }
        
        [[RadarLocationManager sharedInstance]
         getLocationWithDesiredAccuracy:desiredAccuracy
         completionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
            if (status != RadarStatusSuccess) {
                [RadarUtils runOnMainThread:^{
                    [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];
                    
                    if (completionHandler) {
                        completionHandler(status, nil);
                    }
                }];
                
                return;
            }
            
            Class RadarSDKFraud = NSClassFromString(@"RadarSDKFraud");
            if (!RadarSDKFraud) {
                [RadarUtils runOnMainThread:^{
                    [[RadarDelegateHolder sharedInstance] didFailWithStatus:RadarStatusErrorUnknown];
                    
                    if (completionHandler) {
                        // todo: add a new error type for missing modules?
                        completionHandler(RadarStatusErrorUnknown, nil);
                    }
                }];
                return;
            }
            
            [[RadarSDKFraud sharedInstance] getAttestationWithNonce:config.nonce
                        completionHandler:^(NSString *_Nullable attestationString, NSString *_Nullable keyId, NSString *_Nullable attestationError) {
                void (^callTrackAPI)(NSArray<RadarBeacon *> *_Nullable) = ^(NSArray<RadarBeacon *> *_Nullable beacons) {
                    [[RadarAPIClient sharedInstance]
                     trackWithLocation:location
                     stopped:RadarState.stopped
                     foreground:[RadarUtils foreground]
                     source:RadarLocationSourceForegroundLocation
                     replayed:NO
                     beacons:beacons
                     indoorScan:nil
                     verified:YES
                     attestationString:attestationString
                     keyId:keyId
                     attestationError:attestationError
                     encrypted:NO
                     expectedCountryCode:self.expectedCountryCode
                     expectedStateCode:self.expectedStateCode
                     reason:reason
                     transactionId:transactionId
                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events,
                                         RadarUser *_Nullable user, NSArray<RadarGeofence *> *_Nullable nearbyGeofences,
                                         RadarConfig *_Nullable config, RadarVerifiedLocationToken *_Nullable token) {
                        if (status == RadarStatusSuccess && config != nil) {
                            [[RadarLocationManager sharedInstance] updateTrackingFromMeta:config.meta];
                        }
                        
                        if (token) {
                            self.lastToken = token;
                            self.lastTokenSystemUptime = [NSProcessInfo processInfo].systemUptime;
                            self.lastTokenBeacons = lastTokenBeacons;
                        }
                        
                        [RadarUtils runOnMainThread:^{
                            if (status != RadarStatusSuccess) {
                                [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];
                            }
                            
                            if (completionHandler) {
                                completionHandler(status, token);
                            }
                        }];
                    }];
                };
                
                if (beacons) {
                    [[RadarAPIClient sharedInstance]
                     searchBeaconsNear:location
                     radius:1000
                     limit:10
                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons,
                                         NSArray<NSString *> *_Nullable beaconUUIDs) {
                        if (beaconUUIDs && beaconUUIDs.count) {
                            [RadarUtils runOnMainThread:^{
                                [[RadarBeaconManager sharedInstance]
                                 rangeBeaconUUIDs:beaconUUIDs
                                 completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable beacons) {
                                    if (status != RadarStatusSuccess || !beacons) {
                                        callTrackAPI(nil);
                                        
                                        return;
                                    }
                                    
                                    callTrackAPI(beacons);
                                }];
                            }];
                        } else if (beacons && beacons.count) {
                            [RadarUtils runOnMainThread:^{
                                [[RadarBeaconManager sharedInstance]
                                 rangeBeacons:beacons
                                 completionHandler:^(RadarStatus status, NSArray<RadarBeacon *> *_Nullable beacons) {
                                    if (status != RadarStatusSuccess || !beacons) {
                                        callTrackAPI(nil);
                                        
                                        return;
                                    }
                                    
                                    callTrackAPI(beacons);
                                }];
                            }];
                        } else {
                            callTrackAPI(@[]);
                        }
                    }];
                } else {
                    callTrackAPI(nil);
                }
            }];
        }];
    }];
}

- (void)intervalFired {
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Token request interval fired"];
    
    [self callTrackVerifiedWithReason:@"interval"];
}

- (void)scheduleNextIntervalWithLastToken {
    NSTimeInterval minInterval = self.startedInterval;
    
    if (self.lastToken) {
        NSTimeInterval lastTokenElapsed = [NSProcessInfo processInfo].systemUptime - self.lastTokenSystemUptime;
        
        // if expiresIn - lastTokenElapsed is shorter than interval, override interval
        minInterval = MIN(self.lastToken.expiresIn - lastTokenElapsed, self.startedInterval);
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Calculated next interval | minInterval = %f; expiresIn = %f; lastTokenElapsed = %f, startedInterval = %f", minInterval, self.lastToken.expiresIn, lastTokenElapsed,  self.startedInterval]];
    }
    
    // re-request early to maximize the likelihood that a cached token is available
    NSTimeInterval interval = minInterval - 10;
    
    // min interval is 10 seconds
    if (interval < 10) {
        interval = 10;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(intervalFired) object:nil];
    
    if (!self.started) {
        return;
    }
    
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Requesting token again in %f seconds", interval]];
    
    [self performSelector:@selector(intervalFired) withObject:nil afterDelay:interval];
}

- (void)callTrackVerifiedWithReason:(NSString *)reason {
    if (!self.started) {
        return;
    }
    
    [self trackVerifiedWithBeacons:self.startedBeacons desiredAccuracy:RadarTrackingOptionsDesiredAccuracyHigh reason:reason transactionId:nil completionHandler:^(RadarStatus status, RadarVerifiedLocationToken *_Nullable token) {
        [self scheduleNextIntervalWithLastToken];
    }];
}

- (void)startTrackingVerifiedWithInterval:(NSTimeInterval)interval beacons:(BOOL)beacons {
    Class RadarSDKFraud = NSClassFromString(@"RadarSDKFraud");
    if (!RadarSDKFraud) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Skipping startTrackingVerified: RadarSDKFraud submodule not available"];
        return;
    }

    [self stopTrackingVerified];

    self.started = YES;
    self.startedInterval = interval;
    self.startedBeacons = beacons;
    
    [[RadarSDKFraud sharedInstance] startIPMonitoringWithCallback:^(NSString *reason) {
        [self callTrackVerifiedWithReason:reason];
    }];
    
    if ([self isLastTokenValid]) {
        [self scheduleNextIntervalWithLastToken];
    } else {
        [self callTrackVerifiedWithReason:@"start"];
    }
}

- (void)stopTrackingVerified {
    Class RadarSDKFraud = NSClassFromString(@"RadarSDKFraud");
    if (!RadarSDKFraud) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Skipping stopTrackingVerified: RadarSDKFraud submodule not available"];
        return;
    }
    
    self.started = NO;
    
    // Stop IP monitoring in RadarSDKFraud
    [[RadarSDKFraud sharedInstance] stopIPMonitoring];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(intervalFired) object:nil];
}

- (void)getVerifiedLocationTokenWithBeacons:(BOOL)beacons desiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy completionHandler:(RadarTrackVerifiedCompletionHandler)completionHandler {
    if ([self isLastTokenValid]) {
        [Radar flushLogs];
        
        return completionHandler(RadarStatusSuccess, self.lastToken);
    }
    
    [self trackVerifiedWithBeacons:beacons desiredAccuracy:desiredAccuracy reason:@"last_token_invalid" transactionId:nil completionHandler:completionHandler];
}

- (void)clearVerifiedLocationToken {
    self.lastToken = nil;
}

- (BOOL)isLastTokenValid {
    if (!self.lastToken) {
        return NO;
    }

    NSTimeInterval lastTokenElapsed = [NSProcessInfo processInfo].systemUptime - self.lastTokenSystemUptime;
    double lastDistanceToStateBorder = -1;
    if (self.lastToken.user && self.lastToken.user.state) {
        lastDistanceToStateBorder = self.lastToken.user.state.distanceToBorder;
    }

    BOOL lastTokenValid =
        (lastTokenElapsed < self.lastToken.expiresIn) &&
        self.lastToken.passed &&
        (lastDistanceToStateBorder > 1609);

    if (lastTokenValid) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Last token valid | lastToken.expiresIn = %f; lastTokenElapsed = %f; lastToken.passed = %d; lastDistanceToStateBorder = %f", self.lastToken.expiresIn, lastTokenElapsed, self.lastToken.passed, lastDistanceToStateBorder]];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Last token invalid | lastToken.expiresIn = %f; lastTokenElapsed = %f; lastToken.passed = %d; lastDistanceToStateBorder = %f", self.lastToken.expiresIn, lastTokenElapsed, self.lastToken.passed, lastDistanceToStateBorder]];
    }

    return lastTokenValid;
}

- (void)setExpectedJurisdictionWithCountryCode:(NSString *)countryCode stateCode:(NSString *)stateCode {
    self.expectedCountryCode = countryCode;
    self.expectedStateCode = stateCode;
}


@end
