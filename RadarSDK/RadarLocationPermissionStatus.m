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
               precisePermission:(BOOL)precisePermission
              backgroundRequestAvailable:(BOOL)backgroundRequestAvailable
                     inForegroundRequest:(BOOL)inForegroundRequest
       userDeniedBackgroundPermission:(BOOL)userDeniedBackgroundPermission {
    self = [super init];
    if (self) {
        _locationManagerStatus = locationManagerStatus;
        _precisePermission = precisePermission;
        _backgroundRequestAvailable = backgroundRequestAvailable;
        _inForegroundRequest = inForegroundRequest;
        _userDeniedBackgroundPermission = userDeniedBackgroundPermission;
        _locationPermissionState = [RadarLocationPermissionStatus locationPermissionStateForLocationManagerStatus:locationManagerStatus
                                                                                                precisePermission:precisePermission
                                                                                       backgroundRequestAvailable:backgroundRequestAvailable
                                                                                              inForegroundRequest:inForegroundRequest
                                                                                   userDeniedBackgroundPermission:userDeniedBackgroundPermission];
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
        @"precisePermission": @(self.precisePermission),
        @"backgroundRequestAvailable": @(self.backgroundRequestAvailable),
        @"inForegroundRequest": @(self.inForegroundRequest),
        @"userDeniedBackgroundPermission": @(self.userDeniedBackgroundPermission),
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
    BOOL fullAccuracyPermission = [dictionary[@"fullAccuracyPermission"] boolValue];
    BOOL backgroundRequestAvailable = [dictionary[@"backgroundRequestAvailable"] boolValue];
    BOOL inForegroundRequest = [dictionary[@"inForegroundRequest"] boolValue];
    BOOL userDeniedBackgroundPermission = [dictionary[@"userDeniedBackgroundPermission"] boolValue];
    return [self initWithStatus:locationManagerStatus
      precisePermission:userDeniedBackgroundPermission
     backgroundRequestAvailable:backgroundRequestAvailable
            inForegroundRequest:inForegroundRequest
userDeniedBackgroundPermission:userDeniedBackgroundPermission];
}

+ (NSString *)stringForLocationPermissionState:(RadarLocationPermissionState)state {
    switch (state) {
        case NoPermission:
            return @"NO_PERMISSION";
        case ForegroundPermissionGranted:
            return @"FOREGROUND_PERMISSION_GRANTED"; 
        case ForegroundCoarsePermissionGranted:
            return @"FOREGROUND_COARSE_PERMISSION_GRANTED";
        case ForegroundPermissionDenied:
            return @"FOREGROUND_PERMISSION_DENIED"; 
        case ForegroundPermissionRequestInProgress:
            return @"FOREGROUND_PERMISSION_REQUEST_IN_PROGRESS";
        case BackgroundPermissionGranted:
            return @"BACKGROUND_PERMISSION_GRANTED";
        case BackgroundCoarsePermissionGranted:
            return @"BACKGROUND_COARSE_PERMISSION_GRANTED";
        case BackgroundPermissionDenied:
            return @"BACKGROUND_PERMISSION_DENIED";
        case BackgroundPermissionRequestInProgress:
            return @"BACKGROUND_PERMISSION_REQUEST_IN_PROGRESS";
        case PermissionRestricted:
            return @"PERMISSION_RESTRICTED";
        default:
            return @"UNKNOWN";
    }
}

+ (RadarLocationPermissionState)locationPermissionStateForLocationManagerStatus:(CLAuthorizationStatus)locationManagerStatus
                                                              precisePermission:(BOOL)precisePermission
                                                     backgroundRequestAvailable:(BOOL)backgroundRequestAvailable
                                                            inForegroundRequest:(BOOL)inForegroundRequest
                                                 userDeniedBackgroundPermission:(BOOL)userDeniedBackgroundPermission {

    if (locationManagerStatus == kCLAuthorizationStatusNotDetermined) {
        return inForegroundRequest ? ForegroundPermissionRequestInProgress : NoPermission;
    }

    if (locationManagerStatus == kCLAuthorizationStatusDenied) {
        return ForegroundPermissionDenied;
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedAlways) {
        if (precisePermission) {
            return BackgroundPermissionGranted;
        } else {
            return BackgroundCoarsePermissionGranted;
        }
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if (userDeniedBackgroundPermission) {
            return BackgroundPermissionDenied;
        }
        return backgroundRequestAvailable ? (precisePermission ? ForegroundPermissionGranted : ForegroundCoarsePermissionGranted) : BackgroundPermissionRequestInProgress;
    }

    if (locationManagerStatus == kCLAuthorizationStatusRestricted) {
        return PermissionRestricted;
    }
    
    return Unknown;
}

@end
