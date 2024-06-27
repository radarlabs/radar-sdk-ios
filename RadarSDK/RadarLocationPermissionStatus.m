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
                   accuracyAuthorization:(BOOL)accuracyAuthorization
               backgroundPromptAvailable:(BOOL)backgroundPromptAvailable
                      inForegroundPrompt:(BOOL)inForegroundPrompt
        userRejectedBackgroundPermission:(BOOL)userRejectedBackgroundPermission {
    self = [super init];
    if (self) {
        _locationManagerStatus = locationManagerStatus;
        _accuracyAuthorization = accuracyAuthorization;
        _backgroundPromptAvailable = backgroundPromptAvailable;
        _inForegroundPrompt = inForegroundPrompt;
        _userRejectedBackgroundPermission = userRejectedBackgroundPermission;
        _locationPermissionState = [RadarLocationPermissionStatus locationPermissionStateForLocationManagerStatus:locationManagerStatus 
                                                                                            accuracyAuthorization:accuracyAuthorization
                                                                                        backgroundPromptAvailable:backgroundPromptAvailable
                                                                                               inForegroundPrompt:inForegroundPrompt
                                                                                 userRejectedBackgroundPermission:userRejectedBackgroundPermission];
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
        @"accuracyAuthorization": @(self.accuracyAuthorization),
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
    BOOL accuracyAuthorization = [dictionary[@"accuracyAuthorization"] boolValue];
    BOOL backgroundPromptAvailable = [dictionary[@"backgroundPromptAvailable"] boolValue];
    BOOL inForegroundPrompt = [dictionary[@"inForegroundPrompt"] boolValue];
    BOOL userRejectedBackgroundPermission = [dictionary[@"userRejectedBackgroundPermission"] boolValue];
    return [self initWithStatus:locationManagerStatus
          accuracyAuthorization:accuracyAuthorization
      backgroundPromptAvailable:backgroundPromptAvailable
             inForegroundPrompt:inForegroundPrompt
userRejectedBackgroundPermission:userRejectedBackgroundPermission];
}

+ (NSString *)stringForLocationPermissionState:(RadarLocationPermissionState)state {
    switch (state) {
        case NoPermissionGranted:
            return @"NO_PERMISSION_GRANTED";
        case ForegroundPermissionGranted:
            return @"FOREGROUND_PERMISSION_GRANTED";
        case ApproximateForegroundPermissionGranted:
            return @"APPROXIMATE_FOREGROUND_PERMISSION_GRANTED";
        case ForegroundPermissionRejected:
            return @"FOREGROUND_PERMISSION_REJECTED";
        case ForegroundPermissionPending:
            return @"FOREGROUND_PERMISSION_PENDING";
        case BackgroundPermissionGranted:
            return @"BACKGROUND_PERMISSION_GRANTED";
        case ApproximateBackgroundPermissionGranted:
            return @"APPROXIMATE_BACKGROUND_PERMISSION_GRANTED";
        case BackgroundPermissionRejected:
            return @"BACKGROUND_PERMISSION_REJECTED";
        case BackgroundPermissionPending:
            return @"BACKGROUND_PERMISSION_PENDING";
        case PermissionRestricted:
            return @"PERMISSION_RESTRICTED";
        default:
            return @"UNKNOWN";
    }
}

+ (RadarLocationPermissionState)locationPermissionStateForLocationManagerStatus:(CLAuthorizationStatus)locationManagerStatus
                                                          accuracyAuthorization:(BOOL)accuracyAuthorization
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
        if (accuracyAuthorization) {
            return BackgroundPermissionGranted;
        } else {
            return ApproximateBackgroundPermissionGranted;
        }
        
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if (userRejectedBackgroundPermission) {
            return BackgroundPermissionRejected;
        }
        return backgroundPromptAvailable ? (accuracyAuthorization ? ForegroundPermissionGranted : ApproximateForegroundPermissionGranted) : BackgroundPermissionPending;
    }

    if (locationManagerStatus == kCLAuthorizationStatusRestricted) {
        return PermissionRestricted;
    }
    
    return Unknown;
}

@end
