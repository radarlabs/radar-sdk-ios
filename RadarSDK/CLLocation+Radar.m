//
//  CLLocation+Radar.m
//  RadarSDK
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

@import Foundation;
#import "CLLocation+Radar.h"

@implementation CLLocation (Radar)

- (BOOL)isValid {
    CLLocationDegrees lat = self.coordinate.latitude;
    CLLocationDegrees lon = self.coordinate.longitude;

    BOOL latitudeValid = ![self isDouble:lat equalTo:0.0] && lat > -90.0 && lat < 90.0;
    BOOL longitudeValid = ![self isDouble:lon equalTo:0.0] && lon > -180.0 && lon < 180;
    BOOL horizontalAccuracyValid = self.horizontalAccuracy > 0;

    return latitudeValid && longitudeValid && horizontalAccuracyValid;
}

- (BOOL)isDouble:(double)firstValue equalTo:(double)secondValue {
    return fabs(firstValue - secondValue) < FLT_EPSILON;
}

@end
