//
//  RadarAPIHelper.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^_Nullable RadarAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res, NSError *_Nullable error);

typedef NSURLRequest *_Nullable (^RadarAPIRequestPreparation)(NSURLRequest *request, NSError *_Nullable *_Nullable error);

// The client span of a traced request, which RadarAPIHelper starts, propagates, and ends. RadarTraceSpan implements it.
// It's a protocol so this header doesn't depend on that internal Swift class.
@protocol RadarAPIRequestTrace <NSObject>

// The W3C traceparent header to send, or nil when the trace's session isn't sampled.
@property (nonatomic, readonly, copy, nullable) NSString *traceparent;

// Called when the request starts on the API queue. queueNanos is the time since the request was enqueued.
- (void)requestStartedWithURL:(NSString *)url headers:(NSDictionary *_Nullable)headers queueNanos:(uint64_t)queueNanos;

- (void)setResendCount:(NSInteger)count;

// Ends the span for a request that failed without a response.
- (void)endWithNetworkError:(NSError *)error;

- (void)endWithStatus:(RadarStatus)status;

@end

@interface RadarAPIHelper : NSObject

- (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *_Nullable)headers
                   params:(NSDictionary *_Nullable)params
                    sleep:(BOOL)sleep
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
        completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler;

- (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *_Nullable)headers
                   params:(NSDictionary *_Nullable)params
                    sleep:(BOOL)sleep
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
           prepareRequest:(RadarAPIRequestPreparation _Nullable)prepareRequest
preparationFailureHandler:(void (^_Nullable)(NSError *error))preparationFailureHandler
        completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler;

// Every other overload calls this one. trace is the request's client span: it sends trace's traceparent, and ends trace
// before calling completionHandler, so the hop to the main queue counts toward the caller's span instead.
- (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *_Nullable)headers
                   params:(NSDictionary *_Nullable)params
                    sleep:(BOOL)sleep
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
           prepareRequest:(RadarAPIRequestPreparation _Nullable)prepareRequest
preparationFailureHandler:(void (^_Nullable)(NSError *error))preparationFailureHandler
                    trace:(id<RadarAPIRequestTrace> _Nullable)trace
        completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler;

@end

NS_ASSUME_NONNULL_END
