//
//  RadarBeaconScanner.h
//  Library
//
//  Created by Ping Xia on 4/29/20.
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarBeacon.h"
#import "RadarBeaconScanRequest.h"
#import "RadarPermissionsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RadarBeaconScannerDelegate

- (void)didFinishMonitoring:(RadarBeaconScanRequest *)request status:(RadarStatus)status nearbyBeacons:(NSArray<RadarBeacon *> *_Nullable)nearbyBeacons;

- (void)didFailStartMonitoring;

@end

@interface RadarBeaconScanner : NSObject

- (instancetype)initWithDelegate:(__weak id<RadarBeaconScannerDelegate>)delegate
                 locationManager:(CLLocationManager *)locationManager
               permissionsHelper:(RadarPermissionsHelper *)permissionsHelper;

- (void)startMonitoringWithRequest:(RadarBeaconScanRequest *)request;

- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
