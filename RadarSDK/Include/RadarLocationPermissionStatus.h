//
//  RadarLocationPermissionStatus.h
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

/**
 A class representing the status of location permissions.
*/
@interface RadarLocationPermissionStatus : NSObject

/**
 The type of location permissions state.
*/
typedef NS_ENUM(NSInteger, RadarLocationPermissionState) {
    NoAuthorization,
    ForegroundAuthorized,
    ForegroundFullAccuracyDenied,
    ForegroundAuthorizationDenied,
    ForegroundAuthorizationRequestInProgress,
    BackgroundAuthorized,
    BackgroundFullAccuracyDenied,
    BackgroundAuthorizationDenied,
    BackgroundAuthorizationRequestInProgress,
    AuthorizationRestricted,
    Unknown
};

/**
 The CLAuthorizationStatus of the iOS location manager.
*/
@property (nonatomic, assign) CLAuthorizationStatus locationManagerStatus;
/**
 The flag indicating if the user authorized full location accuracy instead of reduced location accuracy.
*/
@property (nonatomic, assign) BOOL accuracyAuthorization;
/**
 The flag indicating if the user has been prompted for background location permissions.
*/
@property (nonatomic, assign) BOOL backgroundRequestAvailable;
/**
 The flag indicating if the user is in the pop-up for foreground location permissions.
*/
@property (nonatomic, assign) BOOL inForegroundRequest;
/**
 The flag indicating if the user has rejected background location permissions.
*/
@property (nonatomic, assign) BOOL userDeniedBackgroundAuthorization;
/**
 The state of the location permissions represented by the RadarLocationPermissionState enum.
*/
@property (nonatomic, assign) RadarLocationPermissionState locationPermissionState;

- (NSDictionary *_Nonnull)dictionaryValue;

@end
