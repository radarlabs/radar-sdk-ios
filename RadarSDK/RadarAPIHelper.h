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

typedef void (^RadarRequestPreparationCompletion)(
    RadarStatus status,
    NSURLRequest *_Nullable request,
    NSError *_Nullable error
);

typedef void (^RadarRequestPreparation)(
    NSURLRequest *request,
    RadarRequestPreparationCompletion completion
);

typedef void (^RadarRequestPreparationFailureHandler)(
    RadarStatus status,
    NSError *_Nullable error
);

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
          prepareRequest:(RadarRequestPreparation _Nullable)prepareRequest
       completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler;

- (void)requestWithMethod:(NSString *)method
                     url:(NSString *)url
                 headers:(NSDictionary *_Nullable)headers
                  params:(NSDictionary *_Nullable)params
                   sleep:(BOOL)sleep
              logPayload:(BOOL)logPayload
         extendedTimeout:(BOOL)extendedTimeout
          prepareRequest:(RadarRequestPreparation _Nullable)prepareRequest
preparationFailureHandler:(RadarRequestPreparationFailureHandler _Nullable)preparationFailureHandler
       completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler;

@end

NS_ASSUME_NONNULL_END
