//
//  RadarSDKLocationPermission.m
//  RadarSDKLocationPermission
//
//  Created by Kenny Hu on 10/2/24.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "RadarSDKLocationPermission.h"

@implementation RadarSDKLocationPermission

- (void)requestBackgroundPermission {
    [[CLLocationManager new] requestAlwaysAuthorization];
}

@end
