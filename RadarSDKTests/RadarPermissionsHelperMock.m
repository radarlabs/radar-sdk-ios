//
//  RadarPermissionsHelperMock.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarPermissionsHelperMock.h"

@implementation RadarPermissionsHelperMock

- (CLAuthorizationStatus)locationAuthorizationStatus {
    return self.mockLocationAuthorizationStatus;
}

@end
