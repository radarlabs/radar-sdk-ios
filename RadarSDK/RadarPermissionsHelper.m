//
//  RadarPermissionsHelper.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarPermissionsHelper.h"

@implementation RadarPermissionsHelper {
    CBCentralManager *_cbManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _cbManager = [[CBCentralManager alloc] init];
    }
    return self;
}

- (CBManagerState)cbState {
    return _cbManager.state;
}

- (CLAuthorizationStatus)locationAuthorizationStatus {
    return [CLLocationManager authorizationStatus];
}

- (BOOL)isBeaconMonitoringAvailable {
    return [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]];
}

@end
