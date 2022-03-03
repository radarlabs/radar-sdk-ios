//
//  CLLocation+Radar.m
//  RadarSDK
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLLocation+Radar.h"

@implementation CLLocation(Radar)

-(BOOL)isValid {
    CLLocationDegrees lat = self.coordinate.latitude;
    CLLocationDegrees lon = self.coordinate.longitude;

    BOOL latitudeValid = lat != 0.0 && lat > -90.0 && lat < 90.0;
    BOOL longitudeValid = lon != 0.0 && lon > -180.0 && lon < 180;
    BOOL horizontalAccuracyValid = self.horizontalAccuracy > 0;

    return latitudeValid && longitudeValid && horizontalAccuracyValid;
}

@end
