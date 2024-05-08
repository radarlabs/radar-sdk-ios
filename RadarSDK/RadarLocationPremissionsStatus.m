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

- (instancetype _Nullable)initWithStatus:(CLAuthorizationStatus)locationManagerStatus
          requestedBackgroundPermissions:(BOOL)requestedBackgroundPermissions
          requestedForegroundPermissions:(BOOL)requestedForegroundPermissions {
    self = [super init];
    if (self) {
        _locationManagerStatus = locationManagerStatus;
        _requestedBackgroundPermissions = requestedBackgroundPermissions;
        _requestedForegroundPermissions = requestedForegroundPermissions;
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
        @"requestedForegroundPermissions": @(self.requestedForegroundPermissions)
    };
}

@end
