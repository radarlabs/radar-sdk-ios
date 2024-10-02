//
//  RadarSDKLocationPermissions.h
//  RadarSDKLocationPermissions
//
//  Created by Kenny Hu on 10/2/24.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface RadarSDKLocationPermissions : NSObject

- (void)requestForegroundPermission;
- (void)requestBackgroundPermission;

@end