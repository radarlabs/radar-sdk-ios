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
          foregroundPopupAvailable:(BOOL)foregroundPopupAvailable
          userRejectedBackgroundPermissions:(BOOL)userRejectedBackgroundPermissions {
    self = [super init];
    if (self) {
        _locationManagerStatus = locationManagerStatus;
        _backgroundPopupAvailable = backgroundPopupAvailable;
        _foregroundPopupAvailable = foregroundPopupAvailable;
        _userRejectedBackgroundPermissions = userRejectedBackgroundPermissions;
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
        @"foregroundPopupAvailable": @(self.foregroundPopupAvailable),
        @"userRejectedBackgroundPermissions": @(self.userRejectedBackgroundPermissions)
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
    BOOL foregroundPopupAvailable = [dictionary[@"foregroundPopupAvailable"] boolValue];
    BOOL userRejectedBackgroundPermissions = [dictionary[@"userRejectedBackgroundPermissions"] boolValue];
    return [self initWithStatus:locationManagerStatus backgroundPopupAvailable:backgroundPopupAvailable foregroundPopupAvailable:foregroundPopupAvailable userRejectedBackgroundPermissions:userRejectedBackgroundPermissions];
}

@end
