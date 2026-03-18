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
#import "RadarSDKFraudProtocol.h"

@interface RadarAPIHelper ()

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) dispatch_semaphore_t semaphore;
@property (assign, nonatomic) BOOL wait;
@property (strong, nonatomic) NSURLSession *standardSession;
@property (strong, nonatomic) NSURLSession *extendedTimeoutSession;

- (NSMutableDictionary *)updateParamsWithTiming:(NSDictionary *)params;

@end

@implementation RadarAPIHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("io.radar.api", DISPATCH_QUEUE_SERIAL);
        _semaphore = dispatch_semaphore_create(1);

        NSURLSessionConfiguration *standardConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        standardConfig.timeoutIntervalForRequest = 10;
        standardConfig.timeoutIntervalForResource = 10;
        _standardSession = [NSURLSession sessionWithConfiguration:standardConfig];

        NSURLSessionConfiguration *extendedConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        extendedConfig.timeoutIntervalForRequest = 25;
        extendedConfig.timeoutIntervalForResource = 25;
        _extendedTimeoutSession = [NSURLSession sessionWithConfiguration:extendedConfig];
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
    [self requestWithMethod:method url:url headers:headers params:params sleep:sleep logPayload:logPayload extendedTimeout:extendedTimeout verified:NO fraudOptions:nil completionHandler:completionHandler];
}

- (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *)headers
                   params:(NSDictionary *)params
                    sleep:(BOOL)sleep
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
                 verified:(BOOL)verified
             fraudOptions:(NSDictionary<NSString *, id> *)fraudOptions
        completionHandler:(RadarAPICompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        if (sleep) {
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        }

        // Nested function to handle response parsing
        NSDate *requestStart = [NSDate date];
        void (^handleResponse)(NSData *data, NSURLResponse *response, NSError *error) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            // calculate request latencies, multiplying by -1 because timeIntervalSinceNow returns a negative value
            NSTimeInterval latency = [requestStart timeIntervalSinceNow] * -1;

            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"Received network error | error = %@", error]];
                    completionHandler(RadarStatusErrorNetwork, nil);
                });

                return;
            }

            NSError *deserializationError = nil;
            id resObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializationError];
            if (deserializationError || ![resObj isKindOfClass:[NSDictionary class]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(RadarStatusErrorServer, nil);
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
                NSString * resJsonStr = [RadarUtils dictionaryToJson:res];

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
                completionHandler(status, res);
            });

            if (sleep) {
                [NSThread sleepForTimeInterval:1];
                dispatch_semaphore_signal(self.semaphore);
            }
        };
        
        @try {
            // Check if verified and fraudOptions provided - pass to fraud SDK early to skip request setup
            if (verified && fraudOptions) {
                Class RadarSDKFraud = NSClassFromString(@"RadarSDKFraud");
                if (RadarSDKFraud) {
                    id<RadarSDKFraudProtocol> fraudInstance = [RadarSDKFraud sharedInstance];
                    if (fraudInstance) {
                        // Log request (fraud SDK will handle actual request)
                        NSString * paramJsonStr = [RadarUtils dictionaryToJson:params];
                        NSString * headersJsonStr = [RadarUtils dictionaryToJson:headers];
                        if (logPayload) {
                            [[RadarLogger sharedInstance]
                                logWithLevel:RadarLogLevelDebug
                                 message:[NSString stringWithFormat:@"📍 Radar API request | method = %@; url = %@; headers = %@; params = %@", method, url, headersJsonStr, paramJsonStr]];
                        } else {
                            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                               message:[NSString stringWithFormat:@"📍 Radar API request | method = %@; url = %@; headers = %@", method, url, headersJsonStr]];
                        }
                        
                        // Update params with timing info before passing to fraud SDK (same as what would be in request body)
                        NSMutableDictionary *bodyForFraud = [self updateParamsWithTiming:params];
                        
                        // Pass headers, body (request params), and fraud detection params to fraud SDK
                        // Fraud SDK constructs its own request with SSL pinning
                        NSMutableDictionary<NSString *, id> *optionsWithRequest = [fraudOptions mutableCopy];
                        optionsWithRequest[@"headers"] = headers;
                        optionsWithRequest[@"body"] = bodyForFraud;  // Request body params
                        // fraudOptions already contains fraud detection params (location, nonce, etc.)
                        
                        [fraudInstance trackVerifiedWithOptions:optionsWithRequest completionHandler:^(NSDictionary<NSString *, id> * _Nullable result) {
                            NSData *data = result[@"data"];
                            NSHTTPURLResponse *response = result[@"response"];
                            NSError *error = result[@"error"];
                            handleResponse(data, response, error);
                        }];
                        return;
                    }
                }
            }

            // Normal request path (not verified/fraud)
            NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
            req.HTTPMethod = method;

            NSString * paramJsonStr = [RadarUtils dictionaryToJson:params];
            NSString * headersJsonStr = [RadarUtils dictionaryToJson:headers];

            if (logPayload) {
                [[RadarLogger sharedInstance]
                    logWithLevel:RadarLogLevelDebug
                     message:[NSString stringWithFormat:@"📍 Radar API request | method = %@; url = %@; headers = %@; params = %@", method, url, headersJsonStr, paramJsonStr]];
            } else {
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                   message:[NSString stringWithFormat:@"📍 Radar API request | method = %@; url = %@; headers = %@", method, url, headersJsonStr]];
            }

            if (headers) {
                for (NSString *key in headers) {
                    [req addValue:[headers valueForKey:key] forHTTPHeaderField:key];
                }
            }

            if (params) {
                NSMutableDictionary *requestParams = [self updateParamsWithTiming:params];
                [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:requestParams options:0 error:NULL]];
            }

            NSURLSession *session = extendedTimeout ? self.extendedTimeoutSession : self.standardSession;
            NSDate *requestStart = [NSDate date];

            void (^dataTaskCompletionHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                NSTimeInterval latency = [requestStart timeIntervalSinceNow] * -1;

                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[RadarLogger sharedInstance]
                            logWithLevel:RadarLogLevelError
                                    type:RadarLogTypeSDKError
                                 message:[NSString stringWithFormat:@"Received network error | error = %@", error]];
                        completionHandler(RadarStatusErrorNetwork, nil);
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
                        completionHandler(RadarStatusErrorServer, nil);
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
                    NSString * resJsonStr = [RadarUtils dictionaryToJson:res];

                    if (params && [params objectForKey:@"replays"]) {
                        NSArray *replays = [params objectForKey:@"replays"];
                        [[RadarLogger sharedInstance]
                            logWithLevel:RadarLogLevelDebug
                                 message:[NSString stringWithFormat:@"📍 Radar API response | method = %@; url = %@; statusCode = %ld; latency = %f; replays = %lu; res = %@",
                                                                    method, url, (long)statusCode, latency, (unsigned long)replays.count, resJsonStr]];
                    } else {
                        [[RadarLogger sharedInstance]
                            logWithLevel:RadarLogLevelDebug
                                 message:[NSString stringWithFormat:@"📍 Radar API response | method = %@; url = %@; statusCode = %ld; latency = %f; res = %@",
                                                                    method, url, (long)statusCode, latency, resJsonStr]];
                    }
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(status, res);
                });

                if (sleep) {
                    [NSThread sleepForTimeInterval:1];
                    dispatch_semaphore_signal(self.semaphore);
                }
            };

            void (^dataTaskRetryHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNetworkConnectionLost) {
                    [[RadarLogger sharedInstance]
                        logWithLevel:RadarLogLevelDebug
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
            return completionHandler(RadarStatusErrorBadRequest, nil);
        }
    });
}

- (NSMutableDictionary *)updateParamsWithTiming:(NSDictionary *)params {
    if (!params) {
        return nil;
    }
    
    NSMutableDictionary *updatedParams = [params mutableCopy];
    NSNumber *prevUpdatedAtMsDiff = params[@"updatedAtMsDiff"];
    NSArray *replays = params[@"replays"];
    
    if (prevUpdatedAtMsDiff || replays) {
        long nowMs = (long)([NSDate date].timeIntervalSince1970 * 1000);
        NSNumber *locationMs = params[@"locationMs"];
        
        if (locationMs != nil && prevUpdatedAtMsDiff != nil) {
            long updatedAtMsDiff = nowMs - [locationMs longValue];
            updatedParams[@"updatedAtMsDiff"] = @(updatedAtMsDiff);
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
            updatedParams[@"replays"] = updatedReplays;
        }
    }
    
    return updatedParams;
}

@end
