//
//  RadarLocationPremissionsStatus.m
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarLocationPermissionsStatus.h"
#import "RadarLocationPermissionsStatus+Internal.h"

@implementation RadarLocationPermissionsStatus

+ (void)store:(RadarLocationPermissionsStatus *)status {
    NSDictionary *dict = [status dictionaryValue];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"radarLocationPermissionsStatus"];
}

+ (RadarLocationPermissionsStatus *)retrieve {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:@"radarLocationPermissionsStatus"];
    if (dict) {
        return [[RadarLocationPermissionsStatus alloc] initWithDictionary:dict];
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
        _locationPermissionState = [RadarLocationPermissionsStatus locationPermissionStateForLocationManagerStatus:locationManagerStatus backgroundPopupAvailable:backgroundPopupAvailable inForegroundPopup:inForegroundPopup userRejectedBackgroundPermissions:userRejectedBackgroundPermissions];
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
        @"locationPermissionState": [RadarLocationPermissionsStatus stringForLocationPermissionState:self.locationPermissionState]
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
    return [self initWithStatus:locationManagerStatus backgroundPopupAvailable:backgroundPopupAvailable inForegroundPopup:inForegroundPopup userRejectedBackgroundPermissions:userRejectedBackgroundPermissions];
}

+ (NSString *)stringForLocationPermissionState:(RadarLocationPermissionState)state {
    switch (state) {
        case NoPermissionsGranted:
            return @"NoPermissionsGranted";
        case ForegroundPermissionsGranted:
            return @"ForegroundPermissionsGranted";
        case ForegroundPermissionsRejected:
            return @"ForegroundPermissionsRejected";
        case ForegroundPermissionsPending:
            return @"ForegroundPermissionsPending";
        case BackgroundPermissionsGranted:
            return @"BackgroundPermissionsGranted";
        case BackgroundPermissionsRejected:
            return @"BackgroundPermissionsRejected";
        case BackgroundPermissionsPending:
            return @"BackgroundPermissionsPending";
        case PermissionsRestricted:
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
        // this is wrong, we might alo get here is we got allow once and it was then revoked
        // we shoould use the dangling flag to set the in foreground prompt too. change it to in foreground popup as
        // the availibility can change. Note if we granted once we can get prompt again.
        return inForegroundPopup ? ForegroundPermissionsPending : NoPermissionsGranted;
    }

    if (locationManagerStatus == kCLAuthorizationStatusDenied) {
        return ForegroundPermissionsRejected;
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedAlways) {
        return BackgroundPermissionsGranted;
    }

    if (locationManagerStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if (userRejectedBackgroundPermissions) {
            return BackgroundPermissionsRejected;
        }
        return backgroundPopupAvailable ? ForegroundPermissionsGranted : BackgroundPermissionsPending;
    }

    if (locationManagerStatus == kCLAuthorizationStatusRestricted) {
        return PermissionsRestricted;
    }
    
    return Unknown;
}

@end
