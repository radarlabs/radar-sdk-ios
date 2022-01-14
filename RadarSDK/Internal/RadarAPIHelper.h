//
//  RadarAPIHelper.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^_Nullable RadarAPICompletionHandler)(RadarStatus status, NSDictionary *_Nullable res);

@interface RadarAPIHelper : NSObject

- (void)requestWithMethod:(NSString *)method
                      url:(NSString *)url
                  headers:(NSDictionary *_Nullable)headers
                   params:(NSDictionary *_Nullable)params
                    sleep:(BOOL)sleep
        completionHandler:(RadarAPICompletionHandler _Nullable)completionHandler;

@end

NS_ASSUME_NONNULL_END
