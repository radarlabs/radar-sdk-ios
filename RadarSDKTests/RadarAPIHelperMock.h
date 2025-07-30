//
//  RadarAPIHelperMock.h
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "../RadarSDK/RadarAPIHelper.h"
#import <Foundation/Foundation.h>
#import <RadarSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarAPIHelperMock : RadarAPIHelper

@property (assign, nonatomic) RadarStatus mockStatus;
@property (nonnull, strong, nonatomic) NSDictionary *mockResponse;

// Properties to capture last request for testing
@property (nonatomic, strong, nullable) NSString *lastMethod;
@property (nonatomic, strong, nullable) NSString *lastUrl;
@property (nonatomic, strong, nullable) NSDictionary *lastHeaders;
@property (nonatomic, strong, nullable) NSDictionary *lastParams;

- (void)setMockResponse:(NSDictionary *)response forMethod:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
