//
//  RadarUtils.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

#import "RadarUtils.h"

@implementation RadarUtils

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
    return @"3.5.12";
}

+ (NSString *)adId {
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        id manager = [ASIdentifierManagerClass valueForKey:@"sharedManager"];
        if ([[manager valueForKey:@"advertisingTrackingEnabled"] isEqual:@1]) {
            return [[manager valueForKey:@"advertisingIdentifier"] UUIDString];
        } else {
            return @"OptedOut";
        }
    }
    return nil;
}

+ (NSString *)deviceId {
    NSUUID *idfv = [[UIDevice currentDevice] identifierForVendor];
    if (idfv) {
        return idfv.UUIDString;
    }
    return nil;
}

+ (NSString *)deviceType {
    return @"iOS";
}

+ (NSString *)deviceMake {
    return @"Apple";
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
    CLLocationManager *locationManager = [CLLocationManager new];
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
            if (sourceInformation.isSimulatedBySoftware) {
                dict[@"mocked"] = @(YES);
            } else {
                dict[@"mocked"] = @(NO);
            }
        }
    }
    return dict;
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
