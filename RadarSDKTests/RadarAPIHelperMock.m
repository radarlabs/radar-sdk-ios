//
//  RadarAPIHelperMock.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarAPIHelperMock.h"

@implementation RadarAPIHelperMock

- (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *)headers
                   params:(NSDictionary *)params
                    sleep:(BOOL)sleep
        completionHandler:(RadarAPICompletionHandler)completionHandler {
    completionHandler(self.mockStatus, self.mockResponse);
}

@end
