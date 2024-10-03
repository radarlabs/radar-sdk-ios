//
//  RadarLocationPermissionManager.h
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "RadarLocationPermissionStatus.h"
#import "RadarLocationPermissionProtocol.h"

@interface RadarLocationPermissionManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) RadarLocationPermissionStatus * _Nullable status;
@property (nonatomic, strong) CLLocationManager * _Nonnull locationManager;
@property (nullable, strong, nonatomic) id radarSDKLocationPermission;

+ (instancetype _Nonnull )sharedInstance;

- (void)requestForegroundLocationPermission;

- (void)requestBackgroundLocationPermission;

- (void)openAppSettings;

- (RadarLocationPermissionStatus *_Nullable)getLocationPermissionStatus;

@end
