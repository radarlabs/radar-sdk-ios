//
//  RadarLocationPermissionsStatus.h
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarLocationPermissionsStatus.h"
#import <Foundation/Foundation.h>

@interface RadarLocationPermissionsStatus()

- (instancetype _Nullable)initWithStatus:(CLAuthorizationStatus)locationManagerStatus
          requestedBackgroundPermissions:(BOOL)requestedBackgroundPermissions
          requestedForegroundPermissions:(BOOL)requestedForegroundPermissions;

@end
