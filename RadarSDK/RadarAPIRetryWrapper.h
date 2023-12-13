//
//  RadarAPIRetryWrapper.h
//  RadarSDK
//
//  Created by Kenny Hu on 12/13/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarAPIHelper.h"
#import "Radar.h"

@interface RadarAPIRetryWrapper : NSObject

@property (nonnull, strong, nonatomic) RadarAPIHelper *apiHelper;

- (instancetype)initWithAPIHelper:(RadarAPIHelper *)apiHelper;

- (void)requestWithRetry:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *_Nullable)headers
                   params:(NSDictionary *_Nullable)params
                    sleep:(BOOL)sleep
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
        completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler
              retriesLeft:(int)retriesLeft;

- (void)requestWithRetry:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *_Nullable)headers
                   params:(NSDictionary *_Nullable)params
                    sleep:(BOOL)sleep
               logPayload:(BOOL)logPayload
          extendedTimeout:(BOOL)extendedTimeout
       completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler;

@end

