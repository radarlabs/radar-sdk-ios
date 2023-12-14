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

@implementation RadarAPIHelperMock {
    int retryCounter;
}

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

    

    if (params != nil && [params objectForKey:@"retry"]) {
        id retry = params[@"retry"];

        if ([retry isKindOfClass:[NSNumber class]]) {

            retryCounter++;
            if (retryCounter < [retry intValue]) {
                if (completionHandler) {
                    completionHandler(RadarStatusErrorUnknown, nil);
                }
                return;
            } else {
                NSDictionary *successJson = @{@"successOn": [NSNumber numberWithInt:retryCounter]};
                if (completionHandler) {
                    completionHandler(RadarStatusSuccess, successJson);
                }
                retryCounter = 0;
                return;
            }
        }
    }

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
