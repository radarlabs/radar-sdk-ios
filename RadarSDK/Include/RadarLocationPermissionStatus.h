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

// /**
//  The type of location permissions state.
// */
// typedef NS_ENUM(NSInteger, RadarLocationPermissionState) {
//     NoPermissionGranted,
//     ForegroundPermissionGranted,
//     ForegroundPermissionRejected,
//     ForegroundPermissionPending,
//     BackgroundPermissionGranted,
//     BackgroundPermissionRejected,
//     BackgroundPermissionPending,
//     PermissionRestricted,
//     Unknown
// };

typedef NS_ENUM(NSInteger, RadarLocationPermissionAccuracy) {
    RadarPermissionAccuracyFull,
    RadarPermissionAccuracyApproximate,
    RadarPermissionAccuracyUnknown
};

typedef NS_ENUM(NSInteger, RadarLocationPermissionLevel) {
    RadarPermissionLevelUnknown,
    RadarPermissionLevelForeground,
    RadarPermissionLevelBackground,
    RadarPermissionLevelNone
};

@property (nonatomic, assign) RadarLocationPermissionAccuracy accuracy;
@property (nonatomic, assign) RadarLocationPermissionLevel permissionGranted;
@property (nonatomic, assign) RadarLocationPermissionLevel requestAvailable;



// /**
//  The CLAuthorizationStatus of the iOS location manager.
// */
// @property (nonatomic, assign) CLAuthorizationStatus locationManagerStatus;
// /**
//  The flag indicating if the user has been prompted for background location permissions.
// */
// @property (nonatomic, assign) BOOL backgroundPopupAvailable;
// /**
//  The flag indicating if the user is in the pop-up for foreground location permissions.
// */
// @property (nonatomic, assign) BOOL inForegroundPopup;
// /**
//  The flag indicating if the user has rejected background location permissions.
// */
// @property (nonatomic, assign) BOOL userRejectedBackgroundPermission;
// /**
//  The state of the location permissions represented by the RadarLocationPermissionState enum.
// */
// @property (nonatomic, assign) RadarLocationPermissionState locationPermissionState;

- (NSDictionary *_Nonnull)dictionaryValue;

@end
