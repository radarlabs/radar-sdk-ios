//
//  RadarLocationPermissionsStatus.m
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarLocationPermissionStatus.h"
#import "RadarLocationPermissionStatus+Internal.h"

@implementation RadarLocationPermissionStatus

+ (void)radarLocationPermissionStatus:(RadarLocationPermissionStatus *)status {
    NSDictionary *dict = [status dictionaryValue];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"radarLocationPermissionStatus"];
}

+ (RadarLocationPermissionStatus *)getRadarLocationPermissionStatus {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:@"radarLocationPermissionStatus"];
    if (dict) {
        return [[RadarLocationPermissionStatus alloc] initWithDictionary:dict];
    }
    return nil;
}

- (instancetype _Nullable)initWithStatus:(CLAuthorizationStatus)locationManagerStatus
                backgroundPromptAvailable:(BOOL)backgroundPromptAvailable
                       inForegroundPrompt:(BOOL)inForegroundPrompt
       userRejectedBackgroundPermission:(BOOL)userRejectedBackgroundPermission {
    self = [super init];
    if (self) {
        _locationManagerStatus = locationManagerStatus;
        _backgroundPromptAvailable = backgroundPromptAvailable;
        _inForegroundPrompt = inForegroundPrompt;
        _userRejectedBackgroundPermission = userRejectedBackgroundPermission;
        _locationPermissionState = [RadarLocationPermissionStatus locationPermissionStateForLocationManagerStatus:locationManagerStatus backgroundPromptAvailable:backgroundPromptAvailable inForegroundPrompt:inForegroundPrompt userRejectedBackgroundPermission:userRejectedBackgroundPermission];
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSString *statusString;
    
    switch (self.locationManagerStatus) {
        case kCLAuthorizationStatusNotDetermined:
            statusString = @"NotDetermined";
            break;
        case kCLAuthorizationStatusRestricted:
            statusString = @"Restricted";
            break;
        case kCLAuthorizationStatusDenied:
            statusString = @"Denied";
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            statusString = @"AuthorizedAlways";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            statusString = @"AuthorizedWhenInUse";
            break;
        default:
            statusString = @"Unknown";
    }
    return @{
        @"locationManagerStatus": statusString,
        @"backgroundPromptAvailable": @(self.backgroundPromptAvailable),
        @"inForegroundPrompt": @(self.inForegroundPrompt),
        @"userRejectedBackgroundPermission": @(self.userRejectedBackgroundPermission),
        @"locationPermissionState": [RadarLocationPermissionStatus stringForLocationPermissionState:self.locationPermissionState]
    };
}

- (instancetype _Nullable)initWithDictionary:(NSDictionary *)dictionary {
    NSString *statusString = dictionary[@"locationManagerStatus"];
    CLAuthorizationStatus locationManagerStatus;
    if ([statusString isEqualToString:@"NotDetermined"]) {
        locationManagerStatus = kCLAuthorizationStatusNotDetermined;
    } else if ([statusString isEqualToString:@"Restricted"]) {
        locationManagerStatus = kCLAuthorizationStatusRestricted;
    } else if ([statusString isEqualToString:@"Denied"]) {
        locationManagerStatus = kCLAuthorizationStatusDenied;
    } else if ([statusString isEqualToString:@"AuthorizedAlways"]) {
        locationManagerStatus = kCLAuthorizationStatusAuthorizedAlways;
    } else if ([statusString isEqualToString:@"AuthorizedWhenInUse"]) {
        locationManagerStatus = kCLAuthorizationStatusAuthorizedWhenInUse;
    } else {
        locationManagerStatus = kCLAuthorizationStatusNotDetermined;
    }
    BOOL backgroundPromptAvailable = [dictionary[@"backgroundPromptAvailable"] boolValue];
    BOOL inForegroundPrompt = [dictionary[@"inForegroundPrompt"] boolValue];
    BOOL userRejectedBackgroundPermission = [dictionary[@"userRejectedBackgroundPermission"] boolValue];
    return [self initWithStatus:locationManagerStatus 
       backgroundPromptAvailable:backgroundPromptAvailable 
              inForegroundPrompt:inForegroundPrompt
userRejectedBackgroundPermission:userRejectedBackgroundPermission];
}

+ (NSString *)stringForLocationPermissionState:(RadarLocationPermissionState)state {
    switch (state) {
        case NoPermissionGranted:
            return @"NoPermissionGranted";
        case ForegroundPermissionGranted:
            return @"ForegroundPermissionGranted";
        case ForegroundPermissionRejected:
            return @"ForegroundPermissionRejected";
        case ForegroundPermissionPending:
            return @"ForegroundPermissionPending";
        case BackgroundPermissionGranted:
            return @"BackgroundPermissionGranted";
        case BackgroundPermissionRejected:
            return @"BackgroundPermissionRejected";
        case BackgroundPermissionPending:
            return @"BackgroundPermissionPending";
        case PermissionRestricted:
            return @"PermissionRestricted";
        default:
            return @"Unknown";
    }
}

+ (RadarLocationPermissionState)locationPermissionStateForLocationManagerStatus:(CLAuthorizationStatus)locationManagerStatus
                                                       backgroundPromptAvailable:(BOOL)backgroundPromptAvailable
                                                              inForegroundPrompt:(BOOL)inForegroundPrompt
                                              userRejectedBackgroundPermission:(BOOL)userRejectedBackgroundPermission {

    if (locationManagerStatus == kCLAuthorizationStatusNotDetermined) {
        return inForegroundPrompt ? ForegroundPermissionPending : NoPermissionGranted;
    }

    if (locationManagerStatus == kCLAuthorizationStatusDenied) {
        return ForegroundPermissionRejected;
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedAlways) {
        return BackgroundPermissionGranted;
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if (userRejectedBackgroundPermission) {
            return BackgroundPermissionRejected;
        }
        return backgroundPromptAvailable ? ForegroundPermissionGranted : BackgroundPermissionPending;
    }

    if (locationManagerStatus == kCLAuthorizationStatusRestricted) {
        return PermissionRestricted;
    }
    
    return Unknown;
}

@end
