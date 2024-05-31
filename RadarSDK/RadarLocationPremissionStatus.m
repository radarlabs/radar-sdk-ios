//
//  RadarLocationPremissionsStatus.m
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
                backgroundPopupAvailable:(BOOL)backgroundPopupAvailable
                       inForegroundPopup:(BOOL)inForegroundPopup
       userRejectedBackgroundPermissions:(BOOL)userRejectedBackgroundPermissions {
    self = [super init];
    if (self) {
        _locationManagerStatus = locationManagerStatus;
        _backgroundPopupAvailable = backgroundPopupAvailable;
        _inForegroundPopup = inForegroundPopup;
        _userRejectedBackgroundPermissions = userRejectedBackgroundPermissions;
        _locationPermissionState = [RadarLocationPermissionStatus locationPermissionStateForLocationManagerStatus:locationManagerStatus backgroundPopupAvailable:backgroundPopupAvailable inForegroundPopup:inForegroundPopup userRejectedBackgroundPermissions:userRejectedBackgroundPermissions];
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
        @"backgroundPopupAvailable": @(self.backgroundPopupAvailable),
        @"inForegroundPopup": @(self.inForegroundPopup),
        @"userRejectedBackgroundPermissions": @(self.userRejectedBackgroundPermissions),
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
    BOOL backgroundPopupAvailable = [dictionary[@"backgroundPopupAvailable"] boolValue];
    BOOL inForegroundPopup = [dictionary[@"inForegroundPopup"] boolValue];
    BOOL userRejectedBackgroundPermissions = [dictionary[@"userRejectedBackgroundPermissions"] boolValue];
    return [self initWithStatus:locationManagerStatus 
       backgroundPopupAvailable:backgroundPopupAvailable 
              inForegroundPopup:inForegroundPopup 
userRejectedBackgroundPermissions:userRejectedBackgroundPermissions];
}

+ (NSString *)stringForLocationPermissionState:(RadarLocationPermissionState)state {
    switch (state) {
        case NoPermissionGranted:
            return @"NoPermissionsGranted";
        case ForegroundPermissionGranted:
            return @"ForegroundPermissionsGranted";
        case ForegroundPermissionRejected:
            return @"ForegroundPermissionsRejected";
        case ForegroundPermissionPending:
            return @"ForegroundPermissionsPending";
        case BackgroundPermissionGranted:
            return @"BackgroundPermissionsGranted";
        case BackgroundPermissionRejected:
            return @"BackgroundPermissionsRejected";
        case BackgroundPermissionPending:
            return @"BackgroundPermissionsPending";
        case PermissionRestricted:
            return @"PermissionsRestricted";
        default:
            return @"Unknown";
    }
}

+ (RadarLocationPermissionState)locationPermissionStateForLocationManagerStatus:(CLAuthorizationStatus)locationManagerStatus
                                                       backgroundPopupAvailable:(BOOL)backgroundPopupAvailable
                                                              inForegroundPopup:(BOOL)inForegroundPopup
                                              userRejectedBackgroundPermissions:(BOOL)userRejectedBackgroundPermissions {

    if (locationManagerStatus == kCLAuthorizationStatusNotDetermined) {
        return inForegroundPopup ? ForegroundPermissionPending : NoPermissionGranted;
    }

    if (locationManagerStatus == kCLAuthorizationStatusDenied) {
        return ForegroundPermissionRejected;
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedAlways) {
        return BackgroundPermissionGranted;
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if (userRejectedBackgroundPermissions) {
            return BackgroundPermissionRejected;
        }
        return backgroundPopupAvailable ? ForegroundPermissionGranted : BackgroundPermissionPending;
    }

    if (locationManagerStatus == kCLAuthorizationStatusRestricted) {
        return PermissionRestricted;
    }
    
    return Unknown;
}

@end