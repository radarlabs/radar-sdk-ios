//
//  RadarAPIHelper.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAPIHelper.h"

#import "RadarLogger.h"
#import "RadarSettings.h"

@interface RadarAPIHelper ()

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) dispatch_semaphore_t semaphore;
@property (assign, nonatomic) BOOL wait;

@end

@implementation RadarAPIHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("io.radar.api", DISPATCH_QUEUE_SERIAL);
        _semaphore = dispatch_semaphore_create(1);
        _wait = NO;
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
    dispatch_async(self.queue, ^{
        BOOL didWait = NO;
        if (self.wait) {
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            didWait = YES;
        }

        self.wait = YES;

        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        req.HTTPMethod = method;

        if (logPayload) {
            [[RadarLogger sharedInstance]
                logWithLevel:RadarLogLevelDebug
                     message:[NSString stringWithFormat:@"📍 Radar API request | method = %@; url = %@; headers = %@; params = %@", method, url, headers, params]];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"📍 Radar API request | method = %@; url = %@; headers = %@", method, url, headers]];
        }

        @try {
            if (headers) {
                for (NSString *key in headers) {
                    NSString *value = [headers valueForKey:key];
                    [req addValue:value forHTTPHeaderField:key];
                }
            }

            if (params) {
                [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:params options:0 error:NULL]];
            }

            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            if (extendedTimeout) {
                configuration.timeoutIntervalForRequest = 25;
                configuration.timeoutIntervalForResource = 25;
            } else {
                configuration.timeoutIntervalForRequest = 10;
                configuration.timeoutIntervalForResource = 10;
            }

            void (^dataTaskCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"Received network error | error = %@", error]];
                        completionHandler(RadarStatusErrorNetwork, nil);
                    });

                    self.wait = NO;
                    if (didWait) {
                        dispatch_semaphore_signal(self.semaphore);
                    }

                    return;
                }

                NSError *deserializationError = nil;
                id resObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializationError];
                if (deserializationError || ![resObj isKindOfClass:[NSDictionary class]]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(RadarStatusErrorServer, nil);
                    });

                    self.wait = NO;
                    if (didWait) {
                        dispatch_semaphore_signal(self.semaphore);
                    }

                    return;
                }

                NSDictionary *res;
                RadarStatus status = RadarStatusErrorUnknown;

                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
                    if (statusCode >= 200 && statusCode < 400) {
                        status = RadarStatusSuccess;
                    } else if (statusCode == 400) {
                        status = RadarStatusErrorBadRequest;
                    } else if (statusCode == 401) {
                        status = RadarStatusErrorUnauthorized;
                    } else if (statusCode == 402) {
                        status = RadarStatusErrorPaymentRequired;
                    } else if (statusCode == 403) {
                        status = RadarStatusErrorForbidden;
                    } else if (statusCode == 404) {
                        status = RadarStatusErrorNotFound;
                    } else if (statusCode == 429) {
                        status = RadarStatusErrorRateLimit;
                    } else if (statusCode >= 500 && statusCode <= 599) {
                        status = RadarStatusErrorServer;
                    }

                    res = (NSDictionary *)resObj;

                    [[RadarLogger sharedInstance]
                        logWithLevel:RadarLogLevelDebug
                             message:[NSString stringWithFormat:@"📍 Radar API response | method = %@; url = %@; statusCode = %ld; res = %@", method, url, (long)statusCode, res]];
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(status, res);
                });

                if (sleep) {
                    [NSThread sleepForTimeInterval:1];
                }

                self.wait = NO;
                if (didWait) {
                    dispatch_semaphore_signal(self.semaphore);
                }
            };

            NSURLSessionDataTask *task = [[NSURLSession sessionWithConfiguration:configuration] dataTaskWithRequest:req completionHandler:dataTaskCompletionHandler];

            [task resume];
        } @catch (NSException *exception) {
            return completionHandler(RadarStatusErrorBadRequest, nil);
        }
    });
}

@end
