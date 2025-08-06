//
//  RadarAPIHelperMock.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarAPIHelperMock.h"

@interface RadarAPIHelperMock ()

@property (nonnull, strong, nonatomic) NSMutableDictionary *mockResponses;

@end

@implementation RadarAPIHelperMock

- (instancetype)init {
    self = [super init];

    if (self) {
        self.mockResponses = [NSMutableDictionary new];
    }

    return self;
}

- (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *)headers
                   params:(NSDictionary *)params
                    sleep:(BOOL)sleep
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
        completionHandler:(RadarAPICompletionHandler)completionHandler {
    // Capture the last request for testing
    self.lastMethod = method;
    self.lastUrl = url;
    self.lastHeaders = headers;
    self.lastParams = params;
    
    NSDictionary *mockResponseForUrl = self.mockResponses[url];

    if (mockResponseForUrl) {
        completionHandler(self.mockStatus, mockResponseForUrl);
    } else {
        completionHandler(self.mockStatus, self.mockResponse);
    }
}

- (void)setMockResponse:(NSDictionary *)response forMethod:(NSString *)urlString {
    self.mockResponses[urlString] = response;
}

@end
