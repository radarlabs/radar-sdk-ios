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
#import <objc/runtime.h>
@import Network;

#import "RadarVerificationManager.h"

#import "Radar+Internal.h"
#import "RadarAPIClient.h"
#import "RadarBeaconManager.h"
#import "RadarLocationManager.h"
#import "RadarLogger.h"
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

@property (assign, nonatomic) BOOL started;
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
    [self trackVerifiedWithBeacons:NO completionHandler:completionHandler];
}

- (void)trackVerifiedWithBeacons:(BOOL)beacons completionHandler:(RadarTrackVerifiedCompletionHandler)completionHandler {
    BOOL lastTokenBeacons = beacons;
    
    [[RadarAPIClient sharedInstance]
     getConfigForUsage:@"verify"
     verified:YES
     completionHandler:^(RadarStatus status, RadarConfig *_Nullable config) {
        if (status != RadarStatusSuccess || !config) {
            if (completionHandler) {
                [RadarUtils runOnMainThread:^{
                    completionHandler(status, nil);
                }];
            }
            return;
        }
        
        [[RadarLocationManager sharedInstance]
         getLocationWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium
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
                     encrypted:NO
                     expectedCountryCode:self.expectedCountryCode
                     expectedStateCode:self.expectedStateCode
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
    
    [self callTrackVerified];
}

- (void)callTrackVerified {
    if (!self.started) {
        return;
    }
    
    [self trackVerifiedWithBeacons:self.startedBeacons completionHandler:^(RadarStatus status, RadarVerifiedLocationToken *_Nullable token) {
        NSTimeInterval expiresIn = 0;
        NSTimeInterval minInterval = self.startedInterval;
        
        if (token) {
            expiresIn = token.expiresIn;
            
            // if expiresIn is shorter than interval, override interval
            // re-request early to maximize the likelihood that a cached token is available
            minInterval = MIN(expiresIn - 10, self.startedInterval);
        }
        
        // min interval is 10 seconds
        if (minInterval < 10) {
            minInterval = 10;
        }
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(intervalFired) object:nil];
        
        if (!self.started) {
            return;
        }
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Requesting token again in %f seconds | minInterval = %f; expiresIn = %f; startedInterval = %f", minInterval, minInterval, expiresIn, self.startedInterval]];
        
        [self performSelector:@selector(intervalFired) withObject:nil afterDelay:minInterval];
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
                [self callTrackVerified];
            }
        });
        nw_path_monitor_start(_monitor);
    }
    
    [self callTrackVerified];
}

- (void)stopTrackingVerified {
    self.started = NO;

    if (_monitor) {
        nw_path_monitor_cancel(_monitor);
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(intervalFired) object:nil];
}

- (void)getVerifiedLocationTokenWithCompletionHandler:(RadarTrackVerifiedCompletionHandler)completionHandler {
    NSTimeInterval lastTokenElapsed = [NSProcessInfo processInfo].systemUptime - self.lastTokenSystemUptime;
    
    if (self.lastToken) {
        if (lastTokenElapsed < self.lastToken.expiresIn && self.lastToken.passed) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Last token valid | lastToken.expiresIn = %f; lastTokenElapsed = %f; lastToken.passed = %d", self.lastToken.expiresIn, lastTokenElapsed, self.lastToken.passed]];
            
            [Radar flushLogs];
            
            return completionHandler(RadarStatusSuccess, self.lastToken);
        }
        
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Last token invalid | lastToken.expiresIn = %f; lastTokenElapsed = %f; lastToken.passed = %d", self.lastToken.expiresIn, lastTokenElapsed, self.lastToken.passed]];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"No last token"];
    }
    
    [self trackVerifiedWithBeacons:self.lastTokenBeacons completionHandler:completionHandler];
}

- (void)setExpectedJurisdictionWithCountryCode:(NSString *)countryCode stateCode:(NSString *)stateCode {
    self.expectedCountryCode = countryCode;
    self.expectedStateCode = stateCode;
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

@end
