//
//  RadarPermissionsHelper.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarPermissionsHelper.h"
#import "RadarState.h"

@implementation RadarPermissionsHelper

- (CLAuthorizationStatus)locationAuthorizationStatus {
    // Reads the status locationManager:didChangeAuthorizationStatus: caches, instead of
    // +[CLLocationManager authorizationStatus], a synchronous call into Core Location that can block
    // the main thread. Core Location reports the status when the manager is created on every launch
    // and whenever it changes. Until it has reported one, the cache is not determined, so ask directly.
    CLAuthorizationStatus cachedStatus = RadarState.shared.locationAuthorizationStatus;
    return cachedStatus != kCLAuthorizationStatusNotDetermined ? cachedStatus : [CLLocationManager authorizationStatus];
}

@end
