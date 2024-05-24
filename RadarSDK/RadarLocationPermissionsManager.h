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

@property (nonatomic, strong) RadarLocationPermissionsStatus * _Nonnull status;
@property (nonatomic, strong) CLLocationManager * _Nonnull locationManager;

+ (instancetype _Nonnull )sharedInstance;

- (void)requestForegroundLocationPermissions;

- (void)requestBackgroundLocationPermissions;

- (void)openAppSettings;

- (RadarLocationPermissionsStatus *_Nullable)getLocationPermissionsStatus;

@end
