//
//  RadarLocationPermissionsManager.h
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "RadarLocationPermissionsStatus.h"

@interface RadarLocationPermissionsManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) RadarLocationPermissionsStatus *status;
@property (nonatomic, strong) CLLocationManager *locationManager;

+ (instancetype)sharedInstance;

- (void)requestLocationPermissions:(BOOL)requestBackgroundPermissions;

- (RadarLocationPermissionsStatus *)getLocationPermissionsStatus;

@end
