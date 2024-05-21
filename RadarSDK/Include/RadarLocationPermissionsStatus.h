//
//  RadarLocationPermissionsStatus.h
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RadarLocationPermissionState) {
    NoPermissionsGranted,
    ForegroundPermissionsGranted,
    ForegroundPermissionsRejected,
    ForegroundPermissionsPending,
    BackgroundPermissionsGranted,
    BackgroundPermissionsRejected,
    BackgroundPermissionsPending,
    PermissionsRestricted,
    Unknown
};

@interface RadarLocationPermissionsStatus : NSObject

@property (nonatomic, assign) CLAuthorizationStatus locationManagerStatus;
@property (nonatomic, assign) BOOL backgroundPopupAvailable;
@property (nonatomic, assign) BOOL inForegroundPopup;
@property (nonatomic, assign) BOOL userRejectedBackgroundPermissions;
@property (nonatomic, assign) RadarLocationPermissionState locationPermissionState;

- (NSDictionary *_Nonnull)dictionaryValue;

@end
