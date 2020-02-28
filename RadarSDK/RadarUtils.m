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

+ (NSString *)deviceModel
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)deviceOS
{
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)country
{
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

+ (NSNumber *)timeZoneOffset
{
    return @((int)[[NSTimeZone localTimeZone] secondsFromGMT]);
}

+ (NSString *)sdkVersion
{
    return @"3.0.0-beta.3";
}

+ (NSString *)adId
{
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

+ (NSString *)deviceId
{
    NSUUID *idfv = [[UIDevice currentDevice] identifierForVendor];
    if (idfv) {
        return idfv.UUIDString;
    }
    return nil;
}

+ (NSString *)deviceType
{
    return @"iOS";
}

+ (NSString *)deviceMake
{
    return @"Apple";
}

+ (BOOL)locationBackgroundMode
{
    NSArray *backgroundModes = [NSBundle mainBundle].infoDictionary[@"UIBackgroundModes"];
    return backgroundModes && [backgroundModes containsObject:@"location"];
}

+ (BOOL)allowsBackgroundLocationUpdates
{
    return [RadarUtils locationBackgroundMode] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
}

+ (BOOL)foreground
{
    return [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground;
}

+ (NSTimeInterval)backgroundTimeRemaining
{
    NSTimeInterval backgroundTimeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
    return (backgroundTimeRemaining == DBL_MAX) ? 180 : backgroundTimeRemaining;
}

+ (CLLocation *)locationForDictionary:(NSDictionary *)dict
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([dict[@"latitude"] doubleValue], [dict[@"longitude"] doubleValue]);
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                         altitude:[dict[@"altitude"] doubleValue]
                                               horizontalAccuracy:[dict[@"horizontalAccuracy"] doubleValue]
                                                 verticalAccuracy:[dict[@"verticalAccuracy"] doubleValue]
                                                        timestamp:dict[@"timestamp"]];
    return location;
}

+ (NSDictionary *)dictionaryForLocation:(CLLocation *)location
{
    return @{
        @"latitude": @(location.coordinate.latitude),
        @"longitude": @(location.coordinate.longitude),
        @"horizontalAccuracy": @(location.horizontalAccuracy),
        @"verticalAccuracy": @(location.verticalAccuracy),
        @"timestamp": location.timestamp,
    };
}

+ (BOOL)validLocation:(CLLocation *)location
{
    BOOL latitudeValid = location.coordinate.latitude != 0 && location.coordinate.latitude > -90 && location.coordinate.latitude < 90;
    BOOL longitudeValid = location.coordinate.longitude != 0 && location.coordinate.longitude > -180 && location.coordinate.latitude < 180;
    BOOL horizontalAccuracyValid = location.horizontalAccuracy > 0;
    return latitudeValid && longitudeValid && horizontalAccuracyValid;
}

#pragma mark - Airship integration

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma GCC diagnostic ignored "-Wundeclared-selector"

+ (NSString *)uaChannelId
{
    Class UAirshipClass = NSClassFromString(@"UAirship");
    if (UAirshipClass) {
        SEL pushSelector = NSSelectorFromString(@"push");
        if ([UAirshipClass respondsToSelector:pushSelector]) {
            id push = [UAirshipClass performSelector:pushSelector];
            Class UAPushClass = NSClassFromString(@"UAPush");
            if (push && UAPushClass && [push isKindOfClass:UAPushClass]) {
                id channelId = [push valueForKey:@"channelID"];
                if (channelId && [channelId isKindOfClass:[NSString class]]) {
                    return channelId;
                }
            }
        }
    }
    return nil;
}

+ (NSString *)uaNamedUserId
{
    Class UAirshipClass = NSClassFromString(@"UAirship");
    if (UAirshipClass) {
        SEL namedUserSelector = NSSelectorFromString(@"namedUser");
        if ([UAirshipClass respondsToSelector:namedUserSelector]) {
            id namedUser = [UAirshipClass performSelector:namedUserSelector];
            Class UANamedUserClass = NSClassFromString(@"UANamedUser");
            if (namedUser && UANamedUserClass && [namedUser isKindOfClass:UANamedUserClass]) {
                id identifier = [namedUser valueForKey:@"identifier"];
                if (identifier && [identifier isKindOfClass:[NSString class]]) {
                    return identifier;
                }
            }
        }
    }
    return nil;
}

+ (NSString *)uaSessionId
{
    Class UAirshipClass = NSClassFromString(@"UAirship");
    if (UAirshipClass) {
        SEL sharedSelector = NSSelectorFromString(@"shared");
        if ([UAirshipClass respondsToSelector:sharedSelector]) {
            id shared = [UAirshipClass performSelector:sharedSelector];
            if (shared && [shared isKindOfClass:UAirshipClass]) {
                id analytics = [shared valueForKey:@"analytics"];
                Class UAAnalytics = NSClassFromString(@"UAAnalytics");
                if (analytics && [analytics isKindOfClass:UAAnalytics]) {
                    id sessionId = [analytics valueForKey:@"sessionID"];
                    if (sessionId && [sessionId isKindOfClass:[NSString class]]) {
                        return sessionId;
                    }
                }
            }
        }
    }
    return nil;
}

#pragma clang diagnostic pop

@end
