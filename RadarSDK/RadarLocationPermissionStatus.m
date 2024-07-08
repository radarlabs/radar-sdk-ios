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
                   fullAccuracyAuthorization:(BOOL)fullAccuracyAuthorization
               backgroundRequestAvailable:(BOOL)backgroundRequestAvailable
                      inForegroundRequest:(BOOL)inForegroundRequest
        userDeniedBackgroundAuthorization:(BOOL)userDeniedBackgroundAuthorization {
    self = [super init];
    if (self) {
        _locationManagerStatus = locationManagerStatus;
        _fullAccuracyAuthorization = fullAccuracyAuthorization;
        _backgroundRequestAvailable = backgroundRequestAvailable;
        _inForegroundRequest = inForegroundRequest;
        _userDeniedBackgroundAuthorization = userDeniedBackgroundAuthorization;
        _locationPermissionState = [RadarLocationPermissionStatus locationPermissionStateForLocationManagerStatus:locationManagerStatus 
                                                                                            fullAccuracyAuthorization:fullAccuracyAuthorization
                                                                                        backgroundRequestAvailable:backgroundRequestAvailable
                                                                                               inForegroundRequest:inForegroundRequest
                                                                                 userDeniedBackgroundAuthorization:userDeniedBackgroundAuthorization];
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
        @"fullAccuracyAuthorization": @(self.fullAccuracyAuthorization),
        @"backgroundRequestAvailable": @(self.backgroundRequestAvailable),
        @"inForegroundRequest": @(self.inForegroundRequest),
        @"userDeniedBackgroundAuthorization": @(self.userDeniedBackgroundAuthorization),
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
    BOOL fullAccuracyAuthorization = [dictionary[@"fullAccuracyAuthorization"] boolValue];
    BOOL backgroundRequestAvailable = [dictionary[@"inForegroundRequest"] boolValue];
    BOOL inForegroundRequest = [dictionary[@"inForegroundRequest"] boolValue];
    BOOL userDeniedBackgroundAuthorization = [dictionary[@"userDeniedBackgroundAuthorization"] boolValue];
    return [self initWithStatus:locationManagerStatus
          fullAccuracyAuthorization:fullAccuracyAuthorization
      backgroundRequestAvailable:backgroundRequestAvailable
             inForegroundRequest:inForegroundRequest
userDeniedBackgroundAuthorization:userDeniedBackgroundAuthorization];
}

+ (NSString *)stringForLocationPermissionState:(RadarLocationPermissionState)state {
    switch (state) {
        case NoAuthorization:
            return @"NO_AUTHORIZATION";
        case ForegroundAuthorized:
            return @"FOREGROUND_AUTHORIZED";
        case ForegroundFullAccuracyDenied:
            return @"FOREGROUND_FULL_ACCURACY_DENIED";
        case ForegroundAuthorizationDenied:
            return @"FOREGROUND_AUTHORIOZATION_DENIED";
        case ForegroundAuthorizationRequestInProgress:
            return @"FOREGROUND_AUTHORIZATION_REQUEST_IN_PROGRESS";
        case BackgroundAuthorized:
            return @"BACKGROUND_AUTHORIZED";
        case BackgroundFullAccuracyDenied:
            return @"BACKGROUND_FULL_ACCURACY_DENIED";
        case BackgroundAuthorizationDenied:
            return @"BACKGROUND_AUTHORIZATION_DENIED";
        case BackgroundAuthorizationRequestInProgress:
            return @"BACKGROUND_AUTHORIZATION_REQUEST_IN_PROGRESS";
        case AuthorizationRestricted:
            return @"AUTHORIZATION_RESTRICTED";
        default:
            return @"UNKNOWN";
    }
}

+ (RadarLocationPermissionState)locationPermissionStateForLocationManagerStatus:(CLAuthorizationStatus)locationManagerStatus
                                                          fullAccuracyAuthorization:(BOOL)fullAccuracyAuthorization
                                                      backgroundRequestAvailable:(BOOL)backgroundRequestAvailable
                                                             inForegroundRequest:(BOOL)inForegroundRequest
                                               userDeniedBackgroundAuthorization:(BOOL)userDeniedBackgroundAuthorization {

    if (locationManagerStatus == kCLAuthorizationStatusNotDetermined) {
        return inForegroundRequest ? ForegroundAuthorizationRequestInProgress : NoAuthorization;
    }

    if (locationManagerStatus == kCLAuthorizationStatusDenied) {
        return ForegroundAuthorizationDenied;
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedAlways) {
        if (fullAccuracyAuthorization) {
            return BackgroundAuthorized;
        } else {
            return BackgroundFullAccuracyDenied;
        }
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if (userDeniedBackgroundAuthorization) {
            return BackgroundAuthorizationDenied;
        }
        return backgroundRequestAvailable ? (fullAccuracyAuthorization ? ForegroundAuthorized : ForegroundFullAccuracyDenied) : BackgroundAuthorizationRequestInProgress;
    }

    if (locationManagerStatus == kCLAuthorizationStatusRestricted) {
        return AuthorizationRestricted;
    }
    
    return Unknown;
}

@end
