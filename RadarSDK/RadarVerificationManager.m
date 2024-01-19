//
//  RadarVerificationManager.m
//  RadarSDK
//
//  Created by Nick Patrick on 1/3/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <CommonCrypto/CommonCrypto.h>
#import <DeviceCheck/DeviceCheck.h>
#import <Foundation/Foundation.h>
@import Network;

#import "RadarVerificationManager.h"

#import "RadarAPIClient.h"
#import "RadarBeaconManager.h"
#import "RadarLocationManager.h"
#import "RadarLogger.h"
#import "RadarState.h"
#import "RadarUtils.h"

@interface RadarVerificationManager ()

@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic, retain) nw_path_monitor_t monitor;

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

- (void)trackVerifiedWithCompletionHandler:(RadarTrackCompletionHandler)completionHandler {
    [self trackVerifiedWithBeacons:NO completionHandler:completionHandler];
}

- (void)trackVerifiedWithBeacons:(BOOL)beacons completionHandler:(RadarTrackCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance]
        getConfigForUsage:@"verify"
                 verified:YES
        completionHandler:^(RadarStatus status, RadarConfig *_Nullable config) {
            [[RadarLocationManager sharedInstance]
                getLocationWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyHigh
                             completionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
                                 if (status != RadarStatusSuccess) {
                                     if (completionHandler) {
                                         [RadarUtils runOnMainThread:^{
                                             completionHandler(status, nil, nil, nil);
                                         }];
                                     }

                                     return;
                                 }

                                 [self getAttestationWithNonce:config.nonce
                                             completionHandler:^(NSString *_Nullable attestationString, NSString *_Nullable keyId, NSString *_Nullable attestationError) {
                                                 void (^callTrackAPI)(NSArray<RadarBeacon *> *_Nullable) = ^(NSArray<RadarBeacon *> *_Nullable beacons) {
                                                     [[RadarAPIClient sharedInstance]
                                                         trackWithLocation:location
                                                                   stopped:RadarState.stopped
                                                                foreground:[RadarUtils foreground]
                                                                    source:RadarLocationSourceForegroundLocation
                                                                  replayed:NO
                                                                   beacons:beacons
                                                                  verified:YES
                                                         attestationString:attestationString
                                                                     keyId:keyId
                                                          attestationError:attestationError
                                                                 encrypted:NO
                                                         completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events,
                                                                             RadarUser *_Nullable user, NSArray<RadarGeofence *> *_Nullable nearbyGeofences,
                                                                             RadarConfig *_Nullable config, NSString *_Nullable token) {
                                                             if (status == RadarStatusSuccess && config != nil) {
                                                                 [[RadarLocationManager sharedInstance] updateTrackingFromMeta:config.meta];
                                                             }
                                                             if (completionHandler) {
                                                                 [RadarUtils runOnMainThread:^{
                                                                     completionHandler(status, location, events, user);
                                                                 }];
                                                             }
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
                                                                 callTrackAPI(nil);
                                                             }
                                                         }];
                                                 } else {
                                                     callTrackAPI(nil);
                                                 }
                                             }];
                             }];
        }];
}

- (void)trackVerifiedTokenWithCompletionHandler:(RadarTrackTokenCompletionHandler)completionHandler {
    [self trackVerifiedTokenWithBeacons:NO completionHandler:completionHandler];
}

- (void)trackVerifiedTokenWithBeacons:(BOOL)beacons completionHandler:(RadarTrackTokenCompletionHandler)completionHandler {
    [[RadarAPIClient sharedInstance]
        getConfigForUsage:@"verify"
                 verified:YES
        completionHandler:^(RadarStatus status, RadarConfig *_Nullable config) {
            [[RadarLocationManager sharedInstance]
                getLocationWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyHigh
                             completionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
                                 if (status != RadarStatusSuccess) {
                                     if (completionHandler) {
                                         [RadarUtils runOnMainThread:^{
                                             completionHandler(status, nil);
                                         }];
                                     }

                                     return;
                                 }

                                 [self getAttestationWithNonce:config.nonce
                                             completionHandler:^(NSString *_Nullable attestationString, NSString *_Nullable keyId, NSString *_Nullable attestationError) {
                                                 void (^callTrackAPI)(NSArray<RadarBeacon *> *_Nullable) = ^(NSArray<RadarBeacon *> *_Nullable beacons) {
                                                     [[RadarAPIClient sharedInstance]
                                                         trackWithLocation:location
                                                                   stopped:RadarState.stopped
                                                                foreground:[RadarUtils foreground]
                                                                    source:RadarLocationSourceForegroundLocation
                                                                  replayed:NO
                                                                   beacons:beacons
                                                                  verified:YES
                                                         attestationString:attestationString
                                                                     keyId:keyId
                                                          attestationError:attestationError
                                                                 encrypted:YES
                                                         completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events,
                                                                             RadarUser *_Nullable user, NSArray<RadarGeofence *> *_Nullable nearbyGeofences,
                                                                             RadarConfig *_Nullable config, NSString *_Nullable token) {
                                                             if (status == RadarStatusSuccess && config != nil) {
                                                                 [[RadarLocationManager sharedInstance] updateTrackingFromMeta:config.meta];
                                                             }
                                                             if (completionHandler) {
                                                                 [RadarUtils runOnMainThread:^{
                                                                     completionHandler(status, token);
                                                                 }];
                                                             }
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
                                                                 callTrackAPI(nil);
                                                             }
                                                         }];
                                                 } else {
                                                     callTrackAPI(nil);
                                                 }
                                             }];
                             }];
        }];
}

- (void)startTrackingVerified:(BOOL)token interval:(NSTimeInterval)interval beacons:(BOOL)beacons {
    if (@available(iOS 12.0, *)) {
        if (!_monitor) {
            _monitor = nw_path_monitor_create();

            nw_path_monitor_set_queue(_monitor, dispatch_get_main_queue());

            nw_path_monitor_set_update_handler(_monitor, ^(nw_path_t path) {
                if (nw_path_get_status(path) == nw_path_status_satisfied) {
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Network connected"];

                    if (token) {
                        [self trackVerifiedTokenWithBeacons:beacons completionHandler:nil];
                    } else {
                        [self trackVerifiedWithBeacons:beacons completionHandler:nil];
                    }
                } else {
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Network disconnected"];
                }
            });

            nw_path_monitor_start(_monitor);
        }
    }

    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                     repeats:YES
                                                       block:^(NSTimer *_Nonnull timer) {
                                                           [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Timer fired"];

                                                           if (token) {
                                                               [self trackVerifiedTokenWithBeacons:beacons completionHandler:nil];
                                                           } else {
                                                               [self trackVerifiedWithBeacons:beacons completionHandler:nil];
                                                           }
                                                       }];
    }
}

- (void)getAttestationWithNonce:(NSString *)nonce completionHandler:(RadarVerificationCompletionHandler)completionHandler {
    if (@available(iOS 14.0, *)) {
        DCAppAttestService *service = [DCAppAttestService sharedService];

        if (!service.isSupported) {
            completionHandler(nil, nil, @"Service unsupported");

            return;
        }

        if (!nonce) {
            completionHandler(nil, nil, @"Missing nonce");

            return;
        }

        [service generateKeyWithCompletionHandler:^(NSString *_Nullable keyId, NSError *_Nullable error) {
            if (error) {
                completionHandler(nil, nil, error.localizedDescription);

                return;
            }

            NSData *clientData = [nonce dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableData *clientDataHash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
            CC_SHA256([clientData bytes], (CC_LONG)[clientData length], [clientDataHash mutableBytes]);

            [service attestKey:keyId
                   clientDataHash:clientDataHash
                completionHandler:^(NSData *_Nullable attestationObject, NSError *_Nullable error) {
                    NSString *assertionString = [attestationObject base64EncodedStringWithOptions:0];

                    completionHandler(assertionString, keyId, nil);
                }];
        }];
    } else {
        completionHandler(nil, nil, @"OS unsupported");
    }
}

@end
