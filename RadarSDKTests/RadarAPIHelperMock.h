//
//  RadarAPIHelperMock.h
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RadarSDK/RadarSDK.h>

#import "RadarAPIHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarAPIHelperMock : RadarAPIHelper

@property (assign, nonatomic) RadarStatus mockStatus;
@property (nonnull, strong, nonatomic) NSDictionary *mockResponse;

@end

NS_ASSUME_NONNULL_END
