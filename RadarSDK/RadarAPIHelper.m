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

@interface RadarAPIHelper ()

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) dispatch_semaphore_t semaphore;
@property (assign, nonatomic) BOOL wait;
@property (strong, nonatomic) NSLock *lock;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSMutableArray<RadarAPICompletionHandler> *> *completions;

@end

@implementation RadarAPIHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("io.radar.api", DISPATCH_QUEUE_SERIAL);
        _semaphore = dispatch_semaphore_create(1);
        _lock = [NSLock new];
        _completions = [NSMutableDictionary new];
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
    [self requestWithMethod:method url:url headers:headers params:params sleep:sleep coalesce:NO logPayload:logPayload extendedTimeout:extendedTimeout completionHandler:completionHandler];
}

- (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *)headers
                   params:(NSDictionary *)params
                    sleep:(BOOL)sleep
                 coalesce:(BOOL)coalesce
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
        completionHandler:(RadarAPICompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        if (sleep && !coalesce) {
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        }
        
        NSArray<RadarAPICompletionHandler> *completionHandlers;
        
        if (coalesce) {
            [self.lock lock];
            if ([self.completions objectForKey:url]) {
                [self.completions[url] addObject:completionHandler];
                [self.lock unlock];
                return;
            } else {
                self.completions[url] = [[NSMutableArray alloc] initWithArray:@[completionHandler]];
                [self.lock unlock];
                // Sleep for 1 second with released lock to allow for coalescing of requests
                [NSThread sleepForTimeInterval:1];
                [self.lock lock];
                if (![self.completions objectForKey:url]) {
                    [self.lock unlock];
                    return;
                }
            }
        } else {
            [self.lock lock];
            if ([self.completions objectForKey:url]) {
                completionHandlers = [self.completions objectForKey:url];
                [self.completions removeObjectForKey:url];
            }
            [self.lock unlock];
        }
        
//        NSArray<RadarAPICompletionHandler> *completionHandlers;

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

            NSURLSessionConfiguration *configuration;
            if (extendedTimeout) {
                configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                configuration.timeoutIntervalForRequest = 25;
                configuration.timeoutIntervalForResource = 25;
            } else {
                // avoid SSL or credential caching
                configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
                configuration.timeoutIntervalForRequest = 10;
                configuration.timeoutIntervalForResource = 10;
            }

            NSDate *requestStart = [NSDate date];

            void (^dataTaskCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                // calculate request latencies, multiplying by -1 because timeIntervalSinceNow returns a negative value
                NSTimeInterval latency = [requestStart timeIntervalSinceNow] * -1;

                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"Received network error | error = %@", error]];
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
                                 message:[NSString stringWithFormat:@"📍 Radar API response | method = %@; url = %@; statusCode = %ld; latency = %f; res = %@", method, url,
                                                                    (long)statusCode, latency, resJsonStr]];
                    }
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.lock lock];
                    if (coalesce && [self.completions objectForKey:url]) {
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                           message:[NSString stringWithFormat:@"Coalescing %ld requests to %@", (long)[self.completions[url] count], url]];
                        for (RadarAPICompletionHandler completion in self.completions[url]) {
                            completion(status, res);
                        }
                        [self.completions removeObjectForKey:url];
                    } else {
                        if (completionHandlers) {
//                            [self.lock lock];
                            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                               message:[NSString stringWithFormat:@"Coalescing %ld requests to %@", (long)[completionHandlers count] + 1, url]];
                            for (RadarAPICompletionHandler completion in completionHandlers) {
                                completion(status, res);
                            }
//                            [self.completions removeObjectForKey:url];
//                            [self.lock unlock];
                        }
                        completionHandler(status, res);
                    }
                    [self.lock unlock];
                });

                if (sleep) {
                    [NSThread sleepForTimeInterval:1];
                    dispatch_semaphore_signal(self.semaphore);
                }
            };

            NSURLSessionDataTask *task = [[NSURLSession sessionWithConfiguration:configuration] dataTaskWithRequest:req completionHandler:dataTaskCompletionHandler];

            [task resume];
        } @catch (NSException *exception) {
            return completionHandler(RadarStatusErrorBadRequest, nil);
        }
//        if (coalesce) {
            [self.lock unlock];
//        }
    });
}

@end
