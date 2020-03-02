//
//  RadarPermissionsHelper.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarPermissionsHelper.h"

@implementation RadarPermissionsHelper

- (CLAuthorizationStatus)locationAuthorizationStatus {
    return [CLLocationManager authorizationStatus];
}

@end
