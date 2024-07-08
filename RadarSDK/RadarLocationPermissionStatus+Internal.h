//
//  RadarLocationPermissionStatus.h
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarLocationPermissionStatus.h"
#import <Foundation/Foundation.h>

@interface RadarLocationPermissionStatus()

+ (void) radarLocationPermissionStatus:(RadarLocationPermissionStatus *_Nonnull)status;

+ (RadarLocationPermissionStatus *_Nullable) getRadarLocationPermissionStatus;

- (instancetype _Nullable)initWithStatus:(CLAuthorizationStatus)locationManagerStatus
                   accuracyAuthorization:(BOOL)accuracyAuthorization
               backgroundRequestAvailable:(BOOL)backgroundPromptAvailable
                      inForegroundRequest:(BOOL)inForegroundPrompt
        userDeniedBackgroundAuthorization:(BOOL)userRejectedBackgroundPermission;

@end
