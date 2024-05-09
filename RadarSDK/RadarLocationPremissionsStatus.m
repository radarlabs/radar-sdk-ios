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
          requestedBackgroundPermissions:(BOOL)requestedBackgroundPermissions
          requestedForegroundPermissions:(BOOL)requestedForegroundPermissions
          userRejectedBackgroundPermissions:(BOOL)userRejectedBackgroundPermissions {
    self = [super init];
    if (self) {
        _locationManagerStatus = locationManagerStatus;
        _requestedBackgroundPermissions = requestedBackgroundPermissions;
        _requestedForegroundPermissions = requestedForegroundPermissions;
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
        @"requestedBackgroundPermissions": @(self.requestedBackgroundPermissions),
        @"requestedForegroundPermissions": @(self.requestedForegroundPermissions),
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
    BOOL requestedBackgroundPermissions = [dictionary[@"requestedBackgroundPermissions"] boolValue];
    BOOL requestedForegroundPermissions = [dictionary[@"requestedForegroundPermissions"] boolValue];
    BOOL userRejectedBackgroundPermissions = [dictionary[@"userRejectedBackgroundPermissions"] boolValue];
    return [self initWithStatus:locationManagerStatus requestedBackgroundPermissions:requestedBackgroundPermissions requestedForegroundPermissions:requestedForegroundPermissions userRejectedBackgroundPermissions:userRejectedBackgroundPermissions];
}

@end
