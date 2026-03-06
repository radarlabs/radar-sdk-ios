//
//  RadarAPIHelperMock.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarAPIHelperMock.h"

@interface RadarAPIHelperMock ()

@property (nonnull, strong, nonatomic) NSMutableDictionary *mockResponses;
@property (nonnull, strong, nonatomic) NSMutableDictionary *mockStatuses;

@end

@implementation RadarAPIHelperMock

- (instancetype)init {
    self = [super init];

    if (self) {
        self.mockResponses = [NSMutableDictionary new];
        self.mockStatuses = [NSMutableDictionary new];
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
    // skip /logs calls
    if ([url containsString:@"v1/logs"]) {
        return;
    }
    
    // Capture the last request for testing
    self.lastMethod = method;
    self.lastUrl = url;
    self.lastHeaders = headers;
    self.lastParams = params;
    
    NSDictionary *response = self.mockResponses[url];
    if (response == nil) {
        response = self.mockResponse;
    }
    
    RadarStatus status;
    if (self.mockStatuses[url]) {
        status = (RadarStatus)[self.mockStatuses[url] integerValue];
    } else {
        status = self.mockStatus;
    }
    
    completionHandler(status, response);
}

- (void)setMockResponse:(NSDictionary *)response forMethod:(NSString *)urlString {
    self.mockResponses[urlString] = response;
}

- (void)setMockStatus:(RadarStatus)mockStatus forMethod:(NSString *)urlString {
    self.mockStatuses[urlString] = @(mockStatus);
}

- (void)setMockStatus:(RadarStatus)mockStatus response:(NSDictionary*)response forMethod:(NSString *)urlString {
    self.mockStatuses[urlString] = @(mockStatus);
    self.mockResponses[urlString] = response;
}

@end
