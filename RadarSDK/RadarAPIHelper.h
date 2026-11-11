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

// Runs after preparation on every attempt, with the exact request that will be sent. Must call completion
// exactly once, passing the request to send (the prepared request itself if there's nothing to add).
typedef void (^RadarAPIRequestAssertion)(NSURLRequest *request, void (^completion)(NSURLRequest *request));

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

- (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *_Nullable)headers
                   params:(NSDictionary *_Nullable)params
                    sleep:(BOOL)sleep
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
           prepareRequest:(RadarAPIRequestPreparation _Nullable)prepareRequest
            assertRequest:(RadarAPIRequestAssertion _Nullable)assertRequest
preparationFailureHandler:(void (^_Nullable)(NSError *error))preparationFailureHandler
        completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler;

@end

NS_ASSUME_NONNULL_END
