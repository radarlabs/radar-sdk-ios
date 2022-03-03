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
    BOOL latitudeValid = self.coordinate.latitude != 0 && self.coordinate.latitude > -90 && self.coordinate.latitude < 90;
    BOOL longitudeValid = self.coordinate.longitude != 0 && self.coordinate.longitude > -180 && self.coordinate.latitude < 180;
    BOOL horizontalAccuracyValid = self.horizontalAccuracy > 0;

    return latitudeValid && longitudeValid && horizontalAccuracyValid;
}

@end
