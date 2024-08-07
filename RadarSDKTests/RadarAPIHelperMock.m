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
                 verified:(BOOL)verified
        completionHandler:(RadarAPICompletionHandler)completionHandler {
    NSURL *host = [NSURL URLWithString:(verified ? @"https://api-verified.radar.io" : @"https://api.radar.io")];
    NSString *urlString = [[NSURL URLWithString:url relativeToURL:host] absoluteString];
                                        
    NSDictionary *mockResponseForUrl = self.mockResponses[urlString];

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
