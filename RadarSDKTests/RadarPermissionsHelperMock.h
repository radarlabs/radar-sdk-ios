//
//  RadarPermissionsHelperMock.h
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <RadarSDK/RadarSDK.h>

#import "RadarPermissionsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarPermissionsHelperMock : RadarPermissionsHelper

@property (assign, nonatomic) CLAuthorizationStatus mockLocationAuthorizationStatus;

@end

NS_ASSUME_NONNULL_END
