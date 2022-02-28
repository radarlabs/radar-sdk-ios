//
//  CLLocation+Radar.m
//  RadarSDK
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLLocation+Radar.h"

@implementation CLLocation

-(BOOL)isValid {
    if (!self) {
        return NO;
    }

    BOOL latitudeValid = _coordinate.latitude != 0 && _coordinate.latitude > -90 && _coordinate.latitude < 90;
    BOOL longitudeValid = _coordinate.longitude != 0 && _coordinate.longitude > -180 && _coordinate.latitude < 180;
    BOOL horizontalAccuracyValid = _horizontalAccuracy > 0;
    return latitudeValid && longitudeValid && horizontalAccuracyValid;
}

@end
