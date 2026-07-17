//
//  RadarAPIHelper.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarAPIHelper.h"

#import "RadarLogger.h"
#import "RadarSettings.h"
#import "RadarUtils.h"

#import <math.h>

#if DEBUG
#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif
#endif

static NSTimeInterval RadarAPIHelperStandardNetworkTimeoutInterval(void) {
    RadarInitializeOptions *opts = [RadarSettings initializeOptions];
    NSTimeInterval interval = opts ? opts.networkTimeoutInterval : 10;

    // Validate
    if (interval <= 0 || isnan(interval) || isinf(interval)) {
        interval = 10;
    }

    // Clamp to reasonable range
    if (interval < 1) {
        interval = 1;
    } else if (interval > 300) {
        interval = 300;
    }

    return interval;
}

static NSTimeInterval RadarAPIHelperExtendedNetworkTimeoutInterval(NSTimeInterval standard) { return standard * 2.5; }

@interface RadarAPIHelper ()

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) dispatch_semaphore_t semaphore;
@property (assign, nonatomic) BOOL wait;
@property (strong, nonatomic) NSURLSession *standardSession;
@property (strong, nonatomic) NSURLSession *extendedTimeoutSession;

@end

@implementation RadarAPIHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("io.radar.api", DISPATCH_QUEUE_SERIAL);
        _semaphore = dispatch_semaphore_create(1);

        NSTimeInterval standardTimeout = RadarAPIHelperStandardNetworkTimeoutInterval();
        NSTimeInterval extendedTimeout = RadarAPIHelperExtendedNetworkTimeoutInterval(standardTimeout);

        NSURLSessionConfiguration *standardConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        standardConfig.timeoutIntervalForRequest = standardTimeout;
        standardConfig.timeoutIntervalForResource = standardTimeout;

        NSURLSessionConfiguration *extendedConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        extendedConfig.timeoutIntervalForRequest = extendedTimeout;
        extendedConfig.timeoutIntervalForResource = extendedTimeout;

#if DEBUG
        // Installs a trust-override delegate so debug builds accept a self-signed cert
        // (e.g. a LAN server). Compiled out of release builds.
        RadarInsecureTrustDelegate *trustDelegate = [RadarInsecureTrustDelegate new];
        _standardSession = [NSURLSession sessionWithConfiguration:standardConfig delegate:trustDelegate delegateQueue:nil];
        _extendedTimeoutSession = [NSURLSession sessionWithConfiguration:extendedConfig delegate:trustDelegate delegateQueue:nil];
#else
        _standardSession = [NSURLSession sessionWithConfiguration:standardConfig];
        _extendedTimeoutSession = [NSURLSession sessionWithConfiguration:extendedConfig];
#endif
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
        if (sleep) {
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        }

        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        req.HTTPMethod = method;

        NSString *paramJsonStr = [RadarUtils dictionaryToJson:params];
        NSString *headersJsonStr = [RadarUtils dictionaryToJson:headers];

        if (logPayload) {
            [[RadarLogger sharedInstance]
                logWithLevel:RadarLogLevelDebug
                     message:[NSString stringWithFormat:@"📍 Radar API request | method = %@; url = %@; headers = %@; params = %@", method, url, headersJsonStr, paramJsonStr]];
        } else {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                               message:[NSString stringWithFormat:@"📍 Radar API request | method = %@; url = %@; headers = %@", method, url, headersJsonStr]];
        }

        @try {
            if (headers) {
                for (NSString *key in headers) {
                    [req addValue:[headers valueForKey:key] forHTTPHeaderField:key];
                }
            }

            if (params) {
                NSNumber *prevUpdatedAtMsDiff = params[@"updatedAtMsDiff"];
                NSArray *replays = params[@"replays"];
                if (prevUpdatedAtMsDiff || replays) {
                    NSMutableDictionary *requestParams = [params mutableCopy];
                    long nowMs = (long)([NSDate date].timeIntervalSince1970 * 1000);
                    NSNumber *locationMs = params[@"locationMs"];

                    if (locationMs != nil && prevUpdatedAtMsDiff != nil) {
                        long updatedAtMsDiff = nowMs - [locationMs longValue];
                        requestParams[@"updatedAtMsDiff"] = @(updatedAtMsDiff);
                    }

                    if (replays) {
                        NSMutableArray *updatedReplays = [NSMutableArray arrayWithCapacity:replays.count];
                        for (NSDictionary *replay in replays) {
                            NSMutableDictionary *updatedReplay = [replay mutableCopy];
                            NSNumber *replayLocationMs = replay[@"locationMs"];
                            if (replayLocationMs != nil) {
                                long replayUpdatedAtMsDiff = nowMs - [replayLocationMs longValue];
                                updatedReplay[@"updatedAtMsDiff"] = @(replayUpdatedAtMsDiff);
                            }
                            [updatedReplays addObject:updatedReplay];
                        }
                        requestParams[@"replays"] = updatedReplays;
                    }

                    [req setHTTPBody:[RadarUtils jsonData:requestParams]];
                } else {
                    [req setHTTPBody:[RadarUtils jsonData:params]];
                }
            }

            NSURLSession *session = extendedTimeout ? self.extendedTimeoutSession : self.standardSession;
            NSDate *requestStart = [NSDate date];

            void (^dataTaskCompletionHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                NSTimeInterval latency = [requestStart timeIntervalSinceNow] * -1;

                if (error) {
                    long elapsedMs = (long)(latency * 1000);
                    NSString *host = req.URL.host ?: @"unknown";
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[RadarLogger sharedInstance]
                            logWithLevel:RadarLogLevelError
                                    type:RadarLogTypeSDKError
                                 message:[NSString stringWithFormat:@"Network error | host = %@; errorDomain = %@; errorCode = %ld; errorDescription = %@; elapsedMs = %ld",
                                          host, error.domain, (long)error.code, error.localizedDescription, elapsedMs]];
                        completionHandler(RadarStatusErrorNetwork, nil, error);
                    });

                    if (sleep) {
                        [NSThread sleepForTimeInterval:1];
                        dispatch_semaphore_signal(self.semaphore);
                    }

                    return;
                }

                NSError *deserializationError = nil;
                id resObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializationError];
                if (deserializationError || ![resObj isKindOfClass:[NSDictionary class]]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(RadarStatusErrorServer, nil, deserializationError);
                    });

                    if (sleep) {
                        [NSThread sleepForTimeInterval:1];
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
                    NSString *resJsonStr = [RadarUtils dictionaryToJson:res];

                    if (params && [params objectForKey:@"replays"]) {
                        NSArray *replays = [params objectForKey:@"replays"];
                        [[RadarLogger sharedInstance]
                            logWithLevel:RadarLogLevelDebug
                                 message:[NSString stringWithFormat:@"📍 Radar API response | method = %@; url = %@; statusCode = %ld; latency = %f; replays = %lu; res = %@",
                                                                    method, url, (long)statusCode, latency, (unsigned long)replays.count, resJsonStr]];
                    } else {
                        [[RadarLogger sharedInstance]
                            logWithLevel:RadarLogLevelDebug
                                 message:[NSString stringWithFormat:@"📍 Radar API response | method = %@; url = %@; statusCode = %ld; latency = %f; res = %@", method, url,
                                                                    (long)statusCode, latency, resJsonStr]];
                    }
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(status, res, nil);
                });

                if (sleep) {
                    [NSThread sleepForTimeInterval:1];
                    dispatch_semaphore_signal(self.semaphore);
                }
            };

            void (^dataTaskRetryHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNetworkConnectionLost) {
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                       message:[NSString stringWithFormat:@"📍 Radar API retrying after lost connection | url = %@", url]];
                    NSURLSessionDataTask *retryTask = [session dataTaskWithRequest:req completionHandler:dataTaskCompletionHandler];
                    [retryTask resume];
                } else {
                    dataTaskCompletionHandler(data, response, error);
                }
            };

            NSURLSessionDataTask *task = [session dataTaskWithRequest:req completionHandler:dataTaskRetryHandler];
            [task resume];
        } @catch (NSException *exception) {
            if (sleep) {
                dispatch_semaphore_signal(self.semaphore);
            }
            NSError *exceptionError = [NSError errorWithDomain:@"RadarSDK"
                                                          code:0
                                                      userInfo:@{
                                                          NSLocalizedDescriptionKey: exception.reason ?: exception.name ?: @"NSException",
                                                          @"NSException": exception
                                                      }];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(RadarStatusErrorBadRequest, nil, exceptionError);
            });
            return;
        }
    });
}

@end
