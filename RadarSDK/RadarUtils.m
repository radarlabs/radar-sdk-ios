//
//  RadarUtils.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <Security/Security.h>
#import <os/log.h>

#import "RadarUtils.h"

@implementation RadarUtilsDeprecated

static NSDateFormatter *_isoDateFormatter;

+ (NSDateFormatter *)isoDateFormatter {
    if (_isoDateFormatter == nil) {
        _isoDateFormatter = [[NSDateFormatter alloc] init];
        _isoDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _isoDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [_isoDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    }

    return _isoDateFormatter;
}

+ (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)deviceOS {
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)country {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

+ (NSNumber *)timeZoneOffset {
    return @((int)[[NSTimeZone localTimeZone] secondsFromGMT]);
}

+ (NSString *)sdkVersion {
    return @"3.45.0"; // SDK VERSION
}

+ (NSString *)deviceId {
    // Caches the device ID for the rest of the session once a lookup succeeds. A nil result
    // (e.g. before first unlock after a reboot) isn't cached, so the next call retries.
    static NSString *deviceId;
    @synchronized(self) {
        if (!deviceId) {
            deviceId = [self fetchDeviceId];
        }
        return deviceId;
    }
}

+ (NSString *)fetchDeviceId {
    NSString *service = @"com.radar";
    NSString *account = @"com.radar.kDeviceId";

    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: service,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecAttrSynchronizable: @NO,
    };

    CFTypeRef dataTypeRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataTypeRef);

    if (status == errSecSuccess) {
        NSData *data = (__bridge_transfer NSData *)dataTypeRef;
        if ([data isKindOfClass:[NSData class]]) {
            NSString *deviceId = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (deviceId.length > 0) {
                return deviceId;
            }
        }
    } else {
        os_log(OS_LOG_DEFAULT, "Error reading from keychain | status = %d", (int)status);
    }

    NSString *deviceId = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    NSData *data = [deviceId dataUsingEncoding:NSUTF8StringEncoding];
    if (!deviceId || !data) {
        os_log(OS_LOG_DEFAULT, "Error getting deviceId");
        return nil;
    }

    NSDictionary *attributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: service,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecValueData: data,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
        (__bridge id)kSecAttrSynchronizable: @NO,
    };
    OSStatus addStatus = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
    if (addStatus == errSecDuplicateItem) {
        CFTypeRef existingDataRef = NULL;
        if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &existingDataRef) == errSecSuccess) {
            NSData *existingData = (__bridge_transfer NSData *)existingDataRef;
            if ([existingData isKindOfClass:[NSData class]]) {
                NSString *storedDeviceId = [[NSString alloc] initWithData:existingData encoding:NSUTF8StringEncoding];
                if (storedDeviceId.length > 0) {
                    return storedDeviceId;
                }
            }
        }
    }
    if (addStatus != errSecSuccess) {
        os_log(OS_LOG_DEFAULT, "Error saving to keychain | addStatus = %d", (int)addStatus);
        return nil;
    }
    return deviceId;
}

+ (NSString *)deviceType {
    return @"iOS";
}

+ (NSString *)deviceMake {
    return @"Apple";
}

+ (RadarConnectionType)networkType {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "google.com");
    
    if(!reachability) {
        return RadarConnectionTypeUnknown;
    }
    
    SCNetworkReachabilityFlags flags;
    
    if(!SCNetworkReachabilityGetFlags(reachability, &flags)) {
        CFRelease(reachability);
        return RadarConnectionTypeUnknown;
    }
    
    CFRelease(reachability);
    
    BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
    BOOL isWWAN = (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0;
    
    if (isReachable) {
        if (isWWAN) {
            CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
            
            NSDictionary *carrierTypes = networkInfo.serviceCurrentRadioAccessTechnology;
            if (carrierTypes && carrierTypes.count > 0) {
                return RadarConnectionTypeCellular;
            } else {
                return RadarConnectionTypeUnknown;
            }
        } else {
            return RadarConnectionTypeWiFi;
        }
    }
    return RadarConnectionTypeUnknown;
}

+ (NSString *)networkTypeString {
    RadarConnectionType type = [self networkType];
    switch(type) {
        case RadarConnectionTypeWiFi:
            return @"wifi";
        case RadarConnectionTypeCellular: {
            CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
            
            if (networkInfo.serviceCurrentRadioAccessTechnology) {
                NSString *radioTech = networkInfo.serviceCurrentRadioAccessTechnology.allValues.firstObject;
                
                if ([radioTech isEqualToString: @"CTRadioAccessTechnologyNR"]) {
                    return @"cellular-5g";
                } else if ([radioTech isEqualToString: @"CTRadioAccessTechnologyLTE"]) {
                    return @"cellular-lte";
                } else if ([radioTech containsString: @"UMTS"] || [radioTech containsString:@"WCDMA"]) {
                    return @"cellular-3g";
                } else if ([radioTech containsString: @"GSM"] || [radioTech containsString:@"EDGE"]) {
                    return @"cellular-2g";
                }
            }
            
            return @"cellular";
        }
        default:
            return @"unknown";
    }
}

+ (NSDictionary *)appInfo {
    NSMutableDictionary *infoDictionary = [[[NSBundle mainBundle] infoDictionary] mutableCopy];
    [infoDictionary addEntriesFromDictionary: [[NSBundle mainBundle] localizedInfoDictionary]];
    
    if (infoDictionary.count) {
        return @{
            @"name": infoDictionary[@"CFBundleDisplayName"] ?: @"",
            @"version": infoDictionary[@"CFBundleShortVersionString"] ?: @"",
            @"build": infoDictionary[@"CFBundleVersion"] ?: @"",
            @"namespace": [[NSBundle mainBundle] bundleIdentifier] ?: @"",
        };
    }
    return @{};
}


+ (BOOL)locationBackgroundMode {
    NSArray *backgroundModes = [NSBundle mainBundle].infoDictionary[@"UIBackgroundModes"];
    return backgroundModes && [backgroundModes containsObject:@"location"];
}

+ (NSString *)locationAuthorization {
    CLAuthorizationStatus authorizationStatus = CLLocationManager.authorizationStatus;
    switch (authorizationStatus) {
    case kCLAuthorizationStatusAuthorizedWhenInUse:
        return @"GRANTED_FOREGROUND";
    case kCLAuthorizationStatusAuthorizedAlways:
        return @"GRANTED_BACKGROUND";
    case kCLAuthorizationStatusDenied:
        return @"DENIED";
    case kCLAuthorizationStatusRestricted:
        return @"DENIED";
    default:
        return @"NOT_DETERMINED";
    }
}

+ (NSString *)locationAccuracyAuthorization {
    static CLLocationManager *locationManager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        locationManager = [CLLocationManager new];
    });
    if (@available(iOS 14.0, *)) {
        CLAccuracyAuthorization accuracyAuthorization = locationManager.accuracyAuthorization;
        switch (accuracyAuthorization) {
        case CLAccuracyAuthorizationReducedAccuracy:
            return @"REDUCED";
        default:
            return @"FULL";
        }
    } else {
        return @"FULL";
    }
}

+ (BOOL)foreground {
    return [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground;
}

+ (NSTimeInterval)backgroundTimeRemaining {
    NSTimeInterval backgroundTimeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
    return (backgroundTimeRemaining == DBL_MAX) ? 180 : backgroundTimeRemaining;
}

+ (CLLocation *)locationForDictionary:(NSDictionary *)dict {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([dict[@"latitude"] doubleValue], [dict[@"longitude"] doubleValue]);
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                         altitude:[dict[@"altitude"] doubleValue]
                                               horizontalAccuracy:[dict[@"horizontalAccuracy"] doubleValue]
                                                 verticalAccuracy:[dict[@"verticalAccuracy"] doubleValue]
                                                        timestamp:dict[@"timestamp"]];
    return location;
}

+ (NSDictionary *)dictionaryForLocation:(CLLocation *)location {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"latitude"] = @(location.coordinate.latitude);
    dict[@"longitude"] = @(location.coordinate.longitude);
    dict[@"horizontalAccuracy"] = @(location.horizontalAccuracy);
    dict[@"verticalAccuracy"] = @(location.verticalAccuracy);
    dict[@"timestamp"] = location.timestamp;
    if (@available(iOS 15.0, *)) {
        CLLocationSourceInformation *sourceInformation = location.sourceInformation;
        if (sourceInformation) {
            if (sourceInformation.isSimulatedBySoftware || sourceInformation.isProducedByAccessory) {
                dict[@"mocked"] = @(YES);
            } else {
                dict[@"mocked"] = @(NO);
            }
        }
    }
    return dict;
}

+ (NSString *)dictionaryToJson:(NSDictionary *)dict {
    if (!dict) {
        return @"{}";
    };

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"bv_jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } 
}

#pragma mark - threading

+ (void)runOnMainThread:(dispatch_block_t)block {
    if (!block) {
        return;
    }

    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
    return;
}

@end
