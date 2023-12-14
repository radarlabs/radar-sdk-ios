//
//  RadarAPIRetryWrapper.m
//  RadarSDK
//
//  Created by Kenny Hu on 12/13/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarLog.h"
#import "RadarAPIRetryWrapper.h"
#import "RadarAPIHelper.h"

@implementation RadarAPIRetryWrapper {
    int _maxRetries;
    int _timeout;
    int _timeoutBase;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype _Nullable)initWithAPIHelper:(RadarAPIHelper *)apiHelper {
    self = [super init];
    if (self) {
        _apiHelper = apiHelper;
        _maxRetries = 5;
        _timeout = 200;
        _timeoutBase = 2;
    }
    return self;
}

- (void)requestWithRetry:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *_Nullable)headers
                   params:(NSDictionary *_Nullable)params
                    sleep:(BOOL)sleep
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
       completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler{
    [self requestWithRetry:method url:url headers:headers params:params sleep:sleep logPayload:logPayload extendedTimeout:extendedTimeout completionHandler:completionHandler retriesLeft:_maxRetries];
    
}

- (void)requestWithRetry:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *_Nullable)headers
                   params:(NSDictionary *_Nullable)params
                    sleep:(BOOL)sleep
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
        completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler
        retriesLeft:(int)retriesLeft{
    
    int retriesLeftSanitized = MIN(retriesLeft, _maxRetries);
    if (retriesLeftSanitized == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(RadarStatusErrorUnknown, nil);
            }
        });
        return;
    }

    RadarAPICompletionHandler newCompletionHandler = ^(RadarStatus status, NSDictionary * _Nullable res) {
        if ((status != RadarStatusSuccess && retriesLeftSanitized == 1) || (status == RadarStatusSuccess)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandler) {
                    completionHandler(status, res);
                }
            });
        } else {
            // Calculate retry duration with jitter.
            double retryDuration = (self->_timeout * pow(self->_timeoutBase, (self->_maxRetries - retriesLeft + 1)) + arc4random_uniform(1000));
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, retryDuration * NSEC_PER_MSEC);
            dispatch_after(delay, dispatch_get_main_queue(), ^{
                [self requestWithRetry:method url:url headers:headers params:params sleep:sleep logPayload:logPayload extendedTimeout:extendedTimeout completionHandler:completionHandler retriesLeft:retriesLeftSanitized - 1];
            });
            
        }
    };

    [_apiHelper requestWithMethod:method url:url headers:headers params:params sleep:sleep logPayload:logPayload extendedTimeout:extendedTimeout completionHandler:newCompletionHandler];
    
}

@end
