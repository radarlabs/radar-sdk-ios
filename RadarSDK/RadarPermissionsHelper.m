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

- (CLAuthorizationStatus)locationAuthorizationStatus {
    return [CLLocationManager authorizationStatus];
}

- (CBManagerState)bluetoothState {
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        return CBManagerStateUnsupported;
    }
    return _cbManager.state;
}

@end
