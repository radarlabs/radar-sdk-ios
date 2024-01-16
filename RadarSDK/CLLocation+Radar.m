//
//  CLLocation+Radar.m
//  RadarSDK
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

@import Foundation;
#import "CLLocation+Radar.h"

const double DEGREE_EPSILON = 0.00000001;

@implementation CLLocation (Radar)

- (BOOL)isValid {
    CLLocationDegrees lat = self.coordinate.latitude;
    CLLocationDegrees lon = self.coordinate.longitude;

    BOOL latitudeValid = ![self isDouble:lat withinDegreeEpsilonTo:0.0] && lat > -90.0 && lat < 90.0;
    BOOL longitudeValid = ![self isDouble:lon withinDegreeEpsilonTo:0.0] && lon > -180.0 && lon < 180;
    BOOL horizontalAccuracyValid = self.horizontalAccuracy > 0;

    return latitudeValid && longitudeValid && horizontalAccuracyValid;
}

- (BOOL)isDouble:(double)firstValue withinDegreeEpsilonTo:(double)secondValue {
    return fabs(firstValue - secondValue) < DEGREE_EPSILON;
}

@end
