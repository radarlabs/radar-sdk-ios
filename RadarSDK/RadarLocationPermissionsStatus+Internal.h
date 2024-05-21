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

+ (void) store:(RadarLocationPermissionsStatus *_Nonnull)status;

+ (RadarLocationPermissionsStatus *_Nullable) retrieve;

- (instancetype _Nullable)initWithStatus:(CLAuthorizationStatus)locationManagerStatus
                backgroundPopupAvailable:(BOOL)backgroundPopupAvailable
                       inForegroundPopup:(BOOL)inForegroundPopup
       userRejectedBackgroundPermissions:(BOOL)userRejectedBackgroundPermissions;

@end
