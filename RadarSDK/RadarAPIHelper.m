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
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSMutableArray<RadarAPICompletionHandler> *> *coalescedRequests;

@end

@implementation RadarAPIHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("io.radar.api", DISPATCH_QUEUE_CONCURRENT);
        _semaphore = dispatch_semaphore_create(1);
        _lock = [NSLock new];
        _coalescedRequests = [NSMutableDictionary new];
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
        
        NSArray<RadarAPICompletionHandler> *coalescedRequestsCompletionHandlers;
        
        [self.lock lock];
        if (coalesce) {
            /*
             This is a coalescing request; either:
             - Add its completion to an existing, duplicate coalescing request and return immediately.
             - No duplicate coalescing requests exist, wait 1 second to collect incoming duplicate
               coalescing requests or to coalesce with a non-coalescing duplicate request.
             */
            if ([self.coalescedRequests objectForKey:url]) {
                [self.coalescedRequests[url] addObject:completionHandler];
                [self.lock unlock];
                return;
            } else {
                self.coalescedRequests[url] = [[NSMutableArray alloc] initWithArray:@[completionHandler]];
                [self.lock unlock];
                [NSThread sleepForTimeInterval:1];
                
                // Check if request was fulfilled by a non-coalescing, duplicate request while sleeping
                [self.lock lock];
                if (![self.coalescedRequests objectForKey:url]) {
                    [self.lock unlock];
                    return;
                }
            }
        } else {
            /*
             Non-coalescing requests will fire immediately and fulfill duplicate coalescing requests that have not fired yet.
             */
            if ([self.coalescedRequests objectForKey:url]) {
                coalescedRequestsCompletionHandlers = [self.coalescedRequests objectForKey:url];
                [self.coalescedRequests removeObjectForKey:url];
            }
        }
        [self.lock unlock];

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

                    if (sleep && !coalesce) {
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

                    if (sleep && !coalesce) {
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
                    if ([url isEqualToString:@"https://api.radar.io/v1/track"]) {
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                           message:[NSString stringWithFormat:@"reached track completion; coalesced call: %@", coalesce ? @"YES" : @"NO"]];
                    }
                    [self.lock lock];
                    if (coalesce && [self.coalescedRequests objectForKey:url]) {
                        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                           message:[NSString stringWithFormat:@"Coalescing %ld requests to %@ from coalesced call", (long)[self.coalescedRequests[url] count], url]];
                        for (RadarAPICompletionHandler completion in self.coalescedRequests[url]) {
                            completion(status, res);
                        }
                        [self.coalescedRequests removeObjectForKey:url];
                    } else {
                        if (coalescedRequestsCompletionHandlers) {
                            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                               message:[NSString stringWithFormat:@"Coalescing %ld requests to %@ from non-coalesced call", (long)[coalescedRequestsCompletionHandlers count] + 1, url]];
                            for (RadarAPICompletionHandler completion in coalescedRequestsCompletionHandlers) {
                                completion(status, res);
                            }
                        }
                        completionHandler(status, res);
                    }
                    [self.lock unlock];
                });

                if (sleep && !coalesce) {
                    [NSThread sleepForTimeInterval:1];
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
