//
//  RadarPermissionsHelper.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarPermissionsHelper.h"

@implementation RadarPermissionsHelper

- (CLAuthorizationStatus)locationAuthorizationStatus {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    switch (authorizationStatus) {
    case kCLAuthorizationStatusAuthorizedWhenInUse:
        return kCLAuthorizationStatusAuthorizedWhenInUse;
    case kCLAuthorizationStatusAuthorizedAlways:
        return kCLAuthorizationStatusAuthorizedAlways;
    case kCLAuthorizationStatusDenied:
        return kCLAuthorizationStatusDenied;
    case kCLAuthorizationStatusRestricted:
        return kCLAuthorizationStatusRestricted;
    default:
        return kCLAuthorizationStatusNotDetermined;
    }
}

@end
