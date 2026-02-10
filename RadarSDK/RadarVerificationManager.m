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
#import <Security/Security.h>
#import <objc/runtime.h>
@import Network;

#import "RadarVerificationManager.h"

#import "Radar+Internal.h"
#import "RadarAPIClient.h"
#import "RadarBeaconManager.h"
#import "RadarDelegateHolder.h"
#import "RadarLocationManager.h"
#import "RadarLogger.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarUtils.h"

#include <dlfcn.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <mach-o/dyld.h>
#include <sys/stat.h>
#include <stdio.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

@interface RadarVerificationManager ()

@property (assign, nonatomic) NSTimeInterval startedInterval;
@property (assign, nonatomic) BOOL startedBeacons;
@property (strong, nonatomic) NSTimer *intervalTimer;
@property (nonatomic, retain) nw_path_monitor_t monitor;
@property (strong, nonatomic) RadarVerifiedLocationToken *lastToken;
@property (assign, nonatomic) NSTimeInterval lastTokenSystemUptime;
@property (assign, nonatomic) BOOL lastTokenBeacons;
@property (strong, nonatomic) NSString *lastIPs;
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
        
        [self getChallengeWithCompletionHandler:^(NSString *_Nullable challenge, NSString *_Nullable keyId, NSString *_Nullable error) {
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
                    keyId:keyId
                    challenge:challenge
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
    [self stopTrackingVerified];
    
    self.started = YES;
    self.startedInterval = interval;
    self.startedBeacons = beacons;
    
    if (!_monitor) {
        _monitor = nw_path_monitor_create();
        
        nw_path_monitor_set_queue(_monitor, dispatch_get_main_queue());
        
        nw_path_monitor_set_update_handler(_monitor, ^(nw_path_t path) {
            if (nw_path_get_status(path) == nw_path_status_satisfied) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Network connected"];
            } else {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Network disconnected"];
            }
            
            NSString *ips = [self getIPs];
            BOOL changed = NO;
            
            if (!self.lastIPs) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"First time getting IPs | ips = %@", ips]];
                changed = NO;
            } else if (!ips || [ips isEqualToString:@"error"]) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error getting IPs | ips = %@", ips]];
                changed = YES;
            } else if (![ips isEqualToString:self.lastIPs]) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"IPs changed | ips = %@; lastIPs = %@", ips, self.lastIPs]];
                changed = YES;
            } else {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"IPs unchanged"];
            }
            self.lastIPs = ips;
            
            if (changed) {
                [self callTrackVerifiedWithReason:@"ip_change"];
            }
        });
        nw_path_monitor_start(_monitor);
    }
    
    if ([self isLastTokenValid]) {
        [self scheduleNextIntervalWithLastToken];
    } else {
        [self callTrackVerifiedWithReason:@"start"];
    }
}

- (void)stopTrackingVerified {
    self.started = NO;
    
    if (_monitor) {
        nw_path_monitor_cancel(_monitor);
    }
    
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

- (void)getAttestationWithChallenge:(NSString *)challenge completionHandler:(RadarVerificationCompletionHandler)completionHandler {
    if (@available(iOS 14.0, *)) {
        DCAppAttestService *service = [DCAppAttestService sharedService];

        if (!service.isSupported) {
            completionHandler(nil, nil, @"Service unsupported");

            return;
        }

        if (!challenge) {
            completionHandler(nil, nil, @"Missing challenge");

            return;
        }

        // Generate new key and attestation (first-time)
        [service generateKeyWithCompletionHandler:^(NSString *_Nullable keyId, NSError *_Nullable error) {
            if (error) {
                completionHandler(nil, nil, error.localizedDescription);

                return;
            }

            NSData *clientData = [challenge dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableData *clientDataHash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
            CC_SHA256([clientData bytes], (CC_LONG)[clientData length], [clientDataHash mutableBytes]);

            [service attestKey:keyId
                   clientDataHash:clientDataHash
                completionHandler:^(NSData *_Nullable attestationObject, NSError *_Nullable error) {
                    if (error) {
                        completionHandler(nil, nil, error.localizedDescription);
                        return;
                    }
                
                    // Store the keyId for future use
                    [self storeAppAttestKeyId:keyId];

                    NSString *attestationString = [attestationObject base64EncodedStringWithOptions:0];

                    completionHandler(attestationString, keyId, nil);
                }];
        }];
    } else {
        completionHandler(nil, nil, @"OS unsupported");
    }
}

- (void)getAssertionWithBodyData:(NSData *)bodyData completionHandler:(RadarVerificationCompletionHandler)completionHandler {
    if (@available(iOS 14.0, *)) {
        DCAppAttestService *service = [DCAppAttestService sharedService];

        if (!service.isSupported) {
            completionHandler(nil, nil, @"Service unsupported");

            return;
        }

        if (!bodyData || bodyData.length == 0) {
            completionHandler(nil, nil, @"Invalid bodyData");

            return;
        }

        // Get existing keyId for assertion - key must exist at this point
        NSString *existingKeyId = [self appAttestKeyId];
        
        if (!existingKeyId) {
            completionHandler(nil, nil, @"No key exists for assertion");
            return;
        }

        // Hash the body data with SHA256 (challenge is inside the body)
        NSMutableData *bodyHash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
        CC_SHA256([bodyData bytes], (CC_LONG)[bodyData length], [bodyHash mutableBytes]);
        
        [service generateAssertion:existingKeyId
                   clientDataHash:bodyHash
                completionHandler:^(NSData *_Nullable assertionObject, NSError *_Nullable error) {
            if (error) {
                completionHandler(nil, nil, error.localizedDescription);
            } else {
                NSString *assertionString = [assertionObject base64EncodedStringWithOptions:0];
                completionHandler(assertionString, existingKeyId, nil);
            }
        }];
    } else {
        completionHandler(nil, nil, @"OS unsupported");
    }
}

- (void)getChallengeWithCompletionHandler:(RadarVerificationCompletionHandler)completionHandler {
    NSString *userId = [RadarSettings userId];
    if (!userId) {
        completionHandler(nil, nil, @"Missing userId.");
        return;
    }

    // Check if key exists
    NSString *existingKeyId = [self appAttestKeyId];

    if (existingKeyId) {
        // Key exists, simply get a challenge
        [[RadarAPIClient sharedInstance]
         getAttestChallengeWithUserId:userId
         forAttest:NO
         completionHandler:^(RadarStatus status, NSString *_Nullable challenge) {
            if (status != RadarStatusSuccess) {
                completionHandler(nil, nil, @"Failed to get challenge");
                return;
            }

            // Return the challenge
            completionHandler(challenge, existingKeyId, nil);
        }];
        return;
    }

    // No key exists, get challenge for attest, then perform attestation and return challenge from attest body
    [[RadarAPIClient sharedInstance]
     getAttestChallengeWithUserId:userId
     forAttest:YES
     completionHandler:^(RadarStatus status, NSString *_Nullable challenge) {
        if (status != RadarStatusSuccess) {
            completionHandler(nil, nil, @"Failed to get challenge");
            return;
        }

        if (!challenge) {
            // Rate limited - challenge is null
            completionHandler(nil, nil, nil);
            return;
        }

        // Perform attestation with the challenge
        [self performAttestationWithChallenge:challenge
                            completionHandler:^(RadarStatus status, BOOL result, NSString *_Nullable keyId, NSString *_Nullable message, NSString *_Nullable newChallenge) {
            if (status != RadarStatusSuccess || !result) {
                completionHandler(nil, nil, message ?: @"Attestation failed");
                return;
            }
            
            // Return the challenge from the attest body
            if (!newChallenge) {
                completionHandler(nil, nil, @"No challenge in attest response");
                return;
            }
            
            completionHandler(newChallenge, keyId, nil);
        }];
    }];
}

- (void)performAttestationWithChallenge:(NSString *)challenge completionHandler:(void (^)(RadarStatus status, BOOL result, NSString *_Nullable keyId, NSString *_Nullable message, NSString *_Nullable newChallenge))completionHandler {
    if (!challenge) {
        [RadarUtils runOnMainThread:^{
            if (completionHandler) {
                completionHandler(RadarStatusErrorBadRequest, NO, nil, @"Missing challenge", nil);
            }
        }];
        return;
    }

    [self getAttestationWithChallenge:challenge
            completionHandler:^(NSString *_Nullable attestationString, NSString *_Nullable keyId, NSString *_Nullable attestationError) {
        if (attestationError || !attestationString || !keyId) {
            [RadarUtils runOnMainThread:^{
                if (completionHandler) {
                    completionHandler(RadarStatusErrorServer, NO, nil, attestationError, nil);
                }
            }];
            return;
        }

        NSString *userId = [RadarSettings userId];

        if (!userId) {
            [RadarUtils runOnMainThread:^{
                if (completionHandler) {
                    completionHandler(RadarStatusErrorBadRequest, NO, nil, @"Missing userId.", nil);
                }
            }];
            return;
        }

        [[RadarAPIClient sharedInstance]
         attestWithAttestationString:attestationString
         keyId:keyId
         userId:userId
         completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, BOOL result, NSString *_Nullable keyIdResponse, NSString *_Nullable message, NSString *_Nullable challenge) {
            [RadarUtils runOnMainThread:^{
                if (completionHandler) {
                    completionHandler(status, result, keyIdResponse, message, challenge);
                }
            }];
        }];
    }];
}

// inspired by https://github.com/securing/IOSSecuritySuite
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
- (BOOL)isJailbroken {
    BOOL jailbroken = NO;
    
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // URL scheme check
    NSArray *suspiciousURLSchemes = @[
        @"undecimus://",
        @"sileo://",
        @"zbra://",
        @"filza://"
    ];
    for (NSString *urlScheme in suspiciousURLSchemes) {
        NSURL *url = [NSURL URLWithString:urlScheme];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Jailbreak check failed: URL scheme check"];
            return YES;
        }
    }
    
    // file check
    NSMutableArray *suspiciousFiles = [NSMutableArray arrayWithArray:@[
        @"/var/mobile/Library/Preferences/ABPattern",
        @"/usr/lib/ABDYLD.dylib",
        @"/usr/lib/ABSubLoader.dylib",
        @"/usr/sbin/frida-server",
        @"/etc/apt/sources.list.d/electra.list",
        @"/etc/apt/sources.list.d/sileo.sources",
        @"/.bootstrapped_electra",
        @"/usr/lib/libjailbreak.dylib",
        @"/jb/lzma",
        @"/.cydia_no_stash",
        @"/.installed_unc0ver",
        @"/jb/offsets.plist",
        @"/usr/share/jailbreak/injectme.plist",
        @"/etc/apt/undecimus/undecimus.list",
        @"/var/lib/dpkg/info/mobilesubstrate.md5sums",
        @"/Library/MobileSubstrate/MobileSubstrate.dylib",
        @"/jb/jailbreakd.plist",
        @"/jb/amfid_payload.dylib",
        @"/jb/libjailbreak.dylib",
        @"/usr/libexec/cydia/firmware.sh",
        @"/var/lib/cydia",
        @"/etc/apt",
        @"/private/var/lib/apt",
        @"/private/var/Users/",
        @"/var/log/apt",
        @"/Applications/Cydia.app",
        @"/private/var/stash",
        @"/private/var/lib/apt/",
        @"/private/var/lib/cydia",
        @"/private/var/cache/apt/",
        @"/private/var/log/syslog",
        @"/private/var/tmp/cydia.log",
        @"/Applications/Icy.app",
        @"/Applications/MxTube.app",
        @"/Applications/RockApp.app",
        @"/Applications/blackra1n.app",
        @"/Applications/SBSettings.app",
        @"/Applications/FakeCarrier.app",
        @"/Applications/WinterBoard.app",
        @"/Applications/IntelliScreen.app",
        @"/private/var/mobile/Library/SBSettings/Themes",
        @"/Library/MobileSubstrate/CydiaSubstrate.dylib",
        @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        @"/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
        @"/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
        @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        @"/Applications/Sileo.app",
        @"/var/binpack",
        @"/Library/PreferenceBundles/LibertyPref.bundle",
        @"/Library/PreferenceBundles/ShadowPreferences.bundle",
        @"/Library/PreferenceBundles/ABypassPrefs.bundle",
        @"/Library/PreferenceBundles/FlyJBPrefs.bundle",
        @"/Library/PreferenceBundles/Cephei.bundle",
        @"/Library/PreferenceBundles/SubstitutePrefs.bundle",
        @"/Library/PreferenceBundles/libhbangprefs.bundle",
        @"/usr/lib/libhooker.dylib",
        @"/usr/lib/libsubstitute.dylib",
        @"/usr/lib/substrate",
        @"/usr/lib/TweakInject",
        @"/var/binpack/Applications/loader.app",
        @"/Applications/FlyJB.app",
        @"/Applications/Zebra.app",
        @"/Library/BawAppie/ABypass",
        @"/Library/MobileSubstrate/DynamicLibraries/SSLKillSwitch2.plist",
        @"/Library/MobileSubstrate/DynamicLibraries/PreferenceLoader.plist",
        @"/Library/MobileSubstrate/DynamicLibraries/PreferenceLoader.dylib",
        @"/Library/MobileSubstrate/DynamicLibraries",
        @"/var/mobile/Library/Preferences/me.jjolano.shadow.plist"
    ]];
    if (![RadarUtils isSimulator]) {
        [suspiciousFiles addObjectsFromArray:@[
            @"/bin/bash",
            @"/usr/sbin/sshd",
            @"/usr/libexec/ssh-keysign",
            @"/bin/sh",
            @"/etc/ssh/sshd_config",
            @"/usr/libexec/sftp-server",
            @"/usr/bin/ssh"
        ]];
    }
    for (NSString *file in suspiciousFiles) {
        if ([fileManager fileExistsAtPath:file]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Jailbreak check failed: File check"];
            jailbroken = YES;
        }
        struct stat statStruct;
        if (stat([file UTF8String], &statStruct) == 0) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Jailbreak check failed: File check"];
            jailbroken = YES;
        }
    }
    
    // fork check
    if (![RadarUtils isSimulator]) {
        void *handle = dlopen(NULL, RTLD_LAZY);
        pid_t (*forkFunction)(void) = dlsym(handle, "fork");
        if (forkFunction == NULL) {
            dlclose(handle);
        }
        pid_t forkResult = forkFunction();
        if (forkResult >= 0) {
            if (forkResult > 0) {
                kill(forkResult, SIGTERM);
            }
            dlclose(handle);
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Jailbreak check failed: Fork check"];
            jailbroken = YES;
        }
        dlclose(handle);
    }
    
    // directory check
    NSArray *suspiciousDirs = @[
        @"/",
        @"/root/",
        @"/private/",
        @"/jb/"
    ];
    for (NSString *dir in suspiciousDirs) {
        NSString *path = [dir stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
        [@"RadarSDK" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (!error) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Jailbreak check failed: Directory check"];
            [fileManager removeItemAtPath:path error:nil];
            jailbroken = YES;
        }
    }
    
    // symlink check
    NSArray *suspiciousSymlinks = @[
        @"/var/lib/undecimus/apt",
        @"/Applications",
        @"/Library/Ringtones",
        @"/Library/Wallpaper",
        @"/usr/arm-apple-darwin9",
        @"/usr/include",
        @"/usr/libexec",
        @"/usr/share"
    ];
    for (NSString *symlink in suspiciousSymlinks) {
        NSString *result = [fileManager destinationOfSymbolicLinkAtPath:symlink error:&error];
        if (result != nil && ![result isEqualToString:@""]) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Jailbreak check failed: Symlink check"];
            jailbroken = YES;
        }
    }
    
    // dylib check
    NSArray *suspiciousDylibs = @[
      @"SubstrateLoader.dylib",
      @"SSLKillSwitch2.dylib",
      @"SSLKillSwitch.dylib",
      @"MobileSubstrate.dylib",
      @"TweakInject.dylib",
      @"CydiaSubstrate",
      @"cynject",
      @"CustomWidgetIcons",
      @"PreferenceLoader",
      @"RocketBootstrap",
      @"WeeLoader",
      @"/.file",
      @"libhooker",
      @"SubstrateInserter",
      @"SubstrateBootstrap",
      @"ABypass",
      @"FlyJB",
      @"Substitute",
      @"Cephei",
      @"Electra",
      @"AppSyncUnified-FrontBoard.dylib",
      @"Shadow",
      @"FridaGadget",
      @"frida",
      @"libcycript"
    ];
    NSUInteger imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const char *imageNameCStr = _dyld_get_image_name(i);
        NSString *imageName = [NSString stringWithUTF8String:imageNameCStr];
        for (NSString *dylib in suspiciousDylibs) {
            NSRange range = [imageName rangeOfString:dylib options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Jailbreak check failed: Dylib check"];
                jailbroken = YES;
            }
        }
    }
    
    // class check
    Class shadowRulesetClass = objc_getClass("ShadowRuleset");
    if (shadowRulesetClass != nil) {
        SEL selector = @selector(internalDictionary);
        if (class_getInstanceMethod(shadowRulesetClass, selector) != NULL) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Jailbreak check failed: Class check"];
            jailbroken = YES;
        }
    }
    
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Jailbreak check passed"];
    
    return jailbroken;
}

- (NSString *)getIPs {
    NSMutableArray<NSString *> *ips = [NSMutableArray new];
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                NSString *ip = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                [ips addObject:ip];
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return (ips.count > 0) ? [ips componentsJoinedByString:@","] : @"error";

}

- (NSString *)kDeviceId {
    NSString *key = @"com.radar.kDeviceId";
    NSString *service = @"com.radar";

    @try {
        NSDictionary *query = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: service,
            (__bridge id)kSecAttrAccount: key,
            (__bridge id)kSecReturnData: @YES,
            (__bridge id)kSecAttrSynchronizable: @NO
        };

        CFTypeRef result = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        if (status == errSecSuccess && result) {
            NSData *data = (__bridge_transfer NSData *)result;
            NSString *kDeviceId = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (kDeviceId.length > 0) {
                return kDeviceId;
            }
        } else if (status != errSecItemNotFound) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error reading from keychain | status = %d", (int)status]];
        }

        NSString *kDeviceId = [RadarUtils deviceId];
        if (!kDeviceId || kDeviceId.length == 0) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Error getting deviceId"];
            
            return nil;
        }
        
        NSData *data = [kDeviceId dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *attributes = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: service,
            (__bridge id)kSecAttrAccount: key,
            (__bridge id)kSecValueData: data,
            (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
            (__bridge id)kSecAttrSynchronizable: @NO
        };
        OSStatus addStatus = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
        if (addStatus != errSecSuccess) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error saving to keychain | addStatus = %d", (int)addStatus]];
            
            return nil;
        }

        return kDeviceId;
    } @catch (NSException *exception) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error accessing keychain | exception = %@", exception]];
        
        return nil;
    }
}

- (NSString *)appAttestKeyId {
    NSString *key = @"com.radar.appAttestKeyId";
    NSString *service = @"com.radar";

    @try {
        NSDictionary *query = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: service,
            (__bridge id)kSecAttrAccount: key,
            (__bridge id)kSecReturnData: @YES,
            (__bridge id)kSecAttrSynchronizable: @NO
        };

        CFTypeRef result = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        if (status == errSecSuccess && result) {
            NSData *data = (__bridge_transfer NSData *)result;
            NSString *appAttestKeyId = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (appAttestKeyId.length > 0) {
                return appAttestKeyId;
            }
        } else if (status != errSecItemNotFound) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error reading appAttestKeyId from keychain | status = %d", (int)status]];
        }

        return nil;
    } @catch (NSException *exception) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error accessing keychain for appAttestKeyId | exception = %@", exception]];
        
        return nil;
    }
}

- (BOOL)storeAppAttestKeyId:(NSString *)keyId {
    if (!keyId || keyId.length == 0) {
        return NO;
    }

    NSString *key = @"com.radar.appAttestKeyId";
    NSString *service = @"com.radar";

    @try {
        // First, try to update existing item
        NSDictionary *query = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: service,
            (__bridge id)kSecAttrAccount: key,
        };

        NSData *data = [keyId dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *attributes = @{
            (__bridge id)kSecValueData: data,
            (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
            (__bridge id)kSecAttrSynchronizable: @NO
        };

        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);
        if (status == errSecSuccess) {
            return YES;
        } else if (status == errSecItemNotFound) {
            // Item doesn't exist, create it
            NSMutableDictionary *addAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
            [addAttributes setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
            [addAttributes setObject:service forKey:(__bridge id)kSecAttrService];
            [addAttributes setObject:key forKey:(__bridge id)kSecAttrAccount];

            OSStatus addStatus = SecItemAdd((__bridge CFDictionaryRef)addAttributes, NULL);
            if (addStatus == errSecSuccess) {
                return YES;
            } else {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error saving appAttestKeyId to keychain | addStatus = %d", (int)addStatus]];
                return NO;
            }
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error updating appAttestKeyId in keychain | status = %d", (int)status]];
            return NO;
        }
    } @catch (NSException *exception) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error accessing keychain for appAttestKeyId | exception = %@", exception]];
        return NO;
    }
}

- (BOOL)clearAppAttestKeyId {
    NSString *key = @"com.radar.appAttestKeyId";
    NSString *service = @"com.radar";

    @try {
        NSDictionary *query = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: service,
            (__bridge id)kSecAttrAccount: key,
        };

        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        if (status == errSecSuccess) {
            return YES;
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error clearing appAttestKeyId from keychain | status = %d", (int)status]];
            return NO;
        }
    } @catch (NSException *exception) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Error accessing keychain for appAttestKeyId | exception = %@", exception]];
        return NO;
    }
}

@end
