//
//  RadarSDKLocationPermissions.m
//  RadarSDKLocationPermissions
//
//  Created by Kenny Hu on 10/2/24.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "RadarSDKLocationPermissions.h"

@implementation RadarSDKLocationPermissions

- (void)requestBackgroundPermission {
    [[CLLocationManager new] requestAlwaysAuthorization];
}

@end
